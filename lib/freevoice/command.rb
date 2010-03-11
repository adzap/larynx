module Freevoice
  class Command
    attr_reader :command

    def initialize(command, params=nil, &block)
      @command, @params, @callbacks = command, params, {}
      @callbacks[:after] = block if block_given?
    end

    def to_s
      @command
    end

    def name
      @command
    end

    def before(&block)
      @callbacks[:before] = block
    end

    def after(&block)
      @callbacks[:after] = block
    end

    def interruptable?
      false
    end

    def fire_callback(callback)
      @callbacks[callback] && @callbacks[callback].call
    end
  end

  class ApiCommand < Command
    def name
      "#{@command}#{" #{@params}" if @params}"
    end

    def to_s
      cmd = @command
      cmd << " #{@params}" if @params
      cmd << "\n\n"
    end
  end

  class AppCommand < Command
    def initialize(command, params=nil, options={}, &block)
      super command, params, &block
      @options = options.reverse_merge(:bargein => true)
    end

    def name
      "#{@command}#{" '#{@params}'" if @params}"
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
