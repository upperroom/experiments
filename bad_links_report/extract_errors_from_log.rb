#!/usr/bin/env ruby
########################################################
###
##  File: extract_errors_from_log.rb
##  Desc: Selects "ERROR:" messages from a SiteSucker error log file and reformats
##        with one error per line
#

require 'pathname'

unless 1 == ARGV.size
  puts
  puts "Usage: #{$0} error_log_file_name"
  puts "  Where:"
  puts "    error_log_file_name is required."
  puts
  exit(-1)
end

error_log_pathname = Pathname.new ARGV.first

print_next = 0

error_log_pathname.each_line do | a_line |

  if print_next > 0
    print a_line.chomp
    print_next -= 1
    next
  end

  if a_line.start_with?("ERROR:")
    print "\n" + a_line.chomp
    print_next = 2
  end

end

