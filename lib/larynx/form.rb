module Larynx
  class Form < Application
    include Fields
    @@setup = nil

    def self.setup(&block)
      @@setup = block
    end

    def run
      instance_eval &@@setup if @@setup
      @fields = self.class.fields.map {|field| Field.new(field[:name], field[:options], &field[:block]) }
      @current_field = 0
      next_field
    end

    def restart_form
      @current_field = 0
      run
    end
  end
end
