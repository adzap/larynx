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

    def answer(&block)
      @answer_block = block
    end
  end
end

require ARGV[0]

EventMachine::run {
  EventMachine::start_server "0.0.0.0", 8084, Freevoice::CallHandler
}
