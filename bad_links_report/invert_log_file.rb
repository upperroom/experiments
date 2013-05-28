#!/usr/bin/env ruby
########################################################
###
##  File: invert_bad_links.rb
##  Desc: Inverts the sort order of a pre-processed SiteSucker error log file
##        with only error code 1100 "file not found" errors.  Output is a list
##        URLs with all of their bad links indented underneath
#

require 'pathname'

unless 1 == ARGV.size
  puts
  puts "Usage: #{$0} bad_links_file_name"
  puts "  Where:"
  puts "    bad_links_file_name is required."
  puts
  exit(-1)
end

bad_links_pathname = Pathname.new ARGV.first

bad_links_pathname.each_line do |a_line|

  items = a_line.split('"')
  bad_link  = items[1]
  from_link = items[3]

  puts "ERROR: #{from_link}  has bad hyper-link to: #{bad_link}"

end
