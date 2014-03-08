require 'bunny'
require 'json'
require 'securerandom'

# This benchmark client sends consecutive (sequential) requests to the server
puts "Single Ant on the Anthill"

NUM_OF_REQUESTS = 10

t0 = Time.new
NUM_OF_REQUESTS.times do |i|
  conn = Bunny.new(vhost: 'anthill', user: 'antman', pass: 'antpass')
  conn.start
  ch = conn.create_channel
  reply_q = ch.queue ""
  exchange = ch.default_exchange

  correlation_id = SecureRandom.uuid
  exchange.publish i.to_s, routing_key: "Benchmark", correlation_id: correlation_id, reply_to: reply_q.name

  response = nil
  reply_q.subscribe block: true do |delivery_info, properties, payload|
    if properties[:correlation_id] == correlation_id
      response = payload.to_s      
      delivery_info.consumer.cancel
    end
  end

  print response
end
t1 = Time.new

puts
puts "#{t1-t0}s for #{NUM_OF_REQUESTS} requests"