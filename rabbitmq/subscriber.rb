#!/usr/bin/env ruby
#################################################################
###
##  File: subscriber.rb
##  Desc: Subscribe to meditation submissions
##
##  System environment variables used when present:
##
##    RABBITMQ_URL  ??
#


require 'awesome_print'

#####################################################
## initializer junk

require "bunny"
require 'json'
require 'hashie'
require 'date'

OPTIONS = {
  :host      => "localhost",          # defualt: 127.0.0.1
  :port      => 5672,                 # default
  :ssl       => false,                # defualt
  :vhost     => "sandbox",            # defualt: /
  :user      => "xyzzy",              # defualt: guest
  :pass      => "xyzzy",              # defualt: guest
  :heartbeat => :server,              # defualt: will use RabbitMQ setting
  :threaded  => true,                 # default
  :network_recovery_interval => 5.0,  # default is in seconds
  :automatically_recover  => true,    # default
  :frame_max => 131072                # default
}

EXCHANGE_NAME   = "sandbox"
QUEUE_NAME      = "submissions"

connection = Bunny.new(OPTIONS).tap(&:start)
channel    = connection.create_channel

exchange   = channel.topic(EXCHANGE_NAME, :auto_delete => true)

queue      = channel.queue( QUEUE_NAME,
                                durable: true,
                                auto_delete: false,
                                arguments: {"x-max-length" => 1000}
                            ).bind(exchange, :routing_key => "#.new")

# NOTE: routing_key by convention is ClassName.transaction_type
#       This queue is only for transaction type 'new' ergo submissions.
#       Other queues could be defined to handle different kinds of
#       classes or transaction types.  Consider basic CRUD transactions.


at_exit do
  connection.close
end

#####################################################
## local stuff

class Submission < Hashie::Mash
  def publish(transaction_type='new')
    # SMELL: what can we do to get rid of the global?
    $exchange.publish(  self.to_json,
                        routing_key: "#{self.class}.#{transaction_type}",
                        app_id: "Fake Submitter"
                     )
  end
end # class Submission < Hashie::Mash

class Author < Submission
  def save
    # TODO: most likely going to save to a database
    #       or maybe to a file in Elvis

    puts "\nSaving New Author"
    puts "\tID ...... #{author_id}"
    puts "\tName .... #{name}"
    puts "\teMail ... #{email}"

    #sleep(1)

  end
end

class Meditation < Submission
  def save
    # TODO: save as an InCopy file
    # TODO: Upload file to Elvis

    puts "\nSaving New Meditation"
    puts "\tID .......... #{submission_id}"
    puts "\tAuthor ID ... #{author_id}"
    puts "\tTheme ....... #{theme}"
    puts "\tTitle ....... #{title}"

    #sleep(1)

  end
end




class MeditationSubmissionConsumer < Bunny::Consumer

  def cancelled?
    @cancelled
  end

  def handle_cancellation(_)
    @cancelled = true
  end

end # class MeditationSubmissionConsumer < Bunny::Consumer

consumer = MeditationSubmissionConsumer.new(
  channel,
  queue,
  "elvis_eats_submissions", # consumer tag
  false,                    # no_ack
  false                     # exclusive
)

consumer.on_delivery() do |delivery_info, metadata, payload|

    puts
    puts "#"*55
    print 'Routing Key: '
    puts delivery_info.routing_key

    begin

      payload_as_hash = JSON.parse(payload)
      submission      = eval( delivery_info.routing_key + '(payload_as_hash)' )

      # NOTE: Using eval in this way is safe because:
      #       Access to the rabbitMQ broker is white-listed to a select
      #       few IP addresses.  Plus there is a user account required.
      #       Plus the queue ONLY has transaction type of new.  Unknown
      #       classes will result in an exception with the rescue block
      #       invoked without an acknowledgement being given.... and don't
      #       you think that taking into account every possible way that a
      #       programmer can screw up is a little bit of overkill?

      begin
        submission.save
        consumer.channel.acknowledge( delivery_info.delivery_tag, false )
      rescue Exception => e
        puts "ERROR: had a problem saving #{e}"
      end

    rescue Exception => e
      puts "ERROR: Don't know: #{e}"
    end

end # consumer.on_delivery() do |delivery_info, metadata, payload|


queue.subscribe_with( consumer, block: true )

__END__





#loop do
  $queue.subscribe( :consumer_tag => "elvis_eats_meditations",
                    :block => true,
                    :ack => true) do |delivery_info, metadata, payload|

    meditation = JSON.parse(payload, symbolize_names: true)

    puts
    puts "#"*55
    ap delivery_info
    ap metadata
    ap meditation

    $channel.acknowledge( delivery_info.delivery_tag, false )
    $channel.reject(delivery_info.delivery_tag)       # reject and discard a message
    $channel.reject(delivery_info.delivery_tag, true) # reject but re-queque for another attempt later

  end
#end


$connection.close

