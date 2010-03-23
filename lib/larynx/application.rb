module Larynx
  class Application
    attr_reader :call
    delegate *Commands.instance_methods << {:to => :call}

    def self.run(call)
      app = self.new(call)
      call.add_observer app
      app.run
    end

    def initialize(call)
      @call = call
    end

    def run
      #override for setup
    end

    def log(msg)
      app.call.log(msg)
    end
  end
end
