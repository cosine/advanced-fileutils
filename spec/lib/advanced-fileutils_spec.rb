require './spec/spec_helper.rb'
require 'advanced-fileutils'
require 'tempfile'


describe AdvFileUtils do
  before :each do
    @file = Tempfile.new File.basename($0)
    @file.close
    @path = @file.path
  end

  after :each do
    @file.delete if @file.path
  end


  describe ".append" do
    it "should write data to an empty file" do
      AdvFileUtils.append(@path, "foo bar\n")
      File.read(@path).should == "foo bar\n"
    end

    it "should append data to the end of a file" do
      AdvFileUtils.append(@path, "foo bar\n")
      AdvFileUtils.append(@path, "bar baz\n")
      File.read(@path).should == "foo bar\nbar baz\n"
    end

    it "should create a new file if it doesn't exist" do
      @file.delete
      File.exists?(@path).should be_false
      AdvFileUtils.append(@path, "foo bar\n")
      File.read(@path).should == "foo bar\n"
    end

    it "should write data from a block" do
      AdvFileUtils.append(@path) { |f| f.puts "foo bar" }
      File.read(@path).should == "foo bar\n"
    end

    it "should not write to a file if passed :noop" do
      AdvFileUtils.append(@path, "foo bar\n", :noop => true)
      File.read(@path).should == ""
    end

    it "should not write to a file if passed :noop and a block" do
      AdvFileUtils.append(@path, :noop => true) { |f| f.puts "foo bar" }
      File.read(@path).should == ""
    end

    it "should emit verbose data if passed :verbose" do
      $stderr.should_receive(:puts).with("echo 'foo bar' >> #{@path}")
      AdvFileUtils.append(@path, "foo bar\n", :verbose => true)
    end

    it "should emit verbose data if passed :verbose and a block" do
      $stderr.should_receive(:puts).with("echo 'foo bar' >> #{@path}")
      AdvFileUtils.append(@path, :verbose => true) { |f| f.print "foo bar\n" }
    end

    it "should emit verbose data for each write if passed :verbose and a block" do
      $stderr.should_receive(:puts).with("echo 'foo bar' >> #{@path}").ordered
      $stderr.should_receive(:puts).with("echo 'bar baz' >> #{@path}").ordered

      AdvFileUtils.append(@path, :verbose => true) do |f|
        f.print "foo bar\n"
        f.print "bar baz\n"
      end
    end

    it "should emit verbose data differently for data without a newline" do
      $stderr.should_receive(:puts).with("echo 'foo bar\\c' >> #{@path}")
      AdvFileUtils.append(@path, "foo bar", :verbose => true)
    end

    it "should emit verbose data if passed :verbose and :noop" do
      $stderr.should_receive(:puts).with("echo 'foo bar' >> #{@path}")
      AdvFileUtils.append(@path, "foo bar\n", :noop => true, :verbose => true)
    end

    it "should emit verbose data if passed :verbose and :noop and a block" do
      $stderr.should_receive(:puts).with("echo 'foo bar' >> #{@path}")

      AdvFileUtils.append(@path, :noop => true, :verbose => true) do |f|
        f.print "foo bar\n"
      end
    end
  end


  describe ".truncate" do
    it "should overwrite an empty file" do
      AdvFileUtils.truncate(@path, "foo bar\n")
      File.read(@path).should == "foo bar\n"
    end

    it "should overwrite the file every time it is called" do
      AdvFileUtils.truncate(@path, "foo bar\n")
      AdvFileUtils.truncate(@path, "bar baz\n")
      File.read(@path).should == "bar baz\n"
    end

    it "should empty the file contents if called without data" do
      AdvFileUtils.truncate(@path, "foo bar\n")
      AdvFileUtils.truncate(@path)
      File.read(@path).should == ""
    end

    it "should create a new file if it doesn't exist" do
      @file.delete
      File.exists?(@path).should be_false
      AdvFileUtils.truncate(@path, "foo bar\n")
      File.read(@path).should == "foo bar\n"
    end

    it "should write data from a block" do
      AdvFileUtils.truncate(@path) { |f| f.puts "foo bar" }
      File.read(@path).should == "foo bar\n"
    end

    it "should not write to a file if passed :noop" do
      AdvFileUtils.truncate(@path, "foo bar\n", :noop => true)
      File.read(@path).should == ""
    end

    it "should not overwrite data if passed :noop" do
      AdvFileUtils.truncate(@path, "foo bar\n")
      AdvFileUtils.truncate(@path, "bar baz\n", :noop => true)
      File.read(@path).should == "foo bar\n"
    end

    it "should not write to a file if passed :noop and a block" do
      AdvFileUtils.truncate(@path, :noop => true) { |f| f.puts "foo bar" }
      File.read(@path).should == ""
    end

    it "should emit verbose data if passed :verbose" do
      $stderr.should_receive(:puts).with("echo 'foo bar' > #{@path}")
      AdvFileUtils.truncate(@path, "foo bar\n", :verbose => true)
    end

    it "should emit verbose data if passed :verbose and a block" do
      $stderr.should_receive(:puts).with("cat /dev/null > #{@path}").ordered
      $stderr.should_receive(:puts).with("echo 'foo bar' >> #{@path}").ordered
      AdvFileUtils.truncate(@path, :verbose => true) { |f| f.print "foo bar\n" }
    end

    it "should emit verbose data for each write if passed :verbose and a block" do
      $stderr.should_receive(:puts).with("cat /dev/null > #{@path}").ordered
      $stderr.should_receive(:puts).with("echo 'foo bar' >> #{@path}").ordered
      $stderr.should_receive(:puts).with("echo 'bar baz' >> #{@path}").ordered

      AdvFileUtils.truncate(@path, :verbose => true) do |f|
        f.print "foo bar\n"
        f.print "bar baz\n"
      end
    end

    it "should emit verbose data differently for data without a newline" do
      $stderr.should_receive(:puts).with("echo 'foo bar\\c' > #{@path}")
      AdvFileUtils.truncate(@path, "foo bar", :verbose => true)
    end

    it "should emit verbose data if passed :verbose and :noop" do
      $stderr.should_receive(:puts).with("echo 'foo bar' > #{@path}")
      AdvFileUtils.truncate(@path, "foo bar\n", :noop => true, :verbose => true)
    end

    it "should emit verbose data if passed :verbose and :noop and a block" do
      $stderr.should_receive(:puts).with("cat /dev/null > #{@path}").ordered
      $stderr.should_receive(:puts).with("echo 'foo bar' >> #{@path}").ordered

      AdvFileUtils.truncate(@path, :noop => true, :verbose => true) do |f|
        f.print "foo bar\n"
      end
    end
  end


  describe ".system" do
    it "should run the given one-argument command in a shell" do
      AdvFileUtils.system("echo 'foo bar' > #{@path}")
      File.read(@path).should == "foo bar\n"
    end

    it "should run the given multiple-argument command" do
      AdvFileUtils.system("sh", "-c", "echo 'foo bar' > #{@path}")
      File.read(@path).should == "foo bar\n"
    end

    it "should raise an ArgumentError if not given any arguments" do
      proc { AdvFileUtils.system }.should raise_error(ArgumentError)
    end

    it "should print the shell command when given the :verbose option" do
      $stderr.should_receive(:puts).with("echo 'foo bar' > #{@path}")
      AdvFileUtils.system("echo 'foo bar' > #{@path}", :verbose => true)
    end

    it "should print the full command when given the :verbose option" do
      $stderr.should_receive(:puts).with("sh -c 'echo '\\''foo bar'\\'' > #{@path}'")
      AdvFileUtils.system("sh", "-c", "echo 'foo bar' > #{@path}", :verbose => true)
    end

    it "should not run a command with passed the :noop option" do
      AdvFileUtils.system("echo 'foo bar' > #{@path}", :noop => true)
      File.read(@path).should == ""
    end

    it "should not run the given multiple-argument command when passed :noop" do
      AdvFileUtils.system("sh", "-c", "echo 'foo bar' > #{@path}", :noop => true)
      File.read(@path).should == ""
    end

    it "should raise an ArgumentError if only passed an option" do
      proc { AdvFileUtils.system(:verbose => true) }.
          should raise_error(ArgumentError)
    end

    it "should not print verbosity information if only passed :verbose" do
      $stderr.stub!(:write).and_return { raise Exception.new }
      proc { AdvFileUtils.system(:verbose => true) }.
          should raise_error(ArgumentError)
    end

    it "should function if invoked as \"sh\"" do
      AdvFileUtils.sh("echo 'foo bar' > #{@path}")
      File.read(@path).should == "foo bar\n"
    end

    it "should function if invoked as \"shell\"" do
      AdvFileUtils.shell("echo 'foo bar' > #{@path}")
      File.read(@path).should == "foo bar\n"
    end
  end


  describe ".edit" do
    before :all do
      @editor_file = Tempfile.new File.basename($0)
      @editor_file.close
      @editor = @editor_file.path
      AdvFileUtils.truncate(@editor, <<-__EOF__.gsub(/^.{8}/, ''))
        #!/usr/bin/env ruby

        Process.kill('TERM', $$) if ENV['TEST_DIE_ON_SIGNAL']

        File.open(ARGV[0], 'r+') do |file|
          data = file.read
          file.rewind
          file.print data.gsub(/foo|bar|baz/) {|x| x.upcase}
        end
      __EOF__

      FileUtils.chmod(0700, @editor)
      @saved_env = {}
      @reset_vars = ['VISUAL', 'EDITOR', 'TEST_DIE_ON_SIGNAL']
      @reset_vars.each {|var| @saved_env[var] = ENV[var] }
    end

    after :all do
      @editor_file.delete
    end

    before :each do
      ENV['VISUAL'] = @editor
      AdvFileUtils.truncate(@path, "foo bar\n")
    end

    after :each do
      @reset_vars.each {|var| ENV[var] = @saved_env[var] }
    end

    it "should invoke an external editor on the file" do
      Kernel.should_receive(:system).with(@editor, @path)
      AdvFileUtils.edit(@path)
    end

    it "should return true if successful with new data in file" do
      sleep 1.02    # sleep so that mtime increments
      AdvFileUtils.edit(@path).should be_true
    end

    it "should return nil if the user did not save any data" do
      ENV['VISUAL'] = 'true'
      sleep 1.02    # sleep so that mtime increments
      AdvFileUtils.edit(@path).should be_nil
    end

    it "should return false if the user saved the original data to the file" do
      ENV['VISUAL'] = 'touch'
      sleep 1.02    # sleep so that mtime increments
      AdvFileUtils.edit(@path).should be_false
    end

    it "should raise a CommandError if the editor cannot be launched" do
      ENV['VISUAL'] = 'foo-bar-baz'
      proc { AdvFileUtils.edit(@path) }.should raise_error(AdvFileUtils::CommandError)
    end

    it "should raise a CommandError if the editor exits with non-zero code" do
      ENV['VISUAL'] = 'false'
      proc { AdvFileUtils.edit(@path) }.should raise_error(AdvFileUtils::CommandError)
    end

    it "should raise a CommandError if the editor dies on a signal" do
      ENV['TEST_DIE_ON_SIGNAL'] = '1'
      proc { AdvFileUtils.edit(@path) }.should raise_error(AdvFileUtils::CommandError)
    end

    it "should result in the data in the file being edited" do
      AdvFileUtils.edit(@path)
      File.read(@path).should == "FOO BAR\n"
    end

    it "should not edit the file if the editor cannot be launched" do
      ENV['VISUAL'] = 'foo-bar-baz'
      begin
        AdvFileUtils.edit(@path)
      rescue AdvFileUtils::CommandError
      end
      File.read(@path).should == "foo bar\n"
    end

    it "should not edit the file if the editor exists with non-zero code" do
      ENV['VISUAL'] = 'false'
      begin
        AdvFileUtils.edit(@path)
      rescue AdvFileUtils::CommandError
      end
      File.read(@path).should == "foo bar\n"
    end

    it "should not edit the file if the editor dies on a signal" do
      ENV['TEST_DIE_ON_SIGNAL'] = '1'
      begin
        AdvFileUtils.edit(@path)
      rescue AdvFileUtils::CommandError
      end
      File.read(@path).should == "foo bar\n"
    end

    it "should print the editor command if :verbose is true" do
      $stderr.should_receive(:puts).with("#{@editor} #{@path}")
      AdvFileUtils.edit(@path, :verbose => true)
    end

    it "should not invoke the editor if :noop is true" do
      Kernel.should_not_receive(:system)
      AdvFileUtils.edit(@path, :noop => true)
    end

    it "should run the editor in the VISUAL environment variable if set" do
      ENV['VISUAL'] = 'from-visual'
      Kernel.should_receive(:system).with('from-visual', @path)
      AdvFileUtils.edit(@path)
    end

    it "should run the editor in the EDITOR environment variable if VISUAL is not set" do
      ENV.delete 'VISUAL'
      ENV['EDITOR'] = 'from-editor'
      Kernel.should_receive(:system).with('from-editor', @path)
      AdvFileUtils.edit(@path)
    end

    it "should not run the editor in the EDITOR environment variable if VISUAL is set" do
      ENV['EDITOR'] = 'from-editor'
      Kernel.should_not_receive(:system).with('from-editor', @path)
      AdvFileUtils.edit(@path)
    end

    it "should run \"vi\" if VISUAL and EDITOR are not set" do
      ENV.delete 'VISUAL'
      ENV.delete 'EDITOR'
      Kernel.should_receive(:system).with('vi', @path)
      AdvFileUtils.edit(@path)
    end
  end


  describe ".replace" do
    it "should overwrite an empty file" do
      AdvFileUtils.replace(@path, "foo bar\n")
      File.read(@path).should == "foo bar\n"
    end

    it "should replace the file every time it is called" do
      AdvFileUtils.replace(@path, "foo bar\n")
      AdvFileUtils.replace(@path, "bar baz\n")
      File.read(@path).should == "bar baz\n"
    end

    it "should empty the file contents if called without data" do
      AdvFileUtils.replace(@path, "foo bar\n")
      AdvFileUtils.replace(@path)
      File.read(@path).should == ""
    end

    it "should create a new file if it doesn't exist" do
      @file.delete
      File.exists?(@path).should be_false
      AdvFileUtils.replace(@path, "foo bar\n")
      File.read(@path).should == "foo bar\n"
    end

    it "should write data from a block" do
      AdvFileUtils.replace(@path) { |f| f.puts "foo bar" }
      File.read(@path).should == "foo bar\n"
    end

    it "should not write to a file if passed :noop" do
      AdvFileUtils.replace(@path, "foo bar\n", :noop => true)
      File.read(@path).should == ""
    end

    it "should not overwrite data if passed :noop" do
      AdvFileUtils.replace(@path, "foo bar\n")
      AdvFileUtils.replace(@path, "bar baz\n", :noop => true)
      File.read(@path).should == "foo bar\n"
    end

    it "should not write to a file if passed :noop and a block" do
      AdvFileUtils.replace(@path, :noop => true) { |f| f.puts "foo bar" }
      File.read(@path).should == ""
    end

    it "should emit verbose data if passed :verbose" do
      $stderr.should_receive(:puts).with("echo 'foo bar' > #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("chown #{Process.uid}:#{Process.gid} #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("chmod 600 #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("mv #{@path}.lock #{@path}").ordered
      AdvFileUtils.replace(@path, "foo bar\n", :verbose => true)
    end

    it "should emit verbose data if passed :verbose and a block" do
      $stderr.should_receive(:puts).with("cat /dev/null > #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("echo 'foo bar' >> #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("chown #{Process.uid}:#{Process.gid} #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("chmod 600 #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("mv #{@path}.lock #{@path}").ordered
      AdvFileUtils.replace(@path, :verbose => true) { |f| f.print "foo bar\n" }
    end

    it "should emit verbose data for each write if passed :verbose and a block" do
      $stderr.should_receive(:puts).with("cat /dev/null > #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("echo 'foo bar' >> #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("echo 'bar baz' >> #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("chown #{Process.uid}:#{Process.gid} #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("chmod 600 #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("mv #{@path}.lock #{@path}").ordered

      AdvFileUtils.replace(@path, :verbose => true) do |f|
        f.print "foo bar\n"
        f.print "bar baz\n"
      end
    end

    it "should emit verbose data differently for data without a newline" do
      $stderr.should_receive(:puts).with("echo 'foo bar\\c' > #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("chown #{Process.uid}:#{Process.gid} #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("chmod 600 #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("mv #{@path}.lock #{@path}").ordered
      AdvFileUtils.replace(@path, "foo bar", :verbose => true)
    end

    it "should emit verbose data if passed :verbose and :noop" do
      $stderr.should_receive(:puts).with("echo 'foo bar' > #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("chown #{Process.uid}:#{Process.gid} #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("chmod 600 #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("mv #{@path}.lock #{@path}").ordered
      AdvFileUtils.replace(@path, "foo bar\n", :noop => true, :verbose => true)
    end

    it "should emit verbose data if passed :verbose and :noop and a block" do
      $stderr.should_receive(:puts).with("cat /dev/null > #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("echo 'foo bar' >> #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("chown #{Process.uid}:#{Process.gid} #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("chmod 600 #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("mv #{@path}.lock #{@path}").ordered

      AdvFileUtils.replace(@path, :noop => true, :verbose => true) do |f|
        f.print "foo bar\n"
      end
    end

    it "should emit verbose data if passed :verbose and a non-existant file" do
      $stderr.should_receive(:puts).with("echo 'foo bar' > #{@path}.lock").ordered
      $stderr.should_receive(:puts).with("mv #{@path}.lock #{@path}").ordered

      $stderr.should_not_receive(:puts).with(/\bchown\b/)
      $stderr.should_not_receive(:puts).with(/\bchmod\b/)

      @file.delete
      File.exists?(@path).should be_false
      AdvFileUtils.replace(@path, "foo bar\n", :verbose => true)
    end
  end
end
