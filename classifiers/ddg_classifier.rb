#!/usr/bin/env ruby
###################################################
###
##  File: ddg_classifier.rb
##  Desc: simple classifier
#

require 'date'
require 'pathname'

require 'awesome_print'

#require 'bayesball'
#ddg_classifier = Bayesball::Classifier.new

require 'stuff-classifier'

data_set_name     = 'sports'
data_dir          = Pathname.new(__FILE__) + '..' + data_set_name
training_db_path  = data_dir + '..' + "#{data_set_name}.db"

previously_trained  = training_db_path.exist?

store = StuffClassifier::FileStorage.new(training_db_path.to_s)

# global setting
StuffClassifier::Base.storage = store

unknown_files = Array.new
training_sets = Array.new

data_dir.children.each {|c| c.directory? ? training_sets << c : unknown_files << c }


if previously_trained

  ddg_classifier = StuffClassifier::Bayes.open(data_set_name) # Bayes or TfIdf

  # to start fresh, deleting the saved training data for this classifier
  # StuffClassifier::Bayes.new(data_set_name, :purge_state => true)

  puts "Using previously trained classification db.  To retrain"
  puts "delete the file: #{training_db_path}"

else

  ddg_classifier = StuffClassifier::Bayes.new(data_set_name) # Bayes or TfIdf


  ####################################################
  ## Train with each subdirectory's contents

  training_sets.each do | ts |

    set_name = ts.basename.to_s

    ts.children.each do |c|
      puts "Training #{set_name} with #{c.basename} ...."
      ddg_classifier.train(set_name, c.read)
    end

  end # of training_sets.each do | ts |

  # after training is done, to persist the data ...
  ddg_classifier.save_state


end # of if previously_trained


#####################################################
## Test each unknown file

unknown_files.each do | uf |
  print "Testing #{uf} ... "
  puts ddg_classifier.classify(uf.read)
  # TODO: move the unknown file into its proper place
end




