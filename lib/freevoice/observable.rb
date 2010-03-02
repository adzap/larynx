module Freevoice
  module Observable

    def add_observer!(object)
      @observers ||= []
      @observers << object
    end

    def remove_observer!(object)
      @observers.delete(object)
    end

    def notify_observers(event, data=nil)
      return unless @observers
      @observers.each do |obs|
        next unless obs.respond_to?(event)
        data ? obs.send(event, data) : obs.send(event)
      end
    end

  end
end
