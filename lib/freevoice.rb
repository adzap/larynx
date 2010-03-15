require 'rubygems'
require 'eventmachine'
require 'active_support'

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

    def start_server(ip="0.0.0.0", port=8084)
      EM::run {
        EM::start_server ip, port, Freevoice::CallHandler
      }
    end
  end
end


unless defined?(TEST)
  require ARGV[0]
  Freevoice.start_server
end
