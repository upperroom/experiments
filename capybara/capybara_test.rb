#!/usr/bin/env ruby -W0
##########################################################
###
##  File: capybara_test.rb
##  Desc: Testing web automatiion testing
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'awesome_print'
require 'pp'
require 'pathname'

require 'capybara'

pgm_name = Pathname.new(__FILE__).basename

$options = {
  verbose:    true,
  phantomjs:  true,
  url:        "http://devotional.upperroom.org/devotionals/"
}

def verbose?
  $options[:verbose]
end

def phantomjs?
  $options[:phantomjs]
end

def xyzzy?
  $options[:xyzzy]
end

def xyzzy?
  $options[:xyzzy]
end




usage = <<EOS

Testing web automatiion testing

Usage: #{pgm_name} [options] URL

Where:

  options               Do This
  -h or --help          Display this message
  -p or --phantomjs     Use phantomjs driver

  URL                   Website to access
                        Example: "http://upperroom.org"

EOS

# Check command line for Problems with Parameters

errors = []

if ARGV.empty?  or  ARGV.include?('-h')  or  ARGV.include?('--help')
  puts usage
  exit
end


#unless  1 == ARGV.size
#  puts usage
#  exit
#end


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


# $options[:url] = ARGV.first


######################################################
# Local methods


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end


session = if phantomjs?
  require 'capybara/poltergeist'
  Capybara::Session.new(:poltergeist)
else
  Capybara::Session.new(:selenium)
end

session.visit $options[:url]

if session.has_content?("Devotional Archives")
  puts "All shiny, captain!"
else
  puts ":( no tagline fonud, possibly something's broken"
  ap session
  exit(-1)
end
