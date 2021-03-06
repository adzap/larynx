require 'rubygems'
require 'eventmachine'
require 'active_support'
require 'active_support/core_ext/module'
require 'active_support/core_ext/class'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'

require 'larynx/version'
require 'larynx/logger'
require 'larynx/server'
require 'larynx/observable'
require 'larynx/callbacks'
require 'larynx/callbacks_with_async'
require 'larynx/session'
require 'larynx/response'
require 'larynx/command'
require 'larynx/commands'
require 'larynx/prompt'
require 'larynx/application'
require 'larynx/field'
require 'larynx/form'
require 'larynx/menu'
require 'larynx/restartable_timer'
require 'larynx/call_handler'

module Larynx
  mattr_accessor :prompt_defaults
  @@prompt_defaults = {
    :bargein  => true,
    :termchar => '#',
    :timeout  => 10,
    :interdigit_timeout => 3
  }

  mattr_accessor :field_defaults
  @@field_defaults = {
    :attempts => 3
  }

  def self.setup
    yield self if block_given?
  end

  class << self
    include Callbacks
    define_callback :connect, :answer, :hungup
  end

  # Default connect callback is to answer call
  connect {|call| call.answer }
end
