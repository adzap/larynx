require 'rubygems'
require 'eventmachine'
require 'active_support'
require 'logger'
require 'daemons/daemonize'

require 'larynx/version'
require 'larynx/logger'
require 'larynx/observable'
require 'larynx/callbacks'
require 'larynx/session'
require 'larynx/response'
require 'larynx/command'
require 'larynx/commands'
require 'larynx/prompt'
require 'larynx/application'
require 'larynx/fields'
require 'larynx/form'
require 'larynx/restartable_timer'
require 'larynx/call_handler'

module Larynx
  class << self
    include Callbacks

    define_callback :connect, :answer, :hungup

    def parse_options(args=ARGV)
      @options = {
        :ip       => "0.0.0.0",
        :port     => 8084,
        :pid_file => './larynx.pid',
        :log_file => './larynx.log'
      }
      opts = OptionParser.new
      opts.banner = "Usage: larynx [options]"
      opts.separator ''
      opts.separator "Larynx is a tool to develop FreeSWITCH IVR applications in Ruby."
      opts.on('-i', '--ip IP',         'Listen for connections on this IP') {|ip| @options[:ip] = ip }
      opts.on('-p', '--port PORT',     'Listen on this port', Integer)      {|port| @options[:port] = port }
      opts.on('-d', '--daemonize',     'Run as daemon')                     { @options[:daemonize] = true }
      opts.on('-l', '--log-file FILE', 'Defaults to /app/root/larynx.log')  {|log| @options[:log_file] = log }
      opts.on(      '--pid-file FILE', 'Defaults to /app/root/larynx.pid')  {|pid| @options[:pid_file] = pid }
      opts.on('-h', '--help',          'This is it')                        { $stderr.puts opts; exit 0 }
      opts.on('-v', '--version')                                            { $stderr.puts "Larynx version #{Larynx::VERSION}"; exit 0 }
      opts.parse!(args)
    end

    def setup_logger
      logger = Larynx::Logger.new(@options[:log_file])
      logger.level = Logger::INFO
      Object.const_set "LARYNX_LOGGER", logger
    end

    def graceful_exit
      LARYNX_LOGGER.info "Shutting down Larynx"
      EM.stop_server @em_signature
      @em_signature = nil
      remove_pid_file if @options[:daemonize]
      exit 130
    end

    def daemonize
      Daemonize.daemonize
      Dir.chdir LARYNX_ROOT
      File.open(@options[:pid_file], 'w+') {|f| f.write("#{Process.pid}\n") }
    end

    def remove_pid_file
      File.delete @options[:pid_file]
    end

    def trap_signals
      trap('TERM') { graceful_exit }
      trap('INT')  { graceful_exit }
    end

    def setup_app
      if ARGV[0].nil?
        $stderr.puts "You must specify an application file"
        exit -1
      end
      Object.const_set "LARYNX_ROOT", File.expand_path(File.dirname(ARGV[0]))
      require File.expand_path(ARGV[0])
    end

    def start_server
      LARYNX_LOGGER.info "Larynx starting up on #{@options[:ip]}:#{@options[:port]}"
      EM::run {
        @em_signature = EM::start_server @options[:ip], @options[:port], Larynx::CallHandler
      }
    end

    def run
      parse_options(ARGV)
      setup_app
      daemonize if @options[:daemonize]
      setup_logger
      trap_signals
      start_server
    end

    def running?
      !@em_signature.nil?
    end
  end
end

Larynx.run unless defined?(TEST)
