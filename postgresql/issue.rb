=begin

CREATE TABLE issues (
    id                      integer NOT NULL,
    site_id                 integer NOT NULL,
    date                    date,
    cover_art_title         character varying(255),
    cover_art_artist        character varying(255),
    cover_art_artist_about  character varying(255),
    cover_art_interpreter   character varying(255),
    cover_art_body          text,
    from_the_editor_title   character varying(255),
    from_the_editor_body    text,
    prayer_workshop_title   character varying(255),
    prayer_workshop         text,
    "position"              integer,
    created_at              timestamp without time zone,
    updated_at              timestamp without time zone,
    title                   character varying(255),
    cover_art_credit        text,
    from_the_editor_signature_block text,
    from_the_editor_credit  text,
    excerpt_title           character varying(255),
    excerpt_body            text,
    excerpt_author          character varying(255),
    excerpt_credit          text,
    prayer_workshop_credit  text,
    cover_image_file_name   character varying(255),
    cover_image_content_type  character varying(255),
    cover_image_file_size     integer,
    cover_image_updated_at    timestamp without time zone,
    language_code             character varying(255)
);

ActiveRecord::Schema.define(:version => 20131030165003) do

  create_table "issues", :force => true do |t|
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


end

=end

class Issue < ActiveRecord::Base

  validates_presence_of :date
  validate :validate_date_uniqueness_for_a_language


  belongs_to :site

  attr_accessor :delete_cover_image
  before_validation { cover_image.clear if delete_cover_image == '1' }

  has_attached_file :cover_image,
                    :styles => { :thumbnail => '75x112',
                                 :sidebar => '125x188',
                                 :slideshow => '248x370',
                                 :main => '225x338' },
                    :storage => PAPERCLIP_CONFIG[:storage],
                    :bucket => PAPERCLIP_CONFIG[:bucket],
                    :s3_host_alias => PAPERCLIP_CONFIG[:bucket],
                    :s3_credentials => {
                      :access_key_id => AWS_S3[:access_key_id],
                      :secret_access_key => AWS_S3[:secret_access_key]
                    },
                    :path => PAPERCLIP_CONFIG[:path_prefix] + ':image_path_prefix/issue_covers/:style/:id.png',
                    :command_path => PAPERCLIP_CONFIG[:command_path]
#                    :url => ':s3_alias_url',

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

end
