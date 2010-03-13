module Freevoice
  module Callbacks

    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        include InstanceMethods
      end
    end

    module ClassMethods
      def define_callback(*callbacks)
        callbacks.each do |callback|
          class_eval <<-DEF
            def #{callback}(&block)
              @callbacks ||= {}
              @callbacks[:#{callback}] = block
              self
            end
          DEF
        end
      end
    end

    module InstanceMethods
      def fire_callback(callback)
        @callbacks[callback] && @callbacks[callback].call
      end
    end

  end
end
