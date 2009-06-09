#
# = advanced-fileutils.rb
#
# Copyright (c) 2009 Michael H. Buselli
#
# This program is free software.
# You can distribute/modify this program under the same terms of Ruby.
#
# == module AdvFileUtils
#
# Advanced FileUtils contains more methods you might have wished were in
# FileUtils.
#
# === Module Functions
#
#   append(filename, data, options)
#   append(filename, options) {|file| .... }
#   truncate(filename, options)
#   truncate(filename, data, options)
#   truncate(filename, options) {|file| .... }
#   replace(filename, data, options)            # does "atomic" file change
#   replace(filename, options) {|file| .... }
# x_insert(filename, data, options)             # :line => 7
# x_insert(filename, options) {|file| .... }
# x_update(filename, data, options)             # :line => 7
# x_update(filename, options) {|file| .... }    # :lines => 7..10
#                                               # :separator => ':'
#                                               # :where => '$1 = mbuselli'
#   edit(filename, options)                     # :visual => true
#   edit(filename, data, options)
#   system(command_list, options)
#   shell(command_list, options)                # alias of system
#   sh(command_list, options)                   # alias of system
# x_sudo(command_list, options)                 # :runas => 0
#
# Many options are not implemented yet.
#

require 'sha1'
require 'escape'

module AdvFileUtils

  #
  # A superclass of all errors that can be raised from this module's
  # functions.
  #
  class Error < Exception; end

  #
  # CommandError is raised when an external command has a problem.
  #
  class CommandError < AdvFileUtils::Error; end

  #
  # FileLockError is raised when trying to open an agreed upon "lockfile"
  # and the file already exists.
  #
  class FileLockError < AdvFileUtils::Error; end


  # Hash table to hold command options.
  OPT_TABLE = {}        #:nodoc: internal use only


  # Method for internal use to prep output for file output verbose messages.
  def write_echo_message (data, op, filename)           #:nodoc:
    [ 'echo',
      Escape.shell_single_word(
        if data[-1] == "\n"[0]
          data[0...-1]
        else
          data + '\\c'
        end),
      op,
      Escape.shell_single_word(filename)
    ].join(' ')
  end
  module_function :write_echo_message
  private_class_method :write_echo_message


  # Method for internal use to intercept write calls when we are being verbose.
  def hook_write (object, filename, tail_msg = nil)    #:nodoc:
    object.instance_eval <<-__EOM__, __FILE__, __LINE__ + 1
      class << self
        def write (data, *args)
            $stderr.puts AdvFileUtils.__send__(:write_echo_message, data, '>>', #{filename.inspect})
            super
          ensure
            send #{tail_msg.inspect} if #{tail_msg.inspect}
        end
      end
    __EOM__
  end
  module_function :hook_write
  private_class_method :hook_write


  def parse_data_and_options (data_and_options)         #:nodoc#
    if data_and_options.size == 1
      if data_and_options[0].respond_to? :has_key?
        options = data_and_options[0]
      else
        data = data_and_options[0]
      end
    else
      data, options = *data_and_options
    end

    data ||= ''
    options ||= {}
    [data, options]
  end
  module_function :parse_data_and_options
  private_class_method :parse_data_and_options


  #
  # Internally used function to implement .append and .truncate.
  #
  def generic_write (open_arg, filename, *data_and_options)     #:nodoc:
    if block_given?
      options = data_and_options[0] || {}

      if options[:verbose] and open_arg == 'w'
        $stderr.puts "cat /dev/null > #{Escape.shell_single_word(filename)}"
      end

      if not options[:noop]
        File.open(filename, open_arg) do |f|
          hook_write(f, filename) if options[:verbose]
          yield f
        end

      elsif options[:verbose]
        f = StringIO.new
        hook_write(f, filename, :rewind)
        yield f
      end

    else
      data, options = *parse_data_and_options(data_and_options)

      if options[:verbose]
        if open_arg == 'w'
          $stderr.puts AdvFileUtils.__send__(:write_echo_message, data, '>', filename)
        else
          $stderr.puts AdvFileUtils.__send__(:write_echo_message, data, '>>', filename)
        end
      end

      if not options[:noop]
        File.open(filename, open_arg) do |f|
          f.write(data)
        end
      end
    end
  end
  module_function :generic_write
  private_class_method :generic_write


  #
  # Options: verbose, noop, force, backup
  #
  # Append the given +data+ to the file named by +filename+.
  #
  # If called with a block then the File object is yielded to the block
  # for appending data intead of the data being passed as an argument.
  #
  #   AdvFileUtils.append('data.log', "some data for log entry\n")
  #   AdvFileUtils.append('data.log') { |f| f.puts "some data for log entry" }
  #
  def append (filename, *data_and_options, &block)
    generic_write 'a', filename, *data_and_options, &block
  end
  module_function :append
  public :append

  OPT_TABLE['append'] = [:verbose, :noop, :force, :backup]


  #
  # Options: verbose, noop, force, backup
  #
  # Replace the given +data+ in the file named by +filename+.
  #
  # If called with a block then the File object is yielded to the block
  # for writing data intead of the data being passed as an argument.
  #
  #   AdvFileUtils.truncate('data.log', "some data\n")
  #   AdvFileUtils.truncate('data.log') { |f| f.puts "some data" }
  #
  def truncate (filename, *data_and_options, &block)
    generic_write 'w', filename, *data_and_options, &block
  end
  module_function :truncate
  public :truncate

  OPT_TABLE['truncate'] = [:verbose, :noop, :force, :backup]


  #
  # Options: verbose, noop
  #
  # An alternative to Kernel.system that accepts options for verbosity
  # and dry runs.
  #
  def system (*command_and_options)
    if command_and_options[-1].respond_to?(:has_key?)
      command = command_and_options[0...-1]
      options = command_and_options[-1]
    else
      command = command_and_options
      options = {}
    end

    raise ArgumentError.new('wrong number of arguments') if command.empty?

    if options[:verbose]
      if command.size == 1
        $stderr.puts command[0]
      else
        $stderr.puts command.collect { |word|
          Escape.shell_single_word word
        }.join(' ')
      end
    end

    if not options[:noop]
      Kernel.system(*command)
    end
  end
  module_function :system
  public :system

  alias sh system
  module_function :sh
  public :sh

  alias shell system
  module_function :shell
  public :shell

  OPT_TABLE['sh'] = OPT_TABLE['shell'] =
  OPT_TABLE['system'] = [:verbose, :noop]


  #
  # Options: verbose, noop, force, backup
  #
  # Invoke an external editor to edit some text or a file.
  #
  #   edit(filename, options)
  #   edit(filename, data, options)
  #   edit(nil, data, options)
  #
  # Return values
  #
  #   true, if successful and file was edited
  #   false, if successful and file was not edited
  #   nil, if successful and file was not saved
  #
  def edit (filename, *data_and_options)
    data, options = *parse_data_and_options(data_and_options)
    editor =
        ENV.has_key?('VISUAL') ? ENV['VISUAL'] :
        ENV.has_key?('EDITOR') ? ENV['EDITOR'] : 'vi'

    file_stat = File.stat(filename)
    file_checksum = SHA1.file(filename)
    system(editor, filename, options)
    proc_status = $?

    if options[:noop]
      return true

    elsif proc_status.success?
      return nil if file_stat == File.stat(filename)
      return false if file_checksum == SHA1.file(filename)
      return true

    elsif proc_status.signaled?
      raise AdvFileUtils::CommandError.new("editor terminated on signal #{proc_status.termsig}")

    else
      raise AdvFileUtils::CommandError.new("editor had non-zero exit code #{proc_status.exitstatus}")
    end
  end
  module_function :edit
  public :edit

  OPT_TABLE['edit'] = [:verbose, :noop, :force, :backup]


  #
  # Options: verbose, noop, force, backup, lockfile, retry
  #
  # Edit a file, but open a temporary lockfile instead and move it in place
  # after editting is complete.
  #
  def replace (filename, *data_and_options)
    data, options = *parse_data_and_options(data_and_options)
    lockfile = options[:lockfile] ? options[:lockfile] : "#{filename}.lock"

    begin
      if not options[:noop]
        fd = IO.sysopen(lockfile, IO::WRONLY | IO::CREAT | IO::EXCL, 0700)
        f = IO.new(fd, 'w')
        hook_write(f, lockfile) if block_given? and options[:verbose]
      else
        f = StringIO.new
        hook_write(f, lockfile, :rewind) if block_given? and options[:verbose]
      end

      file_stat = File.stat(filename) rescue nil

      if block_given?
        $stderr.puts "cat /dev/null > #{Escape.shell_single_word(lockfile)}" if options[:verbose]
        yield f
      else
        $stderr.puts AdvFileUtils.__send__(:write_echo_message, data, '>', lockfile) if options[:verbose]
        f.write(data)
      end

      f.close

      if file_stat
        FileUtils.chown(file_stat.uid.to_s, file_stat.gid.to_s, lockfile, options)
        FileUtils.chmod(file_stat.mode & 07777, lockfile, options)
      end
      FileUtils.mv(lockfile, filename, options)

    ensure
      f.close if f and not f.closed?
      begin
        File.delete(lockfile) if fd
      rescue Errno::ENOENT
      end
    end
  end
  module_function :replace
  public :replace

  OPT_TABLE['replace'] = [:verbose, :noop, :force, :backup, :lockfile, :retry]
end
