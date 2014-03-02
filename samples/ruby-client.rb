require 'bunny'
require 'json'
require 'securerandom'

message = {from: "Alex Bell", to: "Tom Watson", message: "Mr. Watson, come here, I want to see you."}

conn = Bunny.new
conn.start
ch = conn.create_channel
q = ch.queue "Message", durable: true
q.publish message.to_json, persistent: true
puts "Sent #{message.to_json}"
conn.close

