module Larynx
  # Allows you to set the :async flag on the back to the callback in with
  # EM.defer method. Its useful for blocking or long running tasks like database calls.
  module CallbacksWithAsync
    def self.included(base)
      base.extend ClassMethods
      base.cattr_accessor :callback_options
      base.callback_options = {}
      base.class_eval do
        include InstanceMethods
      end
    end

    module ClassMethods

      def define_callback(*callbacks)
        options = callbacks.extract_options!
        callbacks.each do |callback|
          self.callback_options[callback] = options
          class_eval <<-DEF
            def #{callback}(mode=:sync, &block)
              @callbacks ||= {}
              @callbacks[:#{callback}] = [block, mode]
              self
            end
          DEF
        end
      end

    end

    module InstanceMethods

      def fire_callback(callback)
        if @callbacks && @callbacks[callback]
          block, mode = *@callbacks[callback]
          scope = self.class.callback_options[callback][:scope]
          if mode == :async
            EM.defer(scope_callback(block, scope), lambda {|result| callback_complete(callback, result) })
          else
            callback_complete(callback, scope_callback(block, scope).call)
          end
        else
          callback_complete(callback)
        end
      end

      # Scope takes the callback block and a method symbol which is used
      # to return an object that scopes the block evaluation.
      def scope_callback(block, scope=nil)
        scope ? lambda { send(scope).instance_eval(&block) } : block
      end

      def callback_complete(callback, result)
        # Override in class to handle post callback result
      end
    end
  end

end
