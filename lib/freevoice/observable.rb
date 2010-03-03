module Freevoice
  module Observable

    def add_observer!(object)
      @observers ||= []
      @observers << object
    end

    def remove_observer!(object)
      @observers.delete(object)
    end

    # Like an observer stack which only notifies top observer
    def notify_current_observer(event, data=nil)
      return unless @observers
      obs = @observers.last
      if obs.respond_to?(event)
        data ? obs.send(event, data) : obs.send(event)
      end
    end

    def notify_observers(event, data=nil)
      return unless @observers
      @observer.each do |obs|
        next unless obs.respond_to?(event)
        data ? obs.send(event, data) : obs.send(event)
      end
    end

  end
end
