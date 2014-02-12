#!/usr/bin/env ruby
###########################
#read_mail_from_exchange.rb

require 'awesome_print'
require 'pp'

def show(label, thing = :xyzzy, show_methods=false)
  puts "# TDV #{caller}"
  puts "#"*25
  puts "# #{label}  class: #{thing.class}  #{thing.respond_to?(:size) ? 'Size: '+thing.size.to_s : ''}"
  puts
  pp(thing) unless :xyzzy == thing
  pp(thing.methods.sort) if show_methods
  puts
end


require 'viewpoint'

include Viewpoint::EWS

endpoint  = 'https://mail.gbod.org/EWS/Exchange.asmx'
user      = 'jdoe'
pass      = 'password'

cli = Viewpoint::EWSClient.new(endpoint, user, pass)

#show 'cli', cli, true








#
##
###
# Listing Folders
###

# Find all folders under :msgfolderroot
# folders = cli.folders

# show 'folders', folders

# Find all folders under Inbox
# inbox_folders = cli.folders # root: :inbox


# show 'inbox_folders', inbox_folders



inbox = cli.get_folder_by_name 'Inbox'


# show 'inbox', inbox, true

show 'inbox.items.size', inbox.items.size

a_message = inbox.items.first

show 'a_message', a_message, true

__END__


show 'a_message.is_read?',          a_message.is_read?
show 'a_message.read?',             a_message.read?
show 'a_message.has_attachments?',  a_message.has_attachments?
show 'a_message.importance',        a_message.importance

show 'a_message.date_time_sent',    a_message.date_time_sent

show 'a_message.from',              a_message.from
show 'a_message.sender',            a_message.sender
show 'a_message.to_recipients',     a_message.to_recipients

show 'a_message.subject',           a_message.subject

show 'a_message.body_type',         a_message.body_type
show 'a_message.body',              a_message.body

puts "="*45
puts a_message.body
puts "="*45

# show 'mark_read!',    mark_read!


# Find all folders under :root and do a Deep search
#all_folders = cli.folders root: :root, traversal: :deep

#show 'all_folders.first', all_folders.first




###
# Finding single folders
###

=begin
# If you know the EWS id
cli.get_folder <folder_id>
# ... or if it's a standard folder pass its symbol
cli.get_folder :index
# or by name
cli.get_folder_by_name 'test'
# by name as a subfolder under "Inbox"
cli.get_folder_by_name 'test', parent: :inbox

=end

###
# Creating/Deleting a folder
###

=begin
# make a folder under :msgfolderroot
cli.make_folder 'myfolder'

# make a folder under Inbox
my_folder = cli.make_folder 'My Stuff', parent: :inbox

# make a new Tasks folder
tasks = cli.make_folder 'New Tasks', type: :tasks

# delete a folder
my_folder.delete!

=end

###
# Item Accessors
# Finding items
###

# items = inbox.items

# show 'items', items





# for today

show 'inbox.todays_items', inbox.todays_items

# since a specific date
sd = Date.iso8601 '2013-01-01'
show 'sd', sd

# inbox.items_since(sd)

show 'inbox.items_since(sd)', inbox.items_since(sd)

# between 2 dates
sd = Date.iso8601 '2013-01-01'
ed = Date.iso8601 '2013-08-01'

show 'sd',sd
show 'ed',ed


# inbox.items_between(sd, ed)

show 'inbox.items_between(sd, ed)', inbox.items_between(sd, ed)

###
# Free/Busy Calendar Accessors
###

# Find when a user is busy

require 'time'

start_time = DateTime.parse("2013-02-19").iso8601
end_time = DateTime.parse("2013-08-20").iso8601

=begin
user_free_busy = cli.get_user_availability(['dvanhoozer@gbod.org'],
  start_time: start_time,
  end_time:   end_time,
  requested_view: :free_busy)

show 'user_free_busy', user_free_busy


busy_times = user_free_busy.calendar_event_array

show 'busy_times',busy_times


# Parse events from the calendar event array for start/end times and type
busy_times.each { | event |
  puts cli.event_busy_type(event)
  puts cli.event_start_time(event)
  puts cli.event_end_time(event)
}

# Find the user's working hours
# user_free_busy.working_hours

show 'user_free_busy.working_hours', user_free_busy.working_hours
=end

###
# Mailbox Accessors
# Message Accessors
###

show 'Sending Messages'

cli.send_message subject: "Test", body: "Test", to_recipients: ['bigdawg@madbombersoftware.com']

# or
cli.send_message do |m|
  m.subject = "Test2"
  m.body    = "Test2"
  m.to_recipients << 'bigdawg@madbombersoftware.com'
  m.to_recipients << 'dvanhoozer@gmail.com'
end

# set :draft => true or use cli.draft_message to only create a draft and not send.









