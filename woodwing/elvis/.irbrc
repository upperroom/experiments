require './ww-rest-elvis.rb'

$options = {
  verbose:        true,
  debug:          false,
  elvis_api_url:  ENV['ELVIS_API_URL']  || 'http://elvis.upperroom.org:8080/services/'
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



puts "Elvis library is available."
