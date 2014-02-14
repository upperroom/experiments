#!/usr/bin/env ruby
##########################################################
###
##  File: google.rb
##  Desc: Use Google to search for stuff
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'awesome_print'
require 'pp'
require 'pathname'

require 'capybara'
require 'capybara/poltergeist'

terms = ARGV.join(" ")

if terms == ""
  puts "Please specify a search term..."
  puts "   google.rb search_terms"
  exit(-1)
end

puts "Searching for \"#{terms}\"..."


session = Capybara::Session.new(:poltergeist)
session.driver.headers = { "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.107 Safari/537.36" }

#session = Capybara::Session.new(:selenium)

session.visit "http://google.com"

session.fill_in "q", with: terms
if session.has_button?("gbqfb")
  session.click_button "gbqfb"
else
  session.click_button "Google Search"
end

# NOTE: Only includes stuff from the first page

if session.has_css?("#res")
  links = session.all("#res h3 a")
  links.each do |link|
    puts link.text
    puts link[:href]
    puts ""
  end
else
  puts "No results found"
  puts session.text
end

