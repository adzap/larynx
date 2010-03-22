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
end

Spec::Runner.configure do |config|
  config.include SpecHelper, EM::SpecHelper
end
