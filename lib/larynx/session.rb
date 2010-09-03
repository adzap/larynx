module Larynx
  class Session
    attr_reader :variables

    def initialize(data)
      @variables = data
    end

    def method_missing(method, *args, &block)
      if @variables.has_key?(method.to_sym)
        @variables[method.to_sym]
      end
    end

    def []=(key, value)
      @variables[key] = value
    end

    def [](key)
      @variables[key]
    end

  end
end
