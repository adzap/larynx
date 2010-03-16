module EventMachine
  # Adds restart to EM timer class
  class Timer
    def initialize(interval, callback=nil, &block)
      @interval = interval
      @callback = callback || block
      @signature = EventMachine::add_timer(interval, @callback)
    end

    # Restart the timer
    def restart
      cancel
      @signature = EventMachine::add_timer(@interval, @callback)
    end
  end
end
