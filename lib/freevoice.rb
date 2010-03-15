require 'rubygems'
require 'eventmachine'
require 'active_support'
require 'daemons'

require 'freevoice/eventmachine'
require 'freevoice/observable'
require 'freevoice/callbacks'
require 'freevoice/parser'
require 'freevoice/session'
require 'freevoice/response'
require 'freevoice/command'
require 'freevoice/prompt'
require 'freevoice/application'
require 'freevoice/fields'
require 'freevoice/form'
require 'freevoice/call_handler'

module Freevoice
  class << self
    include Callbacks

    define_callback :connect, :answer, :hungup

    def start_server(ip, port)
      EM::run {
        EM::start_server ip, port, Freevoice::CallHandler
      }
    end

    def parse_options(args=ARGV)
      options = {:ip => "0.0.0.0", :port => 8084}
      opts = OptionParser.new
      opts.banner = "Usage: freevoice [options]"
      opts.separator ''
      opts.separator "Freevoice is a tool to develop FreeSWITCH IVR applications in Ruby."
      opts.on('-d', '--daemonize', 'Run as daemon')                     { options[:daemonize] = true }
      opts.on('-i', '--ip IP',     'Listen for connections on this IP') {|ip| options[:ip] = ip }
      opts.on('-p', '--port PORT', 'Listen on this port', Integer)      {|port| options[:port] = port }
      opts.on('-h', '--help',      'This is it')                        { $stderr.puts opts; exit 0 }
      opts.on('-v', '--version')                                        { $stderr.puts "freevoice version #{Freevoice::VERSION}"; exit 0 }
      opts.parse!(args)
      options
    end
  end
end


unless defined?(TEST)
  options = Freevoice.parse_options
  require ARGV[0]
  Daemons.daemonize if options[:daemonize]
  Freevoice.start_server(options[:ip], options[:port])
end
