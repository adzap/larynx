module Freevoice
  class Command
    attr_reader :command

    def initialize(command, &block)
      @command, @callback = command, block
    end

    def to_s
      @command
    end

    def name
      @command
    end

    def interruptable?
      false
    end

    def fire_callback
      @callback && @callback.call
    end
  end

  class ApiCommand < Command
    def to_s
      "#{@command}\n\n"
    end
  end

  class AppCommand < Command

    def initialize(command, params=nil, options={}, &block)
      @command, @params, @callback = command, params, block
      @options = {:bargein => true}.merge(options)
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
