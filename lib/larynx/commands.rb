module Larynx
  module Commands

    def connect(&block)
      execute CallCommand.new('connect', &block)
    end

    def myevents(&block)
      execute CallCommand.new('myevents', &block)
    end

    def filter(type, &block)
      execute CallCommand.new('filter', type, &block)
    end

    def linger(&block)
      execute CallCommand.new('linger', &block)
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

    def break!
      execute AppCommand.new('break'), true
    end

  end
end
