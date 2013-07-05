#!/usr/bin/env ruby
##########################################
###
##  File: judgee.rb
##  Desc: Simple classifier
##
#

require 'awesome_print'
require "judgee"

# Create an instance of Judgee.
# Judgee assumes that your Redis instance is running on localhost at port 6379.
judgee = Judgee::Classifier.new

# Is your Redis instance running on a host in your network, simply pass your options
#judgee = Judgee::Classifier.new(:host => "10.0.1.1", :port => 6380)

# Judgee also supports Unix sockets
#judgee = Judgee::Classifier.new(:path => "/tmp/redis.sock")


# Now you can train the classifier
judgee.train(:spam, ["bad", "worse", "stupid", "idiotic"])
judgee.train(:ham, ["good", "better", "best", "lovely"])

# After training, classify your text sample
puts judgee.classify(["good", "better", "best", "worse"]) # => :ham


# Want to untrain some words?
judgee.untrain(:spam, ["bad", "worse"])

# Now you can train the classifier
judgee.train_fast(:spam, ["bad", "worse", "stupid", "idiotic"])
judgee.train_fast(:ham, ["good", "better", "best", "lovely"])

# After training, classify your text sample
puts judgee.classify_fast(["good", "better", "best", "worse"]) # => :ham


# Want to untrain some words?
judgee.untrain_fast(:spam, ["bad", "worse"])

