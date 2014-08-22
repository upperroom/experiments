#!/usr/bin/env ruby

require 'debug_me'
require 'pathname'
require 'date'
require 'active_support/core_ext/string/inflections'

require 'clusterer'

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

class String
  def title_case
    title = self.split
    title.each do |word|
      unless (word.include?("of")) || (word.include?("the")) && (title.first != "the")
        word.capitalize!
      end
    end # End of each
    title.join(" ")
  end # End of def
end

clusters = Clusterer::Clustering.cluster( :hierarchical, # :kmeans, :bisecting_kmeans, :hierarchical
                                          results,
                                          # :no_of_clusters => 100, # default sqrt of results.size
                                          :no_stem    => true,
                                          :tokenizer  => :simple_ngram_tokenizer
                                        ) { |r| r.prayer_focus }


# output for :hierarchical

#debug_me(){[ 'clusters.size', 'clusters.first', 'clusters.last' ]}

first_cluster = clusters.first

debug_me(){[ 'clusters.first', 'first_cluster.centroid' ]}


# pp clusters


__END__
# output for :kmeans, :bisecting_kmeans
File.open("temp.html","w") do |f|
  f.write("<h1>Prayer Focus Clustering Experiment</h1>")
  f.write("<ul>")
  clusters.each do |clus|
    f.write("<li>")
    f.write("<h4>")
    clus.centroid.to_a.sort{|a,b| b[1] <=> a[1]}.slice(0,5).each {|w| f.write("#{w[0]} - #{format '%.2f',w[1]}, ")}
    f.write("</h4>")
    f.write("<ul>")
    clus.documents.each do |doc|
      result = doc.object
      f.write("<li>")
      f.write(result.prayer_focus)
      f.write(' (')
      f.write(result.meditation_date)
      f.write(')')
      f.write("</li>")
    end
    f.write("</ul>")
  end
  f.write("</ul>")
  f.write("</li>")
end
