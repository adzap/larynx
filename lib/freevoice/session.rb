module Freevoice
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

  end
end
