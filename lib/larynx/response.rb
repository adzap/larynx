module Larynx
  class Response
    attr_reader :header, :body

    def initialize(header, body)
      @header = CallHandler.headers_2_hash(header)
      if body
        @body = body.match(/:/) ? CallHandler.headers_2_hash(body) : body
        @body.each {|k,v| v.chomp! if v.is_a?(String)}
      end
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
      @body[:application] if @body
    end

    def event_name
      @body[:event_name] if @body
    end

    def dtmf?
      @body[:event_name] == 'DTMF' if @body
    end

    def speech?
      @body[:event_name] == 'DETECTED_SPEECH' if @body
    end

    def disconnect?
      @header[:content_type] == 'text/disconnect-notice'
    end
  end
end
