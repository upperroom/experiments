require 'viewpoint'
require 'pp'

include Viewpoint::EWS

endpoint  = 'https://mail.gbod.org/EWS/Exchange.asmx'
user      = 'jdoe'
pass      = 'password'

cli       = Viewpoint::EWSClient.new(endpoint, user, pass)
inbox     = cli.get_folder_by_name 'Inbox'

a_message = inbox.items.first

puts "Name:       #{a_message.from.name} #{a_message.from.name.class}"
puts "eMail Addr: #{a_message.from.email_address} #{a_message.from.email_address.class}"
puts "eMail:      #{a_message.from.email} #{a_message.from.email.class}"
puts "Subject:    #{a_message.subject}"
puts

puts a_message.body.class

pp a_message.instance_variables.sort 

puts a_message.ews_item[:body][:text] # same as a_message.body
