module Freevoice
  class CallHandler < EventMachine::Protocols::HeaderAndContentProtocol
    include Observable

    attr_reader :input
    attr_reader :observers

    def connect(&block)
      execute ApiCommand.new('connect', &block)
    end

    def answer(&block)
      execute AppCommand.new('answer', &block)
    end

    def hangup(&block)
      execute AppCommand.new('hangup', &block)
    end

    def playback(text, options={}, &block)
      execute AppCommand.new('playback', text, options, &block)
    end
    alias_method :play, :playback

    def speak(text, options={}, &block)
      execute AppCommand.new('speak', text, options, &block)
    end

    def phrase(text, options={}, &block)
      execute AppCommand.new('phrase', text, options, &block)
    end

    def post_init
      log "Call received!"
      @queue, @input = [], []
      @state = :initiated
      connect.on_response {
        @state = :connected
        start_session
      }
      execute_next_command
    end

    def start_session
      @session = Session.new(@response.header)
      subscribe_to_events {
        filter_events {
          linger_for_events
          answer {
            @state = :ready
            Freevoice.answer_block.call(self) if Freevoice.answer_block
          }
        }
      }
    end

    def subscribe_to_events(&block)
      # send_data ApiCommand.new('event plain ALL', &block)
      execute ApiCommand.new('myevents', &block)
    end

    def filter_events(&block)
      execute ApiCommand.new("filter Unique-ID #{@session.unique_id}", &block)
    end

    def linger_for_events(&block)
      execute ApiCommand.new('linger', &block)
    end

    def break!
      cmd = AppCommand.new('break')
      @queue.unshift cmd
      send_data cmd.to_s
    end

    def clear_input
      @input = []
    end

    def execute(command)
      @queue << command
      command
    end

    def timer(timeout, &block)
      @timer = [EM::Timer.new(timeout) {
        block.call
        notify_observers :timed_out
        execute_next_command if @state == :ready
        @timer = nil
      }, block]
    end

    def cancel_timer
      if @timer
        @timer[0].cancel
        @timer[1].call if @timer[1]
        @timer = nil
        execute_next_command if @state == :ready
      end
    end

    def cleanup
      break! if @state == :executing
    end

    def receive_request(header, content)
      @response = Response.new(header, content)

      log "RECEIVED\n" + @response.header[:content_type]
      if @response.event?
        log @response.event_name
        log @response.command_name
      end
      log "\n"

      case
      when @response.reply? && current_command.is_a?(ApiCommand)
        finalize_command
        execute_next_command
      when @response.executing?
        @state = :executing
      when @response.executed?
        finalize_command
        execute_next_command
        @state = :ready
      when @response.dtmf? || @response.speech?
        @input << @response.body[:dtmf_digit]
        if @state == :executing && current_command.interruptable?
          break!
        end
        finalize_command
        notify_observers :dtmf_received, @response.body[:dtmf_digit]
      when @response.disconnect?
        cleanup
        notify_observers :hungup
        @state = :waiting
        log 'Bye!'
      end
    end

    def current_command
      @queue.first
    end

    def finalize_command
      if command = @queue.shift
        command.fire_callbacks @response
      end
    end

    def execute_next_command
      send_data current_command.to_s if current_command
    end

    def send_data(msg)
      log 'SENT: ' + msg
      super
    end

    def log(msg)
      puts msg
    end

  end
end
