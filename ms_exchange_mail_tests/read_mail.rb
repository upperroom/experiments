#!/usr/bin/env ruby
###########################
# read_mail.rb

require 'awesome_print'

def show(label, thing = :xyzzy, show_methods=false)
  puts "#"*25
  puts "# #{label}"
  puts
  ap(thing) unless :xyzzy == thing
  ap(thing.methods.sort) if show_methods
end



require 'mail'

  #   Mail.defaults do
  #     delivery_method :smtp, { :address              => "localhost",
  #                              :port                 => 25,
  #                              :domain               => 'localhost.localdomain',
  #                              :user_name            => nil,
  #                              :password             => nil,
  #                              :authentication       => nil,
  #                              :enable_starttls_auto => true  }
  # 
  #     retriever_method :pop3, { :address             => "localhost",
  #                               :port                => 995,
  #                               :user_name           => nil,
  #                               :password            => nil,
  #                               :enable_ssl          => true }
  #   end

Mail.defaults do
  retriever_method :pop3, :address    => "mail.gbod.org",
                          :port       => 995,
                          :user_name  => 'jdoe',
                          :password   => 'password',
                          :enable_ssl => true
end


# You can access incoming email in a number of ways.
#
# The most recent email:

show 'Mail.all', Mail.all    #=> Returns an array of all emails
# Mail.first  #=> Returns the first unread email
# Mail.last   #=> Returns the last unread email

__END__

# The first 10 emails sorted by date in ascending order:

emails = Mail.find(:what => :first, :count => 10, :order => :asc)
emails.length #=> 10


# Or even all emails:

emails = Mail.all
emails.length #=> LOTS!



