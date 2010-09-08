module Larynx
  class NoPromptCommandValue < StandardError; end

	# The prompt class neatly wraps up a convention where you prompt for input of
	# certain length. The prompt waits until the required input length is reached,
	# the user presses the terminator button or the time runs out. Think of the
	# play_and_get_digits command except it works for speak as well. It also
	# provides a bargein option to allow or prevent the user from interrupting
	# the speech or playback.
	#
	# Pass a block to the method as a callback which receives input as an argument.
	#
  class Prompt
    attr_reader :call

    COMMAND_OPTIONS = [:play, :playback, :speak, :phrase]
    PROMPT_OPTIONS  = COMMAND_OPTIONS + [:length, :min_length, :max_length, :bargein, :interdigit_timeout, :timeout, :termchar]

    def self.command_from_options(options)
      (COMMAND_OPTIONS & options.keys).first
    end

    def initialize(call, options, &block)
      options.assert_valid_keys(*PROMPT_OPTIONS)
      @call, @options, @block = call, options, block
      @options.reverse_merge!(Larynx.prompt_defaults)
      raise NoPromptCommandValue, "No output command value supplied. Use one of play, speak or phrase keys." if command_name.blank?
    end

    def command
      @command ||= AppCommand.new(command_name, message, :bargein => @options[:bargein]).
        before { call.clear_input unless @options[:bargein] }.
        after  {
          call.clear_input unless @options[:bargein]
          if prompt_finished?
            finalise
          else
            call.add_observer self
            add_digit_timer
            add_input_timer
          end
        }
    end

    def input
      (call.input.last == termchar ? call.input[0..-2] : call.input).join
    end

    def prompt_finished?
      call.input.last == termchar || call.input.size == maximum_length
    end

    def termchar
      @options[:termchar]
    end

    def minimum_length
      @options[:min_length] || @options[:length] || 1
    end

    def maximum_length
      @options[:max_length] || @options[:length]
    end

    def interdigit_timeout
      @options[:interdigit_timeout]
    end

    def timeout
      @options[:timeout]
    end

    def command_name
      self.class.command_from_options(@options).to_s
    end

    def message
      @options[command_name.to_sym]
    end

    def valid_length?
      length = input.size
      length >= minimum_length && length <= (maximum_length || length)
    end

    def finalise
      call.remove_observer self
      @block.arity == 2 ? @block.call(input, valid_length?) : @block.call(input)
      call.clear_input
    end

    def dtmf_received(digit)
      if prompt_finished?
        call.stop_timer(:input)
        call.cancel_timer(:digit)
      else
        call.restart_timer(:digit)
      end
    end

    def add_digit_timer
      call.add_timer(:digit, interdigit_timeout) {
        call.cancel_timer :input
        finalise
      }
    end

    def add_input_timer
      call.add_timer(:input, timeout) {
        call.cancel_timer :digit
        finalise
      }
    end
  end
end
