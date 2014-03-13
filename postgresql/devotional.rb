=begin

  CREATE TABLE devotionals (
    id              integer NOT NULL,
    title           character varying(255),
    date            date,
    verse_text      text,
    read_passage    character varying(255),
    verse_source    character varying(255),
    content         text,
    thought         text,
    prayer          text,
    prayer_focus    text,
    created_at      timestamp without time zone,
    updated_at      timestamp without time zone,
    author          character varying(255),
    language_code   character varying(255),
    special         text
);

ActiveRecord::Schema.define(:version => 20131030165003) do

  create_table "devotionals", :force => true do |t|
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

end

=end

include ActionView::Helpers::SanitizeHelper

class Devotional < ActiveRecord::Base
  validates_presence_of :title, :date, :verse_text, :read_passage, :content
  validate :validate_date_uniqueness_for_a_language

  searchable do
    text :title, :default_boost => 2
    text :verse_text
    text :verse_source
    text :read_passage
    text :content
    text :thought
    text :prayer
    text :prayer_focus
    text :author
    date :date
    string :language_code
  end



  has_many :comments,
           :class_name => 'DevotionalComment',
           :foreign_key => 'commentable_id',
           :order => 'created_at ASC',
           :dependent => :destroy,
           :before_add => :prepare_comment_for_adding

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

end
