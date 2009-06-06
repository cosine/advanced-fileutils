require './spec/spec_helper.rb'
require './lib/fileutils/advanced.rb'

# Load the tests for the AdvFileUtils module and run them again for the
# FileUtils module.
spec_file = File.join(File.dirname(File.dirname(__FILE__)), 'advanced-fileutils_spec.rb')
eval(File.read(spec_file).gsub(/\bAdvFileUtils\b/, "FileUtils"),
     binding, spec_file, 1)
