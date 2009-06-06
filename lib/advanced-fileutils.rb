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
#   insert(filename, data, options)             # :line => 7
#   insert(filename, options) {|file| .... }
#   update(filename, data, options)             # :line => 7
#   update(filename, options) {|file| .... }    # :lines => 7..10
#                                               # :separator => ':'
#                                               # :where => '$1 = mbuselli'
#   edit(filename, options)                     # :visual => true
#   edit(filename, data, options)
#   system(command_list, options)
#   shell(command_list, options)                # alias of system
#   sh(command_list, options)                   # alias of system
#   sudo(command_list, options)                 # :runas => 0
#
#   Something to do "atomic" file changes.
#

require 'escape'

module AdvFileUtils

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


  # Method for internal use to intercept write calls when we are being verbose.
  def hook_write (object, filename, tail_msg = nil)    #:nodoc:
    object.instance_eval <<-__EOM__, __FILE__, __LINE__
      class << self
        def write (data, *args)
            $stderr.puts AdvFileUtils.write_echo_message(data, '>>', #{filename.inspect})
            super
          ensure
            send #{tail_msg.inspect} if #{tail_msg.inspect}
        end
      end
    __EOM__
  end
  module_function :hook_write
  private_class_method :hook_write
  #private :hook_write


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
      data, options = *data_and_options
      data ||= ''
      options ||= {}

      if options[:verbose]
        if open_arg == 'w'
          $stderr.puts AdvFileUtils.write_echo_message(data, '>', filename)
        else
          $stderr.puts AdvFileUtils.write_echo_message(data, '>>', filename)
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
  # Options: verbose, noop, force, preserve
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

  OPT_TABLE['append'] = [:verbose, :noop, :force, :preserve]


  def truncate (filename, *data_and_options, &block)
    generic_write 'w', filename, *data_and_options, &block
  end
  module_function :truncate

  OPT_TABLE['truncate'] = [:verbose, :noop, :force, :preserve]


  def system (*command)
  end
end

