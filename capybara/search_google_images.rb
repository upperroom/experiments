#!/usr/bin/env ruby
##########################################################
###
##  File: search_google_images.rb
##  Desc: Search Google Images for websites using given image
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'awesome_print'
require 'pp'
require 'pathname'

require 'cgi'
require 'timeout'
require 'capybara'

$options = {
  verbose:    true,
  url:        "http://s3.amazonaws.com/images.upperroom.org/chapel/images/display/2.png?1352820965"
}

def verbose?
  $options[:verbose]
end

pgm_name = Pathname.new(__FILE__).basename

usage = <<EOS

Search Google Images for websites using given image

Usage: #{pgm_name} [options] URL

Where:

  options               Do This
  -h or --help          Display this message

  URL                   URL of image

EOS

# Check command line for Problems with Parameters

errors = []

if ARGV.empty?  or  ARGV.include?('-h')  or  ARGV.include?('--help')
  puts usage
  exit
end

unless  1 == ARGV.size
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

$options[:url] = ARGV.first

######################################################
# Local methods


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end


class GoogleImagesSearcher
  include Capybara::DSL

  def initialize
    Capybara.default_driver = :selenium
  end

  def find_sites_with_image(image_url)
    urls = []

    link = "http://images.google.com/searchbyimage?image_url=#{CGI.escape(image_url)}&filter=0"

    visit link

    return urls unless page.has_content?("Pages that include matching images")

    while true
      page.all("h3.r a").each do |a|
        urls << a[:href]
      end
      within "#nav" do
        click_link "Next"
      end
    end

  rescue Capybara::ElementNotFound
    return urls.uniq
  end
end

images = GoogleImagesSearcher.new.find_sites_with_image $options[:url]

puts "Found #{images.count} pages using this image:"
images.each do |img|
  puts img
end
