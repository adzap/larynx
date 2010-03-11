require 'rubygems'
require 'eventmachine'
require 'active_support'

require 'freevoice/eventmachine'
require 'freevoice/observable'
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
    attr_reader :answer_block
    attr_reader :hungup_block

    def answer(&block)
      @answer_block = block
    end

    def hungup(&block)
      @hungup_block = block
    end

    def start_server(ip="0.0.0.0", port=8084)
      EM::run {
        EM::start_server ip, port, Freevoice::CallHandler
      }
    end
  end
end

require ARGV[0]

Freevoice.start_server unless defined?(TEST)
