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
  debug:          false,
  elvis_api_url:  ENV['ELVIS_API_URL']  || 'http://elvis.upperroom.org:8080/services/',
  elvis_user:     ENV['ELVIS_USER']     || 'guest',
  elvis_pass:     ENV['ELVIS_PASS']     || 'guest',
  out_filename:   nil
}

def verbose?
  $options[:verbose]
end

def debug?
  $options[:debug]
end

$DEBUG = debug?

usage = <<EOS

Does something with the Elvis REST API

Usage: #{my_name} [options] parameters

Where:

  options               Do This
    -h or --help        Display this message
    -v or --verbose     Display progress
    -d or --debug       Issue some special output
    -u or --username    Elvis account username
                          default: $ELVIS_USER
    -p or --password    Elvis account username
                          default: $ELVIS_PASS

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

%w[ -u --username ].each do |param|
  $options[:elvis_user] =
    get_next_parameter( ARGV.index(param) ) if ARGV.include?(param)
end

%w[ -p --password ].each do |param|
  $options[:elvis_pass] =
    get_next_parameter( ARGV.index(param) ) if ARGV.include?(param)
end

ARGV.compact!

# ...

abort_if_errors

# pp $options

$elvis = WW::REST::Elvis.new

######################################################
# Local methods

def send_command( command_name, options, e=$elvis )
  o = options.merge( WW::REST::Elvis::Utilities.encode_login(
    $options[:elvis_user],
    $options[:elvis_pass]) )
  e.send(command_name, o)
end


def test_it( command_name, options, e=$elvis )
  if debug?
    puts "="*45
    puts "Command: #{command_name}"
  end
  r = send_command( command_name, options, e)
  if debug?
    puts "Response is of class: #{r.class}  size: #{r.size}"
    pp r
  end
  return r
end




######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

=begin
# browse returns array of hashes for the contents 1 level deep from path
test_it :browse, {  path:               '/URE/ure_20150304_81_1',
                    # fromRoot:           '/URE/ure_20150304_81_1',
                    includeFolders:     true, # default
                    includeAssets:      true, # default
                    includeExtensions:  'all'
                  }

=end

=begin
r = test_it :search, {  q: '"Abraham Lincoln" AND "Martin Luther King"',
                        metadataToReturn: 'assetCreated,assetModified,fileSize,title,created,assetPath,creatorName',
                        appendRequestSecret: 'true'
}

puts r.class
puts r.size
if Hash == r.class
  pp r.keys
  r.keys.select{|k| :hits != k}.each {|k| puts "#{k}: #{r[k]}"}
  puts r[:hits].class
  puts r[:hits].size
  if Array == r[:hits].class
    puts r[:hits].first.class
    puts r[:hits].first.size
    pp r[:hits].first.keys
    r[:hits].first.keys.select{|k| :metadata != k }.each {|k| puts "#{k}: #{r[:hits].first[k]}"}
    puts "\n===== meta-data ====="
    pp r[:hits].first[:metadata].keys
    r[:hits].first[:metadata].keys.select{|k| :textContent != k }.each {|k| puts "#{k}: #{r[:hits].first[:metadata][k]}"}
  end
end

=end


=begin
r = test_it :search, {  q: 'status:rexeived~',
                        metadataToReturn: 'assetCreated,assetModified,fileSize,title,created,assetPath,creatorName',
                        appendRequestSecret: 'true'
}

puts r.class
puts r.size
if Hash == r.class
  pp r.keys
  r.keys.select{|k| :hits != k}.each {|k| puts "#{k}: #{r[k]}"}
  puts r[:hits].class
  puts r[:hits].size
  if Array == r[:hits].class
    puts r[:hits].first.class
    puts r[:hits].first.size
    pp r[:hits].first.keys
    r[:hits].first.keys.select{|k| :metadata != k }.each {|k| puts "#{k}: #{r[:hits].first[k]}"}
    puts "\n===== meta-data ====="
    pp r[:hits].first[:metadata].keys
    r[:hits].first[:metadata].keys.select{|k| :textContent != k }.each {|k| puts "#{k}: #{r[:hits].first[:metadata][k]}"}
  end
end
=end

#################################################################
## Testing the sequence for adding a file from a web form

# r = test_it :create_folder, {path: '/test'}
# {:"/test"=>"created"}           First time response
# {:"/test"=>"already exists"}    Subsiquent times response

puts "="*45
=begin
f = File.new('silly.txt', 'rb')

r = test_it :create, {
  Filedata:   f, # :multipart => true},
  assetPath:  '/test/silly.txt'
}

pp r
=end

puts "="*45


file_contents = <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<meditation>
  <title>This is My Title</title>
  <theme>Bible Story</theme>
  <longreading>John 1:1-22</longreading>
  <quotedscripture>In the beginning was the word.</quotedscripture>
  <citation>John 1:1</citation>
  <bodytext>
    This is a line.  It is a long line.  It represents all the lines in the first paragraph.  This is a line.  It is a long line.  It represents all the lines in the first paragraph.  This is a line.  It is a long line.  It represents all the lines in the first paragraph.  This is a line.  It is a long line.  It represents all the lines in the first paragraph.  This is a line.  It is a long line.  It represents all the lines in the first paragraph.
    This is a second line.  It represents the start of the second paragraph.
    This is the third paragraph.
  </bodytext>
  <prayer>Dear Lord, please let this program work.</prayer>
  <thoughtfortheday>Documentation should always be written first</thoughtfortheday>
  <author>Dewayne VanHoozer</author>
  <location>Nashville, TN</location>
  <prayerfocus>Computer Programmers Dealing with lack of Documentation</prayerfocus>
</meditation>
EOS

filename  = "yyyyMMddHHmmSS_vanhoozer_en.xml"
temp_file = File.open("/tmp/#{filename}", 'w')
temp_file.puts file_contents
temp_file.close


r = test_it :create,
                {
                  Filedata:   File.open("/tmp/#{filename}", 'rb'),
                  assetPath:  '/test/billy.xml',
                  status:'Needs Conversion',
                  PrayerFocus:'Medical people like doctors and nurses'
                }



pp r




__END__



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


