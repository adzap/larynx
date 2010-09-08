module Larynx
  class NoPromptDefined < StandardError; end

  class Field
    include CallbacksWithAsync

    VALID_PROMPT_OPTIONS = Prompt::PROMPT_OPTIONS + [:repeats]

    attr_reader :name, :form, :attempt, :value
    define_callback :setup, :validate, :invalid, :success, :failure, :scope => :form

    delegate :call, :to => :form

    def initialize(name, options, &block)
      @name = name
      @options = options.reverse_merge(:attempts => 3)
      @prompt_queue = []

      instance_eval(&block)
      raise(Larynx::NoPromptDefined, 'A field requires a prompt to be defined') if @prompt_queue.empty?
    end

    def run(form)
      @form = form
      @attempt = 0
      call.add_observer self
      fire_callback(:setup)
      execute_next_prompt
    end

    def prompt(options)
      add_prompt(options)
    end

    def reprompt(options)
      raise 'A reprompt can only be used after a prompt' if @prompt_queue.empty?
      add_prompt(options)
    end

    def last_attempt?
      @attempt == @options[:attempts]
    end

    def current_prompt
      @current_prompt ||= prompt_for_attempt
    end

    private

    def increment_attempts
      @attempt += 1
    end

    def execute_next_prompt
      @current_prompt = nil
      increment_attempts
      call.execute current_prompt.command
      send_next_command
    end

    def add_prompt(options)
      options.assert_valid_keys(*VALID_PROMPT_OPTIONS)
      repeats = options.delete(:repeats) || 1
      options.merge!(@options.slice(*Prompt::PROMPT_OPTIONS))
      @prompt_queue += ([options] * repeats)
    end

    def prompt_for_attempt
      options = (@prompt_queue[@attempt-1] || @prompt_queue.last).dup
      method  = Prompt.command_from_options(options)
      message = options[method].is_a?(Symbol) ? @form.send(options[method]) : options[method]
      options[method] = message

      Prompt.new(call, options) {|input, result|
        set_instance_variables(input, result)
        evaluate_input
      }
    end

    # hook called when callback is complete
    def callback_complete(callback, result=true)
      case callback
      when :validate
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
      if last_attempt?
        fire_callback(:failure)
      else
        increment_attempts
        execute_next_prompt
      end
    end

    def send_next_command
      call.send_next_command if call.state == :ready
    end

    def set_instance_variables(input, result)
      @value, @valid_length = input, result
      @form.instance_variable_set(:"@#{@name}", input)
    end

    def finalize
      call.remove_observer self
      send_next_command
    end

  end
end
