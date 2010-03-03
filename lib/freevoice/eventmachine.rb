module EventMachine
  class Timer
    def initialize(interval, callback=nil, &block)
      @interval, @callback, @block = interval, callback, block
      @signature = EventMachine::add_timer(interval, callback || block)
    end

    # Cancel the timer
    def cancel
      EventMachine.send :cancel_timer, @signature
    end

    # Restart the timer
    def restart
      cancel
      @signature = EventMachine::add_timer(@interval, @callback || @block)
    end
  end
end
