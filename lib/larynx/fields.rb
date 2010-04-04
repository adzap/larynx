module Larynx
  class NoPromptDefined < StandardError; end

  module Fields

    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        include InstanceMethods
        cattr_accessor :field_definitions
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
        @current_field = index_of_field(field_name) if field_name
        if field = @fields[@current_field]
          field.run(self)
          @current_field += 1
          field
        end
      end

      def index_of_field(name)
        field = @fields.find {|f| f.name == name }
        @fields.index(field)
      end

    end

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
            callback_complete(callback, nil)
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
        options.assert_valid_keys(:play, :speak, :phrase, :bargein, :repeats)
        repeats = options.delete(:repeats) || 1
        options.merge!(@options.slice(:length, :min_length, :max_length, :interdigit_timeout, :timeout))
        @prompt_queue += ([options] * repeats)
      end

      def current_prompt
        options = (@prompt_queue[@attempt-1] || @prompt_queue.last).dup
        method  = ([:play, :speak, :phrase] & options.keys).first
        message = options[method].is_a?(Symbol) ? @app.send(options[method]) : options[method]
        options[method] = message

        Prompt.new(call, options) {|input|
          set_instance_variables(input)
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

      def valid_length?
        @value.size >= minimum_length
      end

      # hook called when callback is complete
      def callback_complete(callback, result)
        case callback
        when :validate
          result = result.nil? ? true : result
          evaluate_validity(result)
        when :invalid
          invalid_input
        when :success
          send_next_command
        when :failure
          send_next_command
        end
      end

      def evaluate_input
        valid_length? ? fire_callback(:validate) : fire_callback(:invalid)
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

      def set_instance_variables(input)
        @value = input
        @app.send("#{@name}=", input)
      end

      def maximum_length
        @options[:max_length] || @options[:length]
      end

      def minimum_length
        @options[:min_length] || @options[:length] || 1
      end

      def run(app)
        @app = app
        @attempt = 1
        fire_callback(:setup)
        execute_prompt
      end

      def call
        @app.call
      end

    end

  end
end
