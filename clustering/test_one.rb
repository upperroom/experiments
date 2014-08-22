#!/usr/bin/env ruby -wKU

require 'debug_me'
require 'pathname'
require 'date'
require 'active_support/core_ext/string/inflections'

me        = Pathname.new(__FILE__).realpath
my_dir    = me.parent
my_name   = me.basename.to_s

data_dir    = my_dir.parent + 'data'
pf_pathname = data_dir + 'prayer_focus.txt'

PrayerFocus = Struct.new(:filename, :meditation_date, :prayer_focus)

results = []

print "Reading data file "

line_count = 0
pf_pathname.each_line do |a_line|
  ;line_count += 1
  print '.' if 0 == line_count % 500
  pff = PrayerFocus.new
  pff_array = a_line.split(':')
  pff.filename          = pff_array.first
  temp                  = pff.filename.split('/').last.split('_').first
  pff.meditation_date   = Date.new(temp[0,4].to_i, temp[4,2].to_i, temp[6,2].to_i)
  pff.prayer_focus      = pff_array.last.chomp.strip.squeeze(' ')
  pff.prayer_focus      = pff.prayer_focus.split('(').first.strip  if pff.prayer_focus.end_with?(')')
  pff.prayer_focus.gsub!("'",'')                  if pff.prayer_focus.include?("'")
  pff.prayer_focus = pff.prayer_focus.titlecase
  results << pff
end

puts " done."

count   = results.size

debug_me(){[ :count]}




require 'bundler/setup'

puts "#"*55
puts "string_clusterer"
puts

require 'string_clusterer/binning/fingerprint_keyer'

keyer     = StringClusterer::Binning::FingerprintKeyer.new
clusters  = %w{Román Ramon Ramón Sáenz Saénz}.group_by { |n| keyer.key(n) }

# clusters  = results.collect{|r| r.prayer_focus}.group_by { |n| keyer.key(n) }

pp clusters

puts "worthless for prayer focus et.al."



puts "#"*55
puts "scluster"
puts

require 'scluster'

=begin
points = [
  {:val => "foobar1"},
  {:val => "foobar2"},
  {:val => "barfoo3"},
  {:val => "barfoo42"},
  {:val => "other"}
]
=end

points = results.collect{|r| { val: r.prayer_focus}  }

max_distance  = 0.5
clusterer     = SCluster::Clusterer.new(points, max_distance)

clusterer.cluster

pp clusterer.to_a



__END__

puts "#"*55
puts "string_clusterer"
puts





puts "#"*55
puts "string_clusterer"
puts





puts "#"*55
puts "string_clusterer"
puts

require 'clusterer'



puts "#"*55
puts "string_clusterer"
puts





puts "#"*55
puts "string_clusterer"
puts





