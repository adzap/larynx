module Larynx
  class Response
    include Parser
    attr_reader :header, :body

    def initialize(header, body)
      @header, @body = parse(header), parse(body)
    end

    def reply?
      @header[:content_type] == 'command/reply'
    end

    def event?
      @header[:content_type] == 'text/event-plain'
    end

    def ok?
      @header[:reply_text] =~ /\+OK/
    end

    def error?
      @header[:reply_text] =~ /ERR/
    end

    def executing?
      event_name == 'CHANNEL_EXECUTE'
    end

    def executed?
      event_name == 'CHANNEL_EXECUTE_COMPLETE'
    end

    def command_name
      @body[:application]
    end

    def event_name
      @body[:event_name]
    end

    def dtmf?
      @body[:event_name] == 'DTMF'
    end

    def speech?
      @body[:event_name] == 'DETECTED_SPEECH'
    end

    def disconnect?
      @header[:content_type] == 'text/disconnect-notice'
    end

  end
end
