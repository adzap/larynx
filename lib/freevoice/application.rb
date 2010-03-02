module Freevoice
  class Application
    attr_reader :call

    class Field
      def initialize(name, options, call, block)
        @name, @options, @callbacks = name, call, options, {}
        instance_eval &block
      end

      def prompt(options, &block)
        method = *([:play, :speak, :phrase] & options.keys)
        @min_length = options[:min_length]
        @max_length = options[:max_length]
        @term_digit = options[:term_digit] || '#'
        @timeout    = options[:timeout] || 5

        call.send(method, options.delete(method), options).on_success {
          call.timer(@timeout) { block.call(call.input.dup) }
        }
      end

      def setup(&block)
        @callbacks[:setup] = block
      end

      def validate(&block)
        @callbacks[:validate] = block
      end

      def invalid(&block)
        @callbacks[:invalid] = block
      end

      def success(&block)
        @callbacks[:success] = block
      end

      def failure(&block)
        @callbacks[:failure] = block
      end
    end

    class << self
      attr_accessor :fields

      def field(name, options={}, &block)
        @fields ||= []
        @fields << Field.new(name, options, block)
      end

      def run(call)
        app = self.new(call)
        call.add_observer! app
        app.run
      end
    end

    def initialize(call)
      @call = call
    end

    def step
    end
  end
end
