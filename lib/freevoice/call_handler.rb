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

    def prompt(options={}, &block)
      Prompt.new(self, options, &block).execute
    end

    def post_init
      @queue, @input, @timers = [], [], {}
      @state = :initiated
      connect {
        @state = :connected
        start_session
      }
      execute_next_command
    end

    def start_session
      @session = Session.new(@response.header)
      log "Call received from #{@response.header[:caller_caller_id_number]}"
      subscribe_to_events {
        filter_events {
          linger_for_events
          answer {
            log 'Answered call'
            @state = :ready
            Freevoice.answer_block.call(self) if Freevoice.answer_block
          }
        }
      }
    end

    def subscribe_to_events(&block)
      # execute ApiCommand.new('event plain ALL', &block)
      execute ApiCommand.new('myevents', &block)
    end

    def filter_events(&block)
      execute ApiCommand.new('filter', "Unique-ID #{@session.unique_id}", &block)
    end

    def linger_for_events(&block)
      execute ApiCommand.new('linger', &block)
    end

    def break!
      execute AppCommand.new('break'), true
    end

    def interrupt_command
      if @state == :executing && current_command.interruptable?
        break!
      end
    end

    def clear_input
      @input = []
    end

    def execute(command, immediately=false)
      log "Queued command: #{command.name}"
      if immediately
        @queue.unshift command
        execute_next_command
      else
        @queue << command
      end
      command
    end

    def timer(name, timeout, &block)
      @timers[name] = [EM::Timer.new(timeout) {
        @timers.delete(name)
        block.call
        notify_observers :timed_out
        execute_next_command if @state == :ready
      }, block]
    end

    def cancel_timer(name)
      if @timers[name]
        timer = @timers.delete(name)
        timer[0].cancel
      end
    end

    def cancel_all_timers
      @timers.values.each {|t| t[0].cancel }
    end

    def stop_timer(name)
      if @timers[name]
        timer = @timers.delete(name)
        timer[0].cancel
        timer[1].call if timer[1]
        execute_next_command if @state == :ready
      end
    end

    def restart_timer(name)
      if timer = @timers[name]
        timer[0].restart
      end
    end

    def cleanup
      break! if @state == :executing
      cancel_all_timers
      clear_observers!
    end

    def receive_request(header, content)
      @response = Response.new(header, content)

      case
      when @response.reply? && current_command.is_a?(ApiCommand)
        log "Completed: #{current_command.name}"
        finalize_command
        execute_next_command
      when @response.executing?
        log "Executing: #{current_command.name}"
        @state = :executing
      when @response.executed? && current_command
        log "Finished: #{current_command.name}"
        finalize_command
        execute_next_command unless last_command.command == 'break'
        @state = :ready
      when @response.dtmf? #|| @response.speech?
        log "Button pressed: #{@response.body[:dtmf_digit]}"
        handle_dtmf
      when @response.disconnect?
        log "Disconnected."
        cleanup
        notify_observers :hungup
        Freevoice.hungup_block.call(self) if Freevoice.hungup_block
        @state = :waiting
      end
    end

    def handle_dtmf
      @input << @response.body[:dtmf_digit]
      interrupt_command
      notify_observers :dtmf_received, @response.body[:dtmf_digit]
    end

    def current_command
      @queue.first
    end

    def last_command
      @last_command
    end

    def finalize_command
      if command = @queue.shift
        command.fire_callback
        @last_command = command
      end
    end

    def execute_next_command
      send_data current_command if current_command
    end

    def send_data(command)
      super command.to_s
    end

    def log(msg)
      puts msg.strip + "\n\n"
    end

  end
end
