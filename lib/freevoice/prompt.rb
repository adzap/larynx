module Freevoice
  class NoPromptCommandValue < StandardError; end

  class Prompt
    attr_reader :call

    def initialize(call, options, &block)
      @call, @options, @block = call, options, block
      @options.reverse_merge!(:attempts => 3, :bargein => true, :timeout => 10, :interdigit_timeout => 3, :termchar => '#')
      raise NoPromptCommandValue, "No output command value supplied. Use one of playback, speak or phrase keys." if command.nil?
    end

    def execute
      cmd = AppCommand.new(command, message, :bargein => @options[:bargein])
      cmd.before { call.clear_input }
      cmd.after  {
        if prompt_finished?
          @block.call(input)
          finalise
        else
          call.add_observer! self
          call.timer(:digit, @options[:interdigit_timeout]) {
            call.cancel_timer :input
            @block.call(input)
            finalise
          }
          call.timer(:input, @options[:timeout]) {
            call.cancel_timer :digit
            @block.call(input)
            finalise
          }
        end
      }
      call.execute cmd
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

    def maximum_length
      @options[:max_length] || @options[:length]
    end

    def dtmf_received(digit)
      if prompt_finished?
        call.stop_timer(:input)
        call.cancel_timer(:digit)
      else
        call.restart_timer(:digit)
      end
    end

    def command
      ([:play, :speak, :phrase] & @options.keys).first
    end

    def message
      @options[command]
    end

    def finalise
      call.remove_observer! self
    end
  end
end
