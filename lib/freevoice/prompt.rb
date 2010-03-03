module Freevoice
  class Prompt
    attr_reader :call

    def initialize(call, options, &block)
      @call, @options, @block = call, options, block
      @options.reverse_merge!(:attempts => 3, :bargein => true, :timeout => 10, :interdigit_timeout => 2, :termchar => '#')
    end

    def execute
      call.add_observer! self
      call.send(command, message, :bargein => @options[:bargein]) {
        if prompt_finished?
          @block.call
          finalise
        else
          call.timer(:digit, @options[:interdigit_timeout]) {
            call.cancel_timer :input
            @block.call
            finalise
          }
          call.timer(:input, @options[:timeout]) {
            call.cancel_timer :digit
            @block.call
            finalise
          }
        end
      }
    end

    def prompt_finished?
      call.input.last == @options[:termchar] || call.input.size == (@options[:max_length] || @options[:length])
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
