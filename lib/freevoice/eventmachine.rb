module EventMachine
  # Adds restart to EM timer class
  class Timer
    def initialize(interval, callback=nil, &block)
      @interval, @callback, @block = interval, callback, block
      @signature = EventMachine::add_timer(interval, callback || block)
    end

    # Restart the timer
    def restart
      cancel
      @signature = EventMachine::add_timer(@interval, @callback || @block)
    end
  end
end
