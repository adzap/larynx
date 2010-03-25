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

    def playback(data, options={}, &block)
      execute AppCommand.new('playback', data, options, &block)
    end
    alias_method :play, :playback

    def speak(data, options={}, &block)
      execute AppCommand.new('speak', data, options, &block)
    end

    def phrase(data, options={}, &block)
      execute AppCommand.new('phrase', data, options, &block)
    end


    # Executes read command with some default values.
    # Allows length option which expands into minimum and maximum length values. Length can be a range.
    # Passes user input into callback block.
    #
    # Defaults:
    #    timeout:  5000 or 5 seconds
    #    termchar: #
    #
    # Example:
    #
    #   read(:minimum => 1, :maximum => 2, :sound_file => 'en/us/callie/conference/8000/conf-pin.wav') {|input|
    #     speak "You entered #{input}"
    #   }
    #
    # Or
    #
    #   read(:length => 1..2, :sound_file => 'en/us/callie/conference/8000/conf-pin.wav') {|input|
    #     speak "You entered #{input}"
    #   }
    #
    def read(options={}, &block)
      options.reverse_merge!(:timeout => 5000, :var_name => 'read_result', :termchar => '#')
      options[:bargein] = false

      if length = options.delete(:length)
        values = length.is_a?(Range) ? [length.first, length.last] : [length, length]
        options.merge!(:minimum => values[0], :maximum => values[1])
      end

      order = [:minimum, :maximum, :sound_file, :var_name, :timeout, :termchar]
      data  = order.inject('') {|data, key| data += " #{options[key]}"; data }.strip

      execute AppCommand.new('read', data, options).after {
        block.call(response.body[:variable_read_result])
      }
    end

    def prompt(options={}, &block)
      execute Prompt.new(self, options, &block).command
    end

    def break!
      execute AppCommand.new('break'), true
    end

  end
end
