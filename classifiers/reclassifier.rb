#!/usr/bin/env ruby
##########################################
###
##  File: reclassifier.rb
##  Desc: Simple classifier
##
#
require 'set'

require 'awesome_print'

require "reclassifier"

b = Reclassifier::Bayes.new(  [ :intersting, :uninteresting ]  )

b.train(:intersting,    "here are some good words. I hope you love them")
b.train(:uninteresting,  "here are some bad words, I hate you")

ap b.classify("I hate bad words and you") # returns 'Uninteresting'

=begin

require 'madeleine'

m = SnapshotMadeleine.new("bayes_data") {
    Reclassifier::Bayes.new(  [ :intersting, :uninteresting ] )
}

m.system.train(:intersting,    "here are some good words. I hope you love them")
m.system.train(:uninteresting,  "here are some bad words, I hate you")

m.take_snapshot

ap m.system.classify("I love you") # returns 'Interesting'

=end

