spec = Gem::Specification.new do |s|
  s.name = "advanced-fileutils"
  s.version = "0.0.2"
  s.author = "Michael H Buselli"
  s.add_dependency("escape", ">= 0.0.4")
  s.email = ["cosine@cosine.org", "michael@buselli.com"]
  #s.files = Dir["lib/**/*"]
  s.files = ["lib/fileutils", "lib/fileutils/advanced.rb", "lib/advanced-fileutils.rb"]
  s.require_path = "lib"
  s.has_rdoc = true
  s.rubyforge_project = "advanced-fileutils"
  s.homepage = "http://cosine.org/ruby/advanced-fileutils/"

  s.summary = "Advanced FileUtils contains more methods you might have wished were in FileUtils."

  s.description = <<-__EOF__
    Advanced FileUtils contains more methods you might have wished were in FileUtils.
  __EOF__
end
