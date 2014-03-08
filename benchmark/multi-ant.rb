require 'bunny'
require 'json'
require 'securerandom'

# This benchmark client sends multiple parallel requests to the server
puts "Many Ants on the Anthill"

NUM_OF_REQUESTS = 2

def ping(i)
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

t0 = Time.now

threads = []
NUM_OF_REQUESTS.times do |i|
  threads << Thread.new { ping(i) }
end

threads.each do |thread|
  thread.join
end

t1 = Time.now
puts
puts "#{t1-t0}s for #{NUM_OF_REQUESTS} requests"
