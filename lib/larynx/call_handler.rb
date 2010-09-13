module Larynx
  class CallHandler < EventMachine::Protocols::HeaderAndContentProtocol
    include Observable
    include Commands

    attr_reader :state, :session, :response, :input, :observers, :last_command

    # EM hook which is run when call is received
    def post_init
      @queue, @input, @timers = [], [], {}
      connect { start_session }
      send_next_command
    end

    def start_session
      @session = Session.new(@response.header)
      log "Call received from #{caller_id}"
      myevents
      linger
      Larynx.fire_callback(:connect, self)
    end

    def called_number
      @session[:caller_destination_number]
    end

    def caller_id
      @session[:caller_caller_id_number]
    end

    def clear_input
      @input = []
    end

    def current_command
      @queue.first
    end

    def next_command
      @queue[1]
    end

    def execute(command, immediately=false)
      log "Queued: #{command.name}"
      if immediately
        @queue.unshift command
        send_next_command true
      else
        @queue << command
      end
      command
    end

    def add_timer(name, timeout, &block)
      @timers[name] = [RestartableTimer.new(timeout) {
        timer = @timers.delete(name)
        timer[1].call if timer[1]
        notify_observers :timed_out
        send_next_command
      }, block]
    end

    def cancel_timer(name)
      if timer = @timers[name]
        timer[0].cancel
        @timers.delete(name)
        send_next_command
      end
    end

    def cancel_all_timers
      @timers.values.each {|t| t[0].cancel }
      @timers = {}
    end

    def stop_timer(name)
      if timer = @timers[name]
        # only run callback if it was actually cancelled (i.e. returns false)
        if timer[0].cancel == false && timer[1]
          timer[1].call
        end
        @timers.delete(name)
        send_next_command
      end
    end

    def restart_timer(name)
      if timer = @timers[name]
        timer[0].restart
      end
    end

    def receive_request(header, content)
      @response = Response.new(header, content)
      handle_request
    end

    def handle_request
      case
      when @response.reply? && current_command.is_a?(CallCommand)
        log "Completed: #{current_command.name}"
        @state = :ready
        finalize_command
        send_next_command
      when @response.answered?
        log 'Answered call'
        @state = :ready
        finalize_command
        Larynx.fire_callback(:answer, self)
        send_next_command
      when @response.executing?
        log "Executing: #{current_command.name}"
        current_command.setup
        @state = :executing
      when @response.executed? && current_command
        @state = :ready
        finalize_command
        send_next_command
      when @response.dtmf?
        log "Button pressed: #{@response.body[:dtmf_digit]}"
        handle_dtmf
      when @response.disconnect?
        log "Disconnected."
        cleanup
        notify_observers :hungup
        Larynx.fire_callback(:hungup, self)
        @state = :waiting
      end
    end

    def handle_dtmf
      @input << @response.body[:dtmf_digit]
      interrupt_command
      notify_observers :dtmf_received, @response.body[:dtmf_digit]
      send_next_command
    end

    def interrupt_command
      if @state == :executing && current_command.interruptable?
        break!
      end
    end

    def finalize_command
      if command = @queue.shift
        command.finalize unless command.interrupted?
        @last_command = command
      end
    end

    def command_to_send
      current_command.try(:interrupted?) ? next_command : current_command
    end

    def send_next_command(force=false)
      command = command_to_send
      if command && (ready? || force)
        @state = :sending
        send_data command.to_s
      end
    end

    def cleanup
      break! if @state == :executing
      cancel_all_timers
      clear_observers!
      @session = nil
    end

    def log(msg)
      LARYNX_LOGGER.info msg
    end

    def ready?
      @state == :ready
    end

  end
end
