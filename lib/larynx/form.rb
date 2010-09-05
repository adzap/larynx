module Larynx
  class Form < Application
    class_inheritable_accessor :setup_block
    class_inheritable_accessor :field_definitions
    self.field_definitions = []

    attr_accessor :fields

    class << self
      def setup(&block)
        self.setup_block = block
      end

      def field(name, options={}, &block)
        self.field_definitions <<  {:name => name, :options => options, :block => block}
        attr_accessor name
      end
    end

    def initialize(call)
      super
      @fields = self.class.field_definitions.map {|field| Field.new(field[:name], field[:options], &field[:block]) }
      @field_index = -1
    end

    def run
      call.clear_input
      instance_eval &self.class.setup_block if self.class.setup_block
      next_field
    end

    def restart_form
      @field_index = -1
      run
    end

    def next_field(field_name=nil)
      if field_name
        @field_index = field_index(field_name)
      else
        @field_index += 1
      end
      if field = current_field
        field.run(self)
        field
      end
    end

    def current_field
      @fields[@field_index]
    end

    def field_index(name)
      field = @fields.find {|f| f.name == name }
      @fields.index(field)
    end

    def attempt
      current_field.attempt
    end

    def last_attempt?
      current_field.last_attempt?
    end
  end
end
