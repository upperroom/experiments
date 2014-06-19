#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: elvis_one.rb
##  Desc: Does something with the Elvis REST API
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'debug_me'

require 'pathname'

require_relative 'ww-rest-elvis'

me        = Pathname.new(__FILE__).realpath
my_dir    = me.parent
my_name   = me.basename.to_s

$options = {
  verbose:        true,
  debug:          true,
  out_filename:   nil
}

def verbose?
  $options[:verbose]
end

def debug?
  $options[:debug]
end



usage = <<EOS

Does something with the Elvis REST API

Usage: #{my_name} [options] parameters

Where:

  options               Do This
    -h or --help        Display this message
    -v or --verbose     Display progress
    -d or --debug       Issue some special output

  parameters            The parameters required by
                        the program

NOTE:

  Something_imporatant

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

# ...

abort_if_errors

$elvis = WW::REST::Elvis.new

######################################################
# Local methods

def test_it( command_name, options, e=$elvis )
  puts "="*45
  puts "Command: #{command_name}"
  o = options.merge( WW::REST::Elvis::Utilities.encode_login('upperroom','please') )
  r = e.send(command_name, o)
  puts "Response:"
  pp r
end

######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end


test_it :browse, { path: '/Users/upperroom'}
test_it :browse, { path: '/Users/upperroom/Auto organized'}
test_it :browse, { path: '/Users/upperroom/Auto organized/2014'}
test_it :browse, { path: '/Users/upperroom/Auto organized/2014/2014-06-19'}

test_it :search, {q: 'prayer'}

# test_it :create_folder, {path: 'test'}  # access denied
# test_it :create_folder, {path: '/test'} # access denied
test_it :create_folder, { path: '/Users/upperroom/test' }

test_it :profile, {}

f = File.new('silly.txt', 'rb')

# test_it :create, {  # RestClient does not like my parameters on post actions
#   Filedata:     f,
#   folderPath:   '/Users/upperroom/test',
#   name:         'silly.txt'
# }

test_it :move, {
  source: '/Users/upperroom/test',
  target: '/Users/upperroom/old_test'
}

test_it :browse, { path: '/Users/upperroom'}

test_it :remove, { folderPath: '/Users/upperroom/test' }

test_it :browse, { path: '/Users/upperroom'}

test_it :rename, {
  source: '/Users/upperroom/old_test',
  target: '/Users/upperroom/test'
}

test_it :browse, { path: '/Users/upperroom'}

test_it :copy, {
  source: '/Users/upperroom/test',
  target: '/Users/upperroom/copy_of_test'
}

test_it :browse, { path: '/Users/upperroom'}

test_it :remove_folder, { folderPath: '/Users/upperroom/test' }
test_it :remove_folder, { folderPath: '/Users/upperroom/copy_of_test' }


