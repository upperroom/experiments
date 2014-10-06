#!/usr/bin/env ruby
####################################################
###
##  File: extract_stuff_from_wcml.rb
##  Desc: wcml is just XML so lets explore the structure
##        of a meditation file.
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'debug_me'
include DebugMe

require 'pathname'

require 'nokogiri'

me        = Pathname.new(__FILE__).realpath
my_dir    = me.parent
my_name   = me.basename.to_s

$options = {
  verbose:        false,
  wcml_files:     [],
  out_filename:   nil
}

def verbose?
  $options[:verbose]
end


usage = <<EOS

Extract story components from a WCML file

Usage: #{my_name} [options] wcml_files+

Where:

  options               Do This
    -h or --help        Display this message
    -v or --verbose     Display progress
    -o or --output      Specifies the path to the output
        out_filename      file.  The extname must be 'ics'
                          Defaults to STDOUT

  wcml_files+           One or more *.wcml files

NOTE:

  Something_imporatant

EOS

# Check command line for Problems with Parameters
$errors   = []
$warnings = []


# Get the next ARGV parameter after param_index
def get_next_parameter(param_index)
  unless Fixnum == param_index.class
    param_index = ARGV.find_index(param_index)
  end
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
    STDERR.print "\nAbort program? (y/N) "
    answer = (gets).chomp.strip.downcase
    $errors << "Aborted by user" if answer.size>0 && 'y' == answer[0]
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

%w[ -o --output ].each do |param|
  get_out_filename( ARGV.index(param) ) if ARGV.include?(param)
  unless $options[:out_filename].nil?
    unless $options[:out_filename].parent.exist?
      $errors << "Directory does not exist: #{$options[:out_filename].parent}"
    end
  end
end

ARGV.compact!

unless ARGV.empty?
  ARGV.each do |a_file|
    fp = Pathname.new(a_file)
    unless fp.exist?
      $warnings << "Does not exist: #{fp}"
      next
    end
    $options[:wcml_files] << fp.realpath
  end
else
  $errors << 'At least one *.wcml file is required'
end


abort_if_errors


######################################################
# Local methods

def story_title(a_story)
  a_story.attributes['StoryTitle'].value.split('/').last
end

def text_of(a_story)
  a_story.xpath('.//Content').to_s.
    gsub('</Content>',"\n").
    gsub('<Content>','').
    gsub('<Content/>','').
    chomp.strip
end


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

pp $options


$options[:wcml_files].each do |fp|
  wcml_doc  = Nokogiri::XML(fp.read)
  # pp wcml_doc
  # contents = wcml_doc.xpath("//Content") # simular to Docx.paragraphs.text
  # pp contents

  stories   = wcml_doc.xpath("//Story")

  story_index = 0
  stories.each do |a_story|
    puts "="*45
    puts story_title(a_story)
    puts text_of(a_story)

  end

end
