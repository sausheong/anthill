# Anthill

## Introduction

Anthill is a simple workload distribution organizer. It allows you, the developer, to create worker nodes to distribute processing workload through an AMQ queue.

## How does it work?

Once you start up Anthill, go to _Programs_. 

![Programs view](/readme_images/programs.png "Programs view")

Click on _Add new program_ to create a new program.

![Add program view](/readme_images/add_program.png "Programs view")

Enter the name of the program, and then the program code you want to run in each worker. Click on _Create Program_ to create the program.

Now that you have the program, click on _Workers_ and then click on _Add new worker_ to create a new worker.

![Add worker view](/readme_images/add_worker.png "Add worker view") 

Enter the name of the channel you want to receive messages from and select the program that you created earlier, then click on *Start_Worker*. 

This will create a worker instance from your program.

That's it! You've just created a worker node that will receive messages from the named channel. You can clone multiple copies of the same worker node if you need more processing capacity, or stop them as you like.

## Client

Clients publish messages on the queue for Anthill workers to process. You can use a number of languages and platforms including Ruby, Python, Java and C#. As long as you can write a client to send a message to a RabbitMQ server, you can send messages to Anthill for processing.

Here's an example of a simple client in Ruby, using the Bunny gem.

```ruby
require 'bunny'
require 'json'

message = {from: "Alex Bell", to: "Tom Watson", message: "Mr. Watson, come here, I want to see you."}

conn = Bunny.new
conn.start
ch = conn.create_channel
q = ch.queue "Message", durable: true
q.publish message.to_json, persistent: true
puts "Sent #{message.to_json}"
conn.close
```


## Installing Anthill

### Dependencies

Anthill is dependent on the following software:

* RabbitMQ - you need to install this before Anthill can run
* Postgres - this allows you to persist your programs in the database (if you want something smaller, you can switch to another relational database with some minor modification of the code)


## Workers

Workers are started in independent threads. Anthill uses JRuby by default, meaning these are OS threads. You can also run in MRI 1.9 and above, though it will mean that the workers will run in green threads instead.

Workers run in parallel and fetches 1 message at a time from the queue for processing. With more workers you can process more messages, increasing throughput of your processing. 

Workers can run in two modes -- it can run in a _process-and-forget mode_ by taking the messages and processing them, or it can run in an _RPC mode_ by taking messages and processing them, then returning a response by publishing the response to a reply queue.

Whether a worker runs as in either mode depends on the calling client. By default it will run in _process-and-forget_ mode. If the client passes a *reply_to* and a *correlation_id* the worker will run in *RPC mode*.

## Programs

Programs are small snippets of Ruby script that you run to process messages that have been published on a queue. Programs are not meant to be full-fledged Ruby programs, so you should not write large complicated pieces of software.

As with any Ruby scripts, the last line of your program will be returned as response. If you have added a *reply_to* and a *correlation_id* to the message in the send queue, the response message will be published on a reply queue with the same name as *reply_to*.

You can find more samples of client code in the _samples_ directory.




## Use cases


