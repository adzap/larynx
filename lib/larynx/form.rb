module Larynx
  class Form < Application
    include Fields
    class_inheritable_accessor :setup_block

    def self.setup(&block)
      self.setup_block = block
    end

    def run
      instance_eval &self.class.setup_block if self.class.setup_block
      next_field
    end

    def restart_form
      @field_index = -1
      run
    end
  end
end
