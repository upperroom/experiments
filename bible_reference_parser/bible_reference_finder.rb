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

require 'bible_reference_parser'
include BibleReferenceParser

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

body_text = in_path.readlines.select {|a_line| a_line if a_line.start_with? "LongReading" }

body_text.each do |a_line|
  puts a_line
  a = a_line.split
  # a.each do |a_word|
  #   puts a
  #   r = BibleReferenceParser.parse_books( a_word )
  #   puts "  R: #{r}"
  # end

=begin
  until a.empty? do
    s = a.join(' ')
    puts "  #{s}"
    r = BibleReferenceParser.parse_books( s )
    # ap r
    puts "    Found: #{r}" if r.errors.empty?
    a.shift
  end
=end

  a.each do |a_word|
    rc = BibleReferenceParser.parse_books( a_word )
    puts rc.references.first.name if rc.errors.empty? and !rc.references.empty?
  end




end


