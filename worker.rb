require 'bunny'
require './models'

class Worker
  include Celluloid, Loggable
  attr_accessor :program, :channel_name, :variables
  finalizer :finalizer
  
  def initialize(channel, program, variables, prefetch_num=1)
    @conn = Bunny.new(automatically_recover: true, vhost: "anthill", user: 'antman', pass: 'antpass')
    @conn.start
    @channel = @conn.create_channel
    @queue = @channel.queue(channel, durable: true)    
    @exchange = @channel.default_exchange
    @channel.prefetch prefetch_num
    @program, @channel_name = program, channel
    @variables = variables
    info "A new worker has started on #{channel} with #{program.name}"
    async.run
  end
  
  def run
    begin
      @consumer = @queue.subscribe(manual_ack: true, block: false) do |delivery_info, properties, body|
        begin
          # add variables from the worker settings
          variables.each do |name, value|
            body.instance_variable_set "@#{name}", value
          end
           # response is the returned last line of the code
          response = body.instance_eval(@program.code)          
          # if the client specifies a reply_to and a correlation_id, publish the response to the reply_to queue
          if properties.reply_to and properties.correlation_id
            @exchange.publish(response.to_s, routing_key: properties.reply_to, correlation_id: properties.correlation_id)
          end
        rescue Exception => exc
          error exc.message
        end
        @channel.ack(delivery_info.delivery_tag)
      end
      
    rescue Interrupt => int
      error int.message
      @channel.close
      @conn.close
    end
  end
  
  def finalizer
    @consumer.cancel
    @conn.close    
    warn "#{self.name} has died"
  end
end



