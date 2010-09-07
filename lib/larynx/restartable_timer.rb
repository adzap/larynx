module Larynx
  # Adds restart to EM timer class. Implementation influenced by EM::PeriodicTimer class
  # so hopefully it should not cause any issues.
  class RestartableTimer < EM::Timer
    def initialize(interval, callback=nil, &block)
      @interval = interval
      @code = callback || block
      @work = method(:fire)
      schedule
    end

    # Restart the timer
    def restart
      cancel
      schedule
    end

    def schedule
      @signature = EM::add_timer(@interval, @work)
    end

    def fire
      @code.call
    end

  end
end
