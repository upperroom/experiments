#!/usr/bin/env ruby
##########################################################
###
##  File: convert_dbentry_to_docx.rb
##  Desc: Convert the database devotional entries into MS Word *.docx files
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#
require 'debug_me'

require 'pathname'

require 'docx'

require 'active_record'

require "yaml"

######################################################
# Initialize Access to Database

# Setup the logger
ActiveRecord::Base.logger = Logger.new(STDERR)
#ActiveRecord::Base.colorize_logging = false

# Connect to Database
ActiveRecord::Base.establish_connection(YAML.load_file("database.yml")['development'])


=begin

ActiveRecord::Base.establish_connection(
  adapter:  "postgresql",
  encoding: "unicode",
  database: "upperroom_test",
  pool:     5,
  username: "dvanhoozer"
)

# Define the simplified table structure
ActiveRecord::Schema.define do

  create_table "devotionals" do |t|
    t.string   "title"
    t.date     "date"
    t.text     "verse_text"
    t.string   "read_passage"
    t.string   "verse_source"
    t.text     "content"
    t.text     "thought"
    t.text     "prayer"
    t.text     "prayer_focus"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "author"
    t.string   "language_code"
    t.text     "special"
  end

  add_index "devotionals", ["date"], :name => "index_devotionals_on_date"

  create_table "issues" do |t|
    t.integer  "site_id",                         :null => false
    t.date     "date"
    t.string   "cover_art_title"
    t.string   "cover_art_artist"
    t.string   "cover_art_artist_about"
    t.string   "cover_art_interpreter"
    t.text     "cover_art_body"
    t.string   "from_the_editor_title"
    t.text     "from_the_editor_body"
    t.string   "prayer_workshop_title"
    t.text     "prayer_workshop"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
    t.text     "cover_art_credit"
    t.text     "from_the_editor_signature_block"
    t.text     "from_the_editor_credit"
    t.string   "excerpt_title"
    t.text     "excerpt_body"
    t.string   "excerpt_author"
    t.text     "excerpt_credit"
    t.text     "prayer_workshop_credit"
    t.string   "cover_image_file_name"
    t.string   "cover_image_content_type"
    t.integer  "cover_image_file_size"
    t.datetime "cover_image_updated_at"
    t.string   "language_code"
  end

  add_index "issues", ["date"], :name => "index_issues_on_date"
  add_index "issues", ["id"], :name => "index_issues_on_id"

end # ActiveRecord::Schema.define do

=end

class Devotional < ActiveRecord::Base

  validates_presence_of :title, :date, :verse_text, :read_passage, :content
  validate :validate_date_uniqueness_for_a_language

  scope :english, -> { where(language_code: 'en') }
  scope :spanish, -> { where(language_code: 'es') }

  def author_name
    return "unknown"  if author.nil?  || author.blank?
    return author     if author.index('(').nil?

    author_parts = author.split('(')

    return "#{author_parts.first.strip}" if 2 == author_parts.size

    # Most likely has a nickname
    s=author.reverse
    x = s.index('(') + 1
    return s[x..-1].reverse.strip

  end # author_name

  def author_last_name
    s = author_name
    return "#{s.split.last}" unless s.include?(',')
    return "#{s.split(',').first.split.last}"
  end

  def author_location
    # FIXNE: does not take into account nicknames within parens
    "#{author.split('(').last.strip[0..-2]}"
  end

  def page_title
    "#{title} - #{I18n.t('site_titles.www')}"
  end

  def teaser
    strip_tags(content)[0, 150]
  end

  def self.current(language_code = I18n.locale)
    Devotional.where(['date<=? AND language_code=?', Date.today, language_code]).order('date DESC').first
  end

  def issue
    issue_date = date.beginning_of_month
    issue_date = issue_date.prev_month if issue_date.month.even?
    Issue.find_by_date(issue_date)
  end

  def feed
    @title = "The Upper Room<sup>&reg;</sup> Daily Devotional"
    @devotionals = Devotional.where('date <=?', Date.today).order('date DESC')
    @updated =  @devotionals.first.date unless @devotionals.empty?

    respond_to do |format|
      format.atom { render :layout => false }
      format.rss { redirect_to feed_path(:format => :atom), :status => :moved_permanently }
    end
  end

  def to_param
    date.to_s
  end

  def nice_date
    # date.strftime("%A, %b. %d, %Y")
    I18n.localize(date, :format => :long)
  end

  def author_nice
    # get rid of stuff in parentheses
    author.gsub(/\([^\)]*\)/, '').strip
  end

  class BookNotFound < RuntimeError
  end

  class PassageNotFound < RuntimeError
  end

  def bible_verses
    passages = {}
    read_passage.split(/; */).each do |single_book_passages|
      passages.merge!(parse_passages_for_a_single_book(single_book_passages))
    end
    passages
  end

  def passage_bounds(passage_string)
    passage_start, passage_end = passage_string.split('-')
    passage = {}
    passage[:start] = verse_parts(passage_start)
    passage[:end] = verse_parts(passage_end) unless passage_end.nil?
    passage
  end


  def verse_parts(passage_string)
    if passage_string.include?(':')
      chapter, verse = passage_string.split(':')
      @chapter = chapter.to_i
    else
      verse = passage_string
    end
    { :chapter => @chapter, :verse => verse.to_i }
  end

  private

  def validate_date_uniqueness_for_a_language
    existing_devotional = Devotional.where(['date=? AND language_code=?', date, language_code]).first
    errors.add(:date, I18n.t('activerecord.errors.messages.date_uniqueness')) if existing_devotional && existing_devotional != self
  end

  def prepare_comment_for_adding(comment)
    comment.site = Site.find_by_subdomain('devotional')
  end

  def parse_passages_for_a_single_book(text)
    passages = {}
    book_name = text.match(/^([^:]+?) +[0-9:]+/)[1]
    book_name.gsub!(/read/i, '')
    book_name.strip!
    book = BibleBook.find_by_name(book_name)
    raise BookNotFound if book.nil?

    @chapter = nil
    current_chapter = 0
    passage_strings = text.match(/ ([: ,0-9-]+)$/)[1]
    passage_strings.scan(/[:0-9-]+/) do |passage_string|

      if passage_string =~ /^[0-9]+$/ && @chapter.nil?
        conditions = ['chapter=?', passage_string.to_i]
        updated_passage_string = passage_string
      else
        passage = passage_bounds(passage_string)
        if passage[:end].nil?
          conditions = ['chapter=? AND verse=?', passage[:start][:chapter], passage[:start][:verse]]
          updated_passage_string = "#{passage[:start][:chapter]}:#{passage[:start][:verse]}"
        elsif passage[:start][:chapter] == passage[:end][:chapter]
          conditions = ['chapter=? AND verse>=? AND verse<=?', passage[:start][:chapter], passage[:start][:verse], passage[:end][:verse]]
          updated_passage_string = "#{passage[:start][:chapter]}:#{passage[:start][:verse]}-#{passage[:end][:verse]}"
        else
          conditions = ['(chapter=? AND verse>=?) OR (chapter=? AND verse<=?)', passage[:start][:chapter], passage[:start][:verse], passage[:end][:chapter], passage[:end][:verse]]
          updated_passage_string = "#{passage[:start][:chapter]}:#{passage[:start][:verse]}-#{passage[:end][:chapter]}:#{passage[:end][:verse]}"
        end
      end

      verses = book.verses.where(conditions)
      raise PassageNotFound if verses.empty?
      passages["#{book_name} #{updated_passage_string}"] = verses
    end

    passages
  end

end # class Devotional < ActiveRecord::Base

class Issue < ActiveRecord::Base

  validates_presence_of :date
  validate :validate_date_uniqueness_for_a_language

  def image_path_prefix
    "#{site.subdomain}/#{language_code}"
  end

  def Issue.valid_years
    (1997..2.years.from_now.year).to_a
  end

  def Issue.valid_months
    [1, 3, 5, 7, 9, 11]
  end

  def Issue.valid_month_options
    case I18n.locale
    when :en
      [['Jan-Feb', 1],
       ['March-April', 3],
       ['May-June', 5],
       ['July-August', 7],
       ['Sept-Oct', 9],
       ['Nov-Dec', 11]]
    when :es
      [['Enero-Feb', 1],
       ['Marzo-Abril', 3],
       ['Mayo-Junio', 5],
       ['Julio-Agosto', 7],
       ['Sept-Oct', 9],
       ['Nov-Dic', 11]]
    end
  end

  validates_inclusion_of :month, :in => Issue.valid_months

  def month_pair
    Issue.valid_month_options.rassoc(month)[0]
  end

  def to_param
    months = month_pair.downcase.split('-')
    m1 = months[0].slice(0,3)
    m2 = months[1].slice(0,3)
    "#{m1}-#{m2}#{year}"
  end

  def title
    "#{month_pair}, #{year}"
  end

  def Issue.current
    Issue.where(['date<=? AND language_code=?', Date.today, I18n.locale]).order('date DESC').first
  end

  def month
    (date || default_date).month
  end

  def month=(int)
    self.date = Date.parse("#{year}-#{int}-01")
  end

  def year
    (date || default_date).year
  end

  def year=(int)
    self.date = Date.parse("#{int}-#{month}-01")
  end

  private

  def default_date
    time = Time.now.next_month.beginning_of_month
    while !Issue.valid_months.include?(time.month)
      time = time.next_month
    end
    time.to_date
  end

  def validate_date_uniqueness_for_a_language
    existing_issue = Issue.where(['date=? AND language_code=?', date, language_code]).first
    errors.add(:date, I18n.t('activerecord.errors.messages.date_uniqueness')) if existing_issue && existing_issue != self
  end

end # class Issue < ActiveRecord::Base

######################################################
# Main

def ddg_filename(m, extname=".txt") # m is a devotional record i.e. meditation
  yyyymmdd    = m.date.to_s.gsub('-','')
  last_name   = m.author_last_name.downcase.
                  gsub("'","")
  last_name   = last_name.split('-').last if last_name.include?('-')
  "#{yyyymmdd}_#{last_name}_#{m.language_code}#{extname}"
end

meditations = Devotional.all

meditations.each do |m|
  #puts "#{m.date}\t#{m.author_last_name}\t[-=>#{m.author}<=-]"

  directory   = 'en' == m.language_code ? 'URE' : 'EAA'
  directory   = 'UNK' unless ['en', 'es'].include?(m.language_code.downcase)

  file_name   = directory + "/" + ddg_filename(m, '.txt')

  puts file_name

  f = File.open( file_name, 'w' )
  f.puts m.date.to_s.gsub('-','')
  f.puts m.title
  f.puts "READ " + m.read_passage
  f.puts m.verse_text
  f.puts m.verse_source
  f.puts m.content
  f.puts "Prayer: " + m.prayer
  f.puts "Thought for the Day\n" + m.thought
  f.puts m.author
  f.puts "Prayer Focus: " + m.prayer_focus
  f.close
end # meditations.each do |m|

puts meditations.size

__END__



album = Album.create(:title => 'Black and Blue',
    :performer => 'The Rolling Stones')
album.tracks.create(:track_number => 1, :title => 'Hot Stuff')
album.tracks.create(:track_number => 2, :title => 'Hand Of Fate')
album.tracks.create(:track_number => 3, :title => 'Cherry Oh Baby ')
album.tracks.create(:track_number => 4, :title => 'Memory Motel ')
album.tracks.create(:track_number => 5, :title => 'Hey Negrita')
album.tracks.create(:track_number => 6, :title => 'Fool To Cry')
album.tracks.create(:track_number => 7, :title => 'Crazy Mama')
album.tracks.create(:track_number => 8,
    :title => 'Melody (Inspiration By Billy Preston)')

album = Album.create(:title => 'Sticky Fingers',
    :performer => 'The Rolling Stones')
album.tracks.create(:track_number => 1, :title => 'Brown Sugar')
album.tracks.create(:track_number => 2, :title => 'Sway')
album.tracks.create(:track_number => 3, :title => 'Wild Horses')
album.tracks.create(:track_number => 4,
    :title => 'Can\'t You Hear Me Knocking')
album.tracks.create(:track_number => 5, :title => 'You Gotta Move')
album.tracks.create(:track_number => 6, :title => 'Bitch')
album.tracks.create(:track_number => 7, :title => 'I Got The Blues')
album.tracks.create(:track_number => 8, :title => 'Sister Morphine')
album.tracks.create(:track_number => 9, :title => 'Dead Flowers')
album.tracks.create(:track_number => 10, :title => 'Moonlight Mile')

puts Album.find(1).tracks.length
puts Album.find(2).tracks.length

puts Album.find_by_title('Sticky Fingers').title
puts Track.find_by_title('Fool To Cry').album_id


######################################################
# Main

