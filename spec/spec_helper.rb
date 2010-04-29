$:.unshift File.expand_path(File.dirname(__FILE__) + '/lib')
$:.unshift File.expand_path(File.dirname(__FILE__) + '/spec')

TEST = true

require 'rubygems'
require 'em-spec/rspec'
require 'larynx'

LARYNX_LOGGER = Logger.new(STDOUT)
RESPONSES = {}
Dir['spec/fixtures/*.rb'].each {|file| require file }

class TestCallHandler < Larynx::CallHandler
  attr_accessor :sent_data, :session, :state, :queue, :input, :timers

  def send_data(msg)
    @sent_data = msg
  end

  def send_response(response)
    request = ::RESPONSES[response]
    receive_request(request[:header], request[:content])
  end

  def log(msg)
    (@log ||= '') << msg
  end
end

module SpecHelper
  def should_be_called(times=1, &block)
    proc = mock('Proc should be called')
    proc.should_receive(:call).exactly(times).times.instance_eval(&(block || lambda {}))
    lambda { |*args| proc.call(*args) }
  end

  def should_not_be_called(&block)
    proc = mock('Proc should not be called')
    proc.should_not_receive(:call).instance_eval(&(block || lambda {}))
    lambda { |*args| proc.call(*args) }
  end

  def reset_class(klass, &block)
    name = klass.name.to_sym
    Object.send(:remove_const, name)
    eval "class #{klass}#{' < ' + klass.superclass.to_s if klass.superclass != Class}; end", TOPLEVEL_BINDING
    new_klass = Object.const_get(name)
    new_klass.class_eval &block if block_given?
    new_klass
  end
end

Spec::Runner.configure do |config|
  config.include SpecHelper, EM::SpecHelper
end
