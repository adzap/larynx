module Larynx
  class Logger < ::Logger
    def format_message(severity, timestamp, progname, msg)
      time = timestamp.strftime("%Y-%m-%dT%H:%M:%S.") << "%06d" % timestamp.usec
      "[%s] %5s: %s\n" % [time, severity, msg]
    end
  end
end
