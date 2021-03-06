require 'rubygems'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'spec/rake/spectask'
require 'lib/larynx/version'

GEM_NAME = "larynx"
GEM_VERSION = Larynx::VERSION

spec = Gem::Specification.new do |s|
  s.name = GEM_NAME
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.rubyforge_project = GEM_NAME
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc"]
  s.executables = ["larynx"]
  s.summary = "An evented application framework for the FreeSWITCH telephony platform"
  s.description = s.summary
  s.author = "Adam Meehan"
  s.email = "adam.meehan@gmail.com"
  s.homepage = "http://github.com/adzap/larynx"

  s.require_path = 'lib'
  s.files = %w(MIT-LICENSE README.rdoc Rakefile) + Dir.glob("{lib,spec,examples}/**/*")
  s.add_dependency "activesupport", ">= 2.3.5"
  s.add_dependency "eventmachine",  "~> 0.12.10"
  s.add_dependency "daemons",       "~> 1.1.0"
  s.add_development_dependency "rspec",   "~> 1.3.0"
  s.add_development_dependency "em-spec", "~> 0.1.3"
end

desc 'Default: run specs.'
task :default => :spec

spec_files = Rake::FileList["spec/**/*_spec.rb"]

desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = spec_files
  t.spec_opts = ["-c"]
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "install the gem locally"
task :install => [:package] do
  sh %{gem install pkg/#{GEM_NAME}-#{GEM_VERSION}}
end

desc "create a gemspec file"
task :make_spec do
  File.open("#{GEM_NAME}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end
