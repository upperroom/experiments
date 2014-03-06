##########################################################
###
##  File: ddg.rb
##  Desc: The Daily Devotional Guide a.k.a URE
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require_relative 'DDG/ai.rb'
require_relative 'DDG/ito.rb'
require_relative 'DDG/pe.rb'
require_relative 'DDG/pw.rb'
require_relative 'DDG/sq.rb'
require_relative 'DDG/wwmp.rb'
require_relative 'DDG/meditation.rb'

module UR

  class DDG
    ABBREVATION = 'URE' # or 'EAA' for Spanish Edition

    attr_accessor :volume
    attr_accessor :issue
    attr_accessor :publication_date


  end # class DDG

end # module UR
