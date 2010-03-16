module Larynx
  module Commands

    def connect(&block)
      execute ApiCommand.new('connect', &block)
    end

    def answer(&block)
      execute AppCommand.new('answer', &block)
    end

    def hangup(&block)
      execute AppCommand.new('hangup', &block)
    end

    def playback(text, options={}, &block)
      execute AppCommand.new('playback', text, options, &block)
    end
    alias_method :play, :playback

    def speak(text, options={}, &block)
      execute AppCommand.new('speak', text, options, &block)
    end

    def phrase(text, options={}, &block)
      execute AppCommand.new('phrase', text, options, &block)
    end

    def prompt(options={}, &block)
      execute Prompt.new(self, options, &block).command
    end

    def subscribe_to_events(&block)
      execute ApiCommand.new('myevents', &block)
    end

    def filter_events(&block)
      execute ApiCommand.new('filter', "Unique-ID #{@session.unique_id}", &block)
    end

    def linger_for_events(&block)
      execute ApiCommand.new('linger', &block)
    end

    def break!
      execute AppCommand.new('break'), true
    end

  end
end
