module Freevoice
  class Command
    attr_reader :command

    def initialize(command, &block)
      @command, @callbacks = command, {}
      @callbacks[:success] = block if block_given?
    end

    def to_s
    end

    def on_success(&block)
      @callbacks[:success] = block
    end

    def on_failure(&block)
      @callbacks[:failure] = block
    end

    def on_response(&block)
      @callbacks[:response] = block
    end

    def fire_callbacks(response)
      run :response
      success?(response) ? run(:success) : run(:failure)
    end

    def success?(response)
      false
    end

    private

    def run(callback)
      @callbacks[callback] && @callbacks[callback].call
    end
  end

  class ApiCommand < Command
    def success?(response)
      response.ok?
    end

    def to_s
      "#{@command}\n\n"
    end
  end

  class AppCommand < Command
    def initialize(command, params=nil, options={}, &block)
      @command, @params, @callbacks = command, params, {}
      @options = {:bargein => true}.merge(options)
      @callback[:success] = block if block_given?
    end

    def success?(response)
      response.executed?
    end

    def to_s
      cmd =  "sendmsg\n"
      cmd << "call-command: execute\n"
      cmd << "execute-app-name: #{@command}\n"
      cmd << "execute-app-arg: #{@params}\n" if @params
      cmd << "event-lock: #{@options[:lock]}\n" if @options[:lock]
      cmd << "\n"
    end

    def interruptable?
      @options[:bargein]
    end

  end
end
