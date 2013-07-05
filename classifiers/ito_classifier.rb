#!/usr/bin/env ruby
###################################################
###
##  File: ito_classifier.rb
##  Desc: simple classifier
#

require 'date'
require 'pathname'

require 'awesome_print'
months = %w{ jan. feb. mar. apr. may jun. jul. aug. sep. oct. nov. dec. }

ito_path  = Pathname.new(__FILE__) + '..' + '2014_ito.txt'

ito_base  = ito_path.read.split("\n")

year = ito_base.first

ito_base.shift


ito_base.map! { |a_line|
  {
    a_line.split(':').first =>
    a_line.downcase.split(':').last.split(',').map { |a| a.split(';') }.flatten.map {|b| b.strip}
  }
}

mm = 0

out_hash = Hash.new

ito_base.each do | h |
  category = h.keys.first
  h.values[0].each do |v|
    mm_dd = v.split
    if 2 == mm_dd.length
      mm = ("00" + (months.index(mm_dd.first)+1).to_s)[-2,2]
    end
    dd = ("00"+mm_dd.last.to_s)[-2,2]
    key = year + mm + dd
    out_hash.include?(key) ? out_hash[key] << category : out_hash[key] = [category]
  end
end

out_hash.sort.each do | entry |
  file        = entry.first
  categpries  = entry.last.join(', ')
  puts "#{file} Category: #{categpries}"
end




