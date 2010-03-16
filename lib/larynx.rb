require 'rubygems'
require 'eventmachine'
require 'active_support'
require 'daemons'

require 'larynx/eventmachine'
require 'larynx/observable'
require 'larynx/callbacks'
require 'larynx/parser'
require 'larynx/session'
require 'larynx/response'
require 'larynx/command'
require 'larynx/commands'
require 'larynx/prompt'
require 'larynx/application'
require 'larynx/fields'
require 'larynx/form'
require 'larynx/call_handler'

module Larynx
  class << self
    include Callbacks

    define_callback :connect, :answer, :hungup

    def start_server(ip, port)
      EM::run {
        EM::start_server ip, port, Larynx::CallHandler
      }
    end

    def parse_options(args=ARGV)
      options = {:ip => "0.0.0.0", :port => 8084}
      opts = OptionParser.new
      opts.banner = "Usage: larynx [options]"
      opts.separator ''
      opts.separator "Larynx is a tool to develop FreeSWITCH IVR applications in Ruby."
      opts.on('-d', '--daemonize', 'Run as daemon')                     { options[:daemonize] = true }
      opts.on('-i', '--ip IP',     'Listen for connections on this IP') {|ip| options[:ip] = ip }
      opts.on('-p', '--port PORT', 'Listen on this port', Integer)      {|port| options[:port] = port }
      opts.on('-h', '--help',      'This is it')                        { $stderr.puts opts; exit 0 }
      opts.on('-v', '--version')                                        { $stderr.puts "Larynx version #{Larynx::VERSION}"; exit 0 }
      opts.parse!(args)
      options
    end
  end
end


unless defined?(TEST)
  options = Larynx.parse_options
  require ARGV[0]
  Daemons.daemonize if options[:daemonize]
  Larynx.start_server(options[:ip], options[:port])
end
