require 'rubygems'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'spec/rake/spectask'
require 'lib/freevoice/version'

GEM_NAME = "freevoice"
GEM_VERSION = Freevoice::VERSION

spec = Gem::Specification.new do |s|
  s.name = GEM_NAME
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.rubyforge_project = GEM_NAME
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc"]
  s.summary = ""
  s.description = s.summary
  s.author = "Adam Meehan"
  s.email = "adam.meehan@gmail.com"
  s.homepage = "http://github.com/adzap/freevoice"

  s.require_path = 'lib'
  s.autorequire = GEM_NAME
  s.files = %w(MIT-LICENSE README.rdoc Rakefile) + Dir.glob("{lib,spec}/**/*")
end

desc 'Default: run specs.'
task :default => :spec

spec_files = Rake::FileList["spec/**/*_spec.rb"]

desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = spec_files
  t.spec_opts = ["-c"]
end
