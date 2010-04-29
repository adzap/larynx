module Larynx
  class NoPromptDefined < StandardError; end

  module Fields

    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        include InstanceMethods
        class_inheritable_accessor :field_definitions
        self.field_definitions = []
        attr_accessor :fields
      end
    end

    module ClassMethods

      def field(name, options={}, &block)
        self.field_definitions <<  {:name => name, :options => options, :block => block}
        attr_accessor name
      end

    end

    module InstanceMethods

      def initialize(*args, &block)
        @fields = self.class.field_definitions.map {|field| Field.new(field[:name], field[:options], &field[:block]) }
        @current_field = 0
        super
      end

      def next_field(field_name=nil)
        @current_field = field_index(field_name) if field_name
        if field = @fields[@current_field]
          field.run(self)
          @current_field += 1
          field
        end
      end

      def field_index(name)
        field = @fields.find {|f| f.name == name }
        @fields.index(field)
      end

    end

    class Field
      include CallbacksWithAsync

      attr_reader :name, :app
      define_callback :setup, :validate, :invalid, :success, :failure, :scope => :app

      def initialize(name, options, &block)
        @name = name
        @options = options.reverse_merge(:attempts => 3)
        @prompt_queue = []

        instance_eval(&block)
        raise(Larynx::NoPromptDefined, 'A field requires a prompt to be defined') if @prompt_queue.empty?
      end

      def prompt(options)
        add_prompt(options)
      end

      def reprompt(options)
        raise 'A reprompt can only be used after a prompt' if @prompt_queue.empty?
        add_prompt(options)
      end

      def add_prompt(options)
        options.assert_valid_keys(:play, :speak, :phrase, :bargein, :repeats, :interdigit_timeout, :timeout)
        repeats = options.delete(:repeats) || 1
        options.merge!(@options.slice(:length, :min_length, :max_length, :interdigit_timeout, :timeout))
        @prompt_queue += ([options] * repeats)
      end

      def current_prompt
        options = (@prompt_queue[@attempt-1] || @prompt_queue.last).dup
        method  = command_from_options(options)
        message = options[method].is_a?(Symbol) ? @app.send(options[method]) : options[method]
        options[method] = message

        Prompt.new(call, options) {|input, result|
          set_instance_variables(input, result)
          evaluate_input
        }
      end

      def execute_prompt
        call.execute current_prompt.command
        send_next_command
      end

      def increment_attempts
        @attempt += 1
      end

      # hook called when callback is complete
      def callback_complete(callback, result)
        case callback
        when :validate
          result = result.nil? ? true : result
          evaluate_validity(result)
        when :invalid
          invalid_input
        when :success, :failure
          finalize
        end
      end

      def evaluate_input
        @valid_length ? fire_callback(:validate) : fire_callback(:invalid)
      end

      def evaluate_validity(result)
        result ? fire_callback(:success) : fire_callback(:invalid)
      end

      def invalid_input
        if @attempt < @options[:attempts]
          increment_attempts
          execute_prompt
        else
          fire_callback(:failure)
        end
      end

      def send_next_command
        call.send_next_command if call.state == :ready
      end

      def set_instance_variables(input, result)
        @value, @valid_length = input, result
        @app.send("#{@name}=", input)
      end

      def command_from_options(options)
        ([:play, :speak, :phrase] & options.keys).first
      end

      def run(app)
        @app = app
        @attempt = 1
        call.add_observer self
        fire_callback(:setup)
        execute_prompt
      end

      def call
        @app.call
      end

      def finalize
        call.remove_observer self
        send_next_command
      end

    end

  end
end
