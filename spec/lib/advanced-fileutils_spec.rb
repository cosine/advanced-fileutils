require './spec/spec_helper.rb'
require './lib/advanced-fileutils.rb'
require 'tempfile'


describe AdvFileUtils do
  describe ".append" do
    before :each do
      @file = Tempfile.new File.basename($0)
      @file.close
      @path = @file.path
    end

    after :each do
      @file.delete if @file.path
    end

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
    before :each do
      @file = Tempfile.new File.basename($0)
      @file.close
      @path = @file.path
    end

    after :each do
      @file.delete if @file.path
    end

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
end
