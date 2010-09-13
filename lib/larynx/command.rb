module Larynx
  class Command
    include Callbacks
    attr_reader :command

    define_callback :before, :after

    def initialize(command, params=nil, &block)
      @command, @params, @callbacks, @interrupted = command, params, {}, false
      after(&block) if block_given?
    end

    def to_s
      @command
    end

    def name
      @command
    end

    def interrupt!
      @interrupted = true if interruptable?
    end

    def interruptable?
      false
    end

    def interrupted?
      @interrupted
    end

    def setup
      unless @setup
        @setup = true
        fire_callback :before
      end
    end

    def finalize
      unless @finalized
        @finalized = true
        fire_callback :after
      end
    end
  end

  class CallCommand < Command
    def name
      "#{@command}#{" #{@params}" if @params}"
    end

    def to_s
      cmd =  "#{@command}"
      cmd << " #{@params}" if @params
      cmd << "\n\n"
    end
  end

  class ApiCommand < Command
    def name
      "#{@command}#{" #{@params}" if @params}"
    end

    def to_s
      cmd =  "api #{@command}"
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
