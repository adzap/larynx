module Larynx
  module Parser
    def parse(data)
      vars = {}
      return vars if data.nil? || data == ''

      data = data.strip.split("\n") if data.is_a?(String)
      data.each do |line|
        begin
          parts = line.split(':')
          var = parts[0].strip.gsub('-', '_').downcase.to_sym
          vars[var] = URI.unescape(parts[1]).strip
        rescue
        end
      end
      vars
    end
  end
end
