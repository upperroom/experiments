class Reference
  attr_reader :book, :from_chapter, :to_chapter, :from_verse, :to_verse, :input

  def initialize(input)
    @input = input
    parse
  end

  def valid?
    @valid ||= false
  end

  def parse
    # @input.downcase.gsub(/\s/,'').match /(\d)?([a-zéèïëô]+)\s*(\d+)([.,:](\d+)-?((\d+)[.,:])?(\d+)?)?/
    m = @input.downcase.gsub('.','').match /\s*(\d)?\s+([a-zéèïëô]+)\s+(\d+)([.,:](\d+)-?((\d+)[.,:])?(\d+)?)?/

ap m

    @book = $1.nil? ? $2 : $1+$2
    @from_chapter = $3.to_i == 0 ? nil : $3.to_i
    @to_chapter = $7.to_i == 0 ? nil : $7.to_i

    if $5.to_i > 0
      @from_verse = $5.to_i
      @to_verse = $8.to_i > 0 ? $8.to_i : nil
    else
      @from_verse = @to_verse = nil
    end

    validate!
  end # def parse

  def validate!
    @valid = true
    @valid = false if @book.nil? or @book.empty?
    @valid = false if @from_chapter.nil?

    if @to_chapter.nil?
      unless @from_verse.nil? or @to_verse.nil?
        @valid &&= (@from_verse < @to_verse)
      end
    end

    @valid
  end # def validate!

  def to_s
    s = @book
    s += " #{from_chapter}"   if @from_chapter
    s += ":"                  if @from_chapter and @from_verse
    s += "#{ @from_verse }"   if @from_verse
    s += "-"                  if @to_chapter or @to_verse
    s += "#{@to_chapter}"     if @to_chapter
    s += ":"                  if @to_chapter and @to_verse
    s += "#{@to_verse}"       if @to_verse
    return s
  end

end # end of class Reference

puts Time.now
