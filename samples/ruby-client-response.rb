require 'bunny'
require 'json'
require 'securerandom'

message = {from: "Alex Bell", to: "Tom Watson", message: "Mr. Watson, come here, I want to see you."}

conn = Bunny.new(vhost: 'anthill', user: 'antman', pass: 'antpass')
conn.start
ch = conn.create_channel
reply_q = ch.queue ""
exchange = ch.default_exchange

correlation_id = SecureRandom.uuid
exchange.publish message.to_json, routing_key: "Reply", correlation_id: correlation_id, reply_to: reply_q.name

response = nil
reply_q.subscribe block: true do |delivery_info, properties, payload|
  if properties[:correlation_id] == correlation_id
    response = payload.to_s      
    delivery_info.consumer.cancel
  end
end

puts response

conn.close
