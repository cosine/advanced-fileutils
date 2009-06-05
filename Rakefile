
require 'rake/gempackagetask'
require 'spec/rake/spectask'

spec = Gem::Specification.new do |s|
  s.name = "advanced-fileutils"
  s.version = "0.0.1"
  s.author = "Michael H Buselli"
  s.add_dependency("escape", ">= 0.0.4")
  s.email = ["cosine@cosine.org", "michael@buselli.com"]
  s.files = Dir["lib/**/*"]
  s.require_path = "lib"
  s.has_rdoc = false
  s.rubyforge_project = "advanced-fileutils"
  s.homepage = "http://cosine.org/ruby/advanced-fileutils/"

  s.summary = "Advanced FileUtils contains more methods you might have wished were in FileUtils."

  s.description = <<-__EOF__
    Advanced FileUtils contains more methods you might have wished were in FileUtils.
  __EOF__
end


Rake::GemPackageTask.new(spec) {}


desc "Run the RSpec tests"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList["spec/**/*_spec.rb"]
  t.spec_opts = ['-c', '-f s']
end


desc "Clean up generated files and directories"
task :clean do |t|
  rm_rf "pkg"
end


task :default => :gem
