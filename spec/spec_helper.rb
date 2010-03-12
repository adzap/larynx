$:.unshift File.expand_path(File.dirname(__FILE__) + '/lib')
$:.unshift File.expand_path(File.dirname(__FILE__) + '/spec')

TEST = true

require 'rubygems'
require 'em-spec/rspec'
require 'freevoice'

RESPONSES = {}
Dir['spec/fixtures/*.rb'].each {|file| require file }

module SpecHelper
end

Spec::Runner.configure do |config|
  config.include SpecHelper, EM::SpecHelper
end
