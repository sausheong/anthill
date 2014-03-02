require 'bunny'
require 'json'
require 'securerandom'

message = {to: "sauchang@paypal.com", subject: "First phone call", body: "Mr. Watson, come here, I want to see you."}

conn = Bunny.new
conn.start
ch = conn.create_channel
q = ch.queue "Mailer", durable: true
q.publish message.to_json, persistent: true
puts "Sent #{message.to_json}"
conn.close

