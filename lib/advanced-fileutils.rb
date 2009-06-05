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

  # Append the given +data+ to the file named by +filename+.
  def append (filename, *data_and_options)
    if block_given?
      options = data_and_options[0]

      if options[:verbose]
        $stderr.puts "cat \"$DATA\" >> #{Escape.shell_single_word(filename)}"
      end

      if not options[:noop]
        File.open(filename, 'a') do |f|
          yield f
        end
      end

    else
      data, options = *data_and_options

      if options[:verbose]
        $stderr.puts "echo #{Escape.shell_single_word(data)} >> #{Escape.shell_single_word(filename)}"
      end

      if not options[:noop]
        File.open(filename, 'a') do |f|
          f.write(data)
        end
      end
    end
  end
  module_function :append


  def truncate (filename, data = '', options = {})
  end


  def system (*command)
  end
end

