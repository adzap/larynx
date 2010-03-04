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

      def next_field(field_name=nil)
        @current_field ||= 0
        @current_field = index_of_field(field_name) if field_name
        if field = self.class.fields[@current_field]
          field.run(self)
          @current_field += 1
        end
      end

      def index_of_field(name)
        field = self.class.fields.find {|f| f.name == name }
        self.class.fields.index(field)
      end

    end

    class Field
      attr_reader :name

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
        repeats = options.delete(:repeats) || 1
        @prompt_queue += ([options] * repeats)
      end

      def next_prompt
        options = @prompt_queue[@attempt-1] || @prompt_queue.last
        method  = ([:play, :speak, :phrase] & options.keys).first
        message = options[method].is_a?(Symbol) ? @app.send(options[method]) : options[method]
        options[method] = message

        call.clear_input
        prompt = Prompt.new(call, options) {|input| evaluate_input(input) }
        prompt.execute
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
        @value.size >= minimum_length && fire_callback(:validate)
      end

      def evaluate_input(input)
        @value = input
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
          end
        end
      end

      def maximum_length
        @options[:max_length] || @options[:length]
      end

      def minimum_length
        @options[:min_length] || @options[:length]
      end

      def run(app)
        @app = app
        @attempt = 1
        fire_callback(:setup)
        next_prompt
      end

      def call
        @app.call
      end
    end

  end
end
