module Freevoice
  module Fields

    def self.included(base)
      base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      attr_accessor :fields

      def field(name, options={}, &block)
        @fields ||= []
        @fields << Field.new(name, options, &block)
        attr_accessor name
      end

    end

    module InstanceMethods

      def next_field
        @current_field ||= 0
        if field = self.class.fields[@current_field]
          field.run(self)
          @current_field += 1
        end
      end

    end

    class Field
      def initialize(name, options, &block)
        @name, @options, @callbacks = name, options, {}
        @prompt_queue = []

        instance_eval(&block)
        raise 'A field requires a prompt to be defined' if @prompt_queue.empty?
      end

      def prompt(options)
       add_prompt(options)
      end

      def reprompt(options)
        raise 'A reprompt can only be used after a prompt' if @prompt_queue.empty?
        add_prompt(options)
      end

      def add_prompt(options)
        method = *([:play, :speak, :phrase] & options.keys)
        options.reverse_merge!(:attempts => 1, :bargein => true, :timeout => 10, :termchar => '#')
        options[:message] = options.delete(method)
        options[:method]  = method

        repeats = options.delete(:repeats) || 1
        @prompt_queue += ([options] * repeats)
      end

      def next_prompt
        prompt = @prompt_queue[@attempt-1] || @prompt_queue.last
        call.clear_input
        call.send(prompt[:method], prompt[:message], :bargein => prompt[:bargein]) {
          # checks if input during speech/playback has completed input
          if finished_input?
            evaluate_input
          else
            call.timer(prompt[:timeout]) { evaluate_input }
          end
        }
        @current_prompt = prompt
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

      def fire_callback(callback)
        if block = @callbacks[callback]
          @app.instance_eval(&block)
        else
          true
        end
      end

      def valid?
        if input.size >= minimum_length
          fire_callback(:validate)
        else
          false
        end
      end

      def evaluate_input
        @app.send("#{@name}=", input)
        if valid?
          fire_callback(:success)
        else
          fire_callback(:invalid)
          if @attempt < @options[:attempts]
            @attempt += 1
            next_prompt
          else
            fire_callback(:failure)
            finalise
          end
        end
      end

      def maximum_length
        @options[:max_length] || @options[:length]
      end

      def minimum_length
        @options[:min_length] || @options[:length] || 1
      end

      def input
        (call.input.last == terminator ? call.input[0..-2] : call.input).join
      end

      def terminator
        @current_prompt[:termchar]
      end

      def finished_input?
        call.input.last == terminator || input.size == maximum_length
      end

      def dtmf_received(digit)
        if finished_input?
          call.cancel_timer
        end
      end

      def run(app)
        @app = app
        @attempt = 1
        call.add_observer! self
        fire_callback(:setup)
        next_prompt
      end

      def finalise
        call.remove_observer! self
      end

      def call
        @app.call
      end
    end

  end
end
