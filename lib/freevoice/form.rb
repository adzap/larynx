module Freevoice
  class Form < Application
    include Fields

    def run
      next_field
    end
  end
end
