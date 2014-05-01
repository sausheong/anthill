get "/:queue" do
  queue = params[:queue]
  message = params.select {|k, v| !%w(splat queue captures).include?(k)}
  respond queue, message
end


post "/:queue" do
  respond params[:queue], params[:splat] 
end


put "/:queue" do
  conn = Bunny.new(vhost: 'anthill', user: 'antman', pass: 'antpass')
  conn.start
  ch = conn.create_channel
  q = ch.queue params[:queue], durable: true
  q.publish params[:splat].to_json, persistent: true
  conn.close
end

def respond(queue_name, message)
  conn = Bunny.new(vhost: 'anthill', user: 'antman', pass: 'antpass')
  conn.start
  ch = conn.create_channel
  reply_q = ch.queue ""
  exchange = ch.default_exchange

  correlation_id = SecureRandom.uuid
  exchange.publish message.to_json, routing_key: queue_name, correlation_id: correlation_id, reply_to: reply_q.name

  response = nil
  reply_q.subscribe block: true do |delivery_info, properties, payload|
    if properties[:correlation_id] == correlation_id
      response = payload.to_s      
      delivery_info.consumer.cancel
    end
  end
  conn.close  
  response  
end
