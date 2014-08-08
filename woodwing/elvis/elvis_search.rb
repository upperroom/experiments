#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: elvis_search.rb
##  Desc: Search Elvis for stuff
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'debug_me'

require 'pathname'
require_relative 'ww-rest-elvis'


me        = Pathname.new(__FILE__).realpath
my_dir    = me.parent
my_name   = me.basename.to_s

$options = {
  verbose:        false,
  debug:          false,
  show_text:      false,
  show_dates:     false,
  elvis_api_url:  ENV['ELVIS_API_URL']  || 'http://elvis.upperroom.org:8080/services/',
  elvis_user:     ENV['ELVIS_USER']     || 'guest',
  elvis_pass:     ENV['ELVIS_PASS']     || 'guest',
  meta_fields:    [],
  query:          ''  # syntax identical to Elvis UI search box
}

def verbose?
  $options[:verbose]
end

def debug?
  $options[:debug]
end

def show_text?
  $options[:show_text]
end

def show_dates?
  $options[:show_dates]
end

$KNOWN_MFIELDS = %w[  assetCreator
                      assetDomain
                      assetFileModifier
                      assetModifier
                      assetPath
                      assetPropertyETag
                      assetType
                      basicDataETag
                      cf_PrayerFocus
                      cf_Theme
                      cf_TFTD
                      cf_LongReading
                      cf_Citation
                      contentETag
                      extension
                      filename
                      fileSize
                      fileType
                      folderPath
                      indexRevision
                      metadataComplete
                      mimeType
                      name
                      previewETag
                      previewState
                      sceArchived
                      sceUsed
                      status
                      textContent
                      versionETag
                      versionNumber ]

usage = <<EOS

Search Elvis for stuff

Usage: #{my_name} [options] 'query'

Where:

  options               Do This
    -h or --help        Display this message
    -v or --verbose     Display progress
    -d or --debug       Sets $DEBUG
    -m or --meta        Display these metadata fields
      field_names+        one of more metadata field
                          names seperated by commas
          --dates       Shows creation and modification
                          dates and users
          --text        Shows text around the search term(s)
                          for the first "hit" in the document

  'query'               The search query constrained by
                        single quotes.

NOTE:

  The single quotes around the search query are required to
  defeat the command line file glob/wildcard facility.

  The following list contains the known (case-SENSITIVE)
  metadata fields:

  #{$KNOWN_MFIELDS.join(', ')}

EOS

# Check command line for Problems with Parameters
$errors   = []
$warnings = []


# Get the next ARGV parameter after param_index
def get_next_parameter(param_index)
  next_parameter = nil
  if param_index+1 >= ARGV.size
    $errors << "#{ARGV[param_index]} specified without parameter"
  else
    next_parameter = ARGV[param_index+1]
    ARGV[param_index+1] = nil
  end
  ARGV[param_index] = nil
  return next_parameter
end # def get_next_parameter(param_index)


# Get $options[:out_filename]
def get_out_filename(param_index)
  filename_str = get_next_parameter(param_index)
  $options[:out_filename] = Pathname.new( filename_str ) unless filename_str.nil?
end # def get_out_filename(param_index)


# Display global warnings and errors arrays and exit if necessary
def abort_if_errors
  unless $warnings.empty?
    STDERR.puts
    STDERR.puts "The following warnings were generated:"
    STDERR.puts
    $warnings.each do |w|
      STDERR.puts "\tWarning: #{w}"
    end
    STDERR.puts
  end
  unless $errors.empty?
    STDERR.puts
    STDERR.puts "Correct the following errors and try again:"
    STDERR.puts
    $errors.each do |e|
      STDERR.puts "\t#{e}"
    end
    STDERR.puts
    exit(-1)
  end
end # def abort_if_errors


# Display the usage info
if  ARGV.empty?               ||
    ARGV.include?('-h')       ||
    ARGV.include?('--help')
  puts usage
  exit
end

%w[ -v --verbose ].each do |param|
  if ARGV.include? param
    $options[:verbose]        = true
    ARGV[ ARGV.index(param) ] = nil
  end
end

%w[ -d --debug ].each do |param|
  if ARGV.include? param
    $options[:debug]          = true
    $DEBUG                    = true
    ARGV[ ARGV.index(param) ] = nil
  end
end

%w[ -m --meta ].each do |param|
  if ARGV.include? param
    $options[:meta_fields] = get_next_parameter(ARGV.index(param))
  end
end

%w[ --dates ].each do |param|
  if ARGV.include? param
    $options[:show_dates]     = true
    ARGV[ ARGV.index(param) ] = nil
  end
end

%w[ --text ].each do |param|
  if ARGV.include? param
    $options[:show_text]      = true
    ARGV[ ARGV.index(param) ] = nil
  end
end


ARGV.compact!

if ARGV.empty?
  $errors << "No search query was specified."
end

$options[:query] = ARGV.shift

unless ARGV.empty?
  $errors << "The search query is malformed - may not be enclosed in quotes."
end

abort_if_errors

max_mfield_size = 0

unless $options[:meta_fields].empty?
  $options[:meta_fields] = $options[:meta_fields].split(',')
  $options[:meta_fields].each do |mf|
    max_mfield_size = mf.size if mf.size > max_mfield_size
  end
  max_mfield_size += 2
end



######################################################
# Local methods

def send_command( command_name, options, e=$elvis )
  o = options.merge( WW::REST::Elvis::Utilities.encode_login(
    $options[:elvis_user],
    $options[:elvis_pass]) )
  e.send(command_name, o)
end


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

$elvis = WW::REST::Elvis.new

if debug?
  puts
  pp $options
  puts
  pp $elvis
  puts
end

response = send_command :search, {
  q:                    $options[:query],
  metadataToReturn:     'all',
  appendRequestSecret: 'true'
}

if debug?
  puts "======= Full Response ======="
  pp response
end

puts

unless response.include?(:totalHits)
  puts "ERROR: response does not include :totalHits"
  exit
end

puts
puts "Total Hits:   #{response[:totalHits]}"
puts "First Result: #{response[:firstResult]}"
puts "Max. Results: #{response[:maxResultHits]}"
puts

if response[:totalHits] > 0
  result_number = 0
  response[:hits].each do |hit|
    metadata = hit[:metadata]
    puts
    puts "="*45
    puts "== Result # #{result_number+=1}   ID: #{hit[:id]}"
    puts
    puts "originalUrl:  #{hit[:originalUrl]}"
    puts "Asset Path:   #{metadata[:assetPath]}"
    puts "Status:       #{metadata[:status]}"

    puts
    $options[:meta_fields].each do |mf|
      mf_label = "#{mf}:" + ' '*(max_mfield_size-mf.size)
      puts "#{mf_label} #{metadata[mf.to_sym]}"
    end


    if show_dates?
      puts
      puts "Created on:   #{metadata[:assetCreated][:formatted]}  by: #{metadata[:assetCreator]}"
      puts "Modified on:  #{metadata[:assetModified][:formatted]}  by: #{metadata[:assetModifier]}  Version Number # #{metadata[:versionNumber]}"
    end

    if show_text?
      puts
      puts "highlightedText:  #{hit[:highlightedText]}"
    end

    puts
  end # end
end
