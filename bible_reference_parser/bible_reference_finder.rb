#!/usr/bin/env ruby
##########################################################
###
##  File: bible_reference_finder.rb
##  Desc: Finds valid bible references in text
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'awesome_print'
require 'pp'
require 'pathname'
require 'debug_me'

require 'pericope'

#require 'bible_reference_parser'
#include BibleReferenceParser

pgm_name = Pathname.new(__FILE__).basename

usage = <<EOS

Finds valid bible references in text

Usage: #{pgm_name} options

Where:

  options               Do This
  -h or --help          Display this message

EOS


# Check command line for Problems with Parameters
errors = []

if ARGV.empty?  or  ARGV.include?('-h')  or  ARGV.include?('--help')
  puts usage
  exit
end



unless errors.empty?
  puts
  puts "Correct the following errors and try again:"
  puts
  errors.each do |e|
    puts "\t#{e}"
  end
  puts
  exit(1)
end

######################################################
# Local methods


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

in_path = Pathname.pwd + 'meditations.txt'

body_text = in_path.readlines # .select {|a_line| a_line if a_line.start_with? "LongReading" }

body_text.each do |a_line|
  puts a_line

  pc = Pericope.parse(a_line)
  pc.each do |r|
    puts "*** Found: #{r}"
  end unless pc.empty?

end

