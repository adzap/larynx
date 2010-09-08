module Larynx
  class Menu < Application
    class_inheritable_accessor :prompt_definition
    class_inheritable_accessor :option_definitions
    class_inheritable_accessor :callbacks

    attr_reader :menu, :attempt

    class << self
      def prompt(options, &block)
        options.merge!(:block => block) if block_given?
        self.prompt_definition = options.reverse_merge(:attempts => 3)
      end

      def option(values, prompt=nil, &block)
        self.option_definitions ||= []
        self.option_definitions << [values, prompt, block]
      end

      def invalid(&block)
        self.callbacks ||= {}
        self.callbacks[:invalid] = block
      end

      def failure(&block)
        self.callbacks ||= {}
        self.callbacks[:failure] = block
      end
    end

    def initialize(call)
      super
      @attempt = 1
    end

    def run
      execute_prompt
    end

    def compile_prompt
      prompt_options = self.class.prompt_definition.dup
      command = Prompt.command_from_options(prompt_options)
      command_value = prompt_options[command]
      prompt_options[command] = command_value.is_a?(Symbol) ? send(command_value) : command_value 

      Prompt.new(call, prompt_options.slice(*Prompt::PROMPT_OPTIONS)) {|input, result|
        evaluate_choice(input)
      }
    end

    def execute_prompt
      call.execute compile_prompt.command
      call.send_next_command
    end

    def evaluate_choice(choice)
      if chosen = find_choice(choice)
        instance_eval &chosen.last
        finalize
      else
        invalid_choice
      end
    end

    def find_choice(choice)
      choice = choice.to_i
      option_definitions.find {|option|
        values = option.first
        case values
        when Fixnum
          values == choice
        when Range, Array
          values.include?(choice)
        end
      }
    end

    def invalid_choice
      fire_callback :invalid
      if last_attempt?
        fire_callback :failure
        finalize
      else
        increment_attempts
        execute_prompt
      end
    end

    def increment_attempts
      @attempt += 1
    end

    def last_attempt?
      @attempt == self.class.prompt_definition[:attempts]
    end

    def send_next_command
      call.send_next_command if call.state == :ready
    end

    def finalize
      call.remove_observer self
      send_next_command
    end

    def fire_callback(callback)
      if self.class.callbacks && self.class.callbacks[callback]
        instance_eval(&self.class.callbacks[callback]) 
      end
    end

  end
end
