##########################################################
###
##  File: meditation.rb
##  Desc: Meditation
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

module UR

  class DDG

    attr_accessor :meditations

    class Meditation
      attr_accessor :meditation_date
      attr_accessor :title
      attr_accessor :quoted_scripture
      attr_accessor :citation
      attr_accessor :body_text
      attr_accessor :author
      attr_accessor :tftd
      attr_accessor :prayer
      attr_accessor :prayer_focus
      attr_accessor :categories

    end # Meditation

  end # class DDG

end # module UR
