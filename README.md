# Anthill

## Introduction

Anthill is a simple workload distribution organizer. It allows you, the developer, to create worker nodes to distribute processing workload through an AMQ queue. These worker are distributed evenly amongst your cores and can be scaled up and down through a simple user interface. Clients publish messages on a named queue to be picked up by the workers.

While the current version runs both the queue and Anthill in the same server, they can be easily deployed separately, allowing even better scalability.

**IMPORTANT - Anthill is experimental software as of now and cannot be considered production quality**

## How does it work?

Once you start up Anthill, you will see the login page. Remember Anthill requires you to log in using authserv.

![Login view](/readme_images/login.png "Login view")

Once you have logged in go to _Programs_. 

![Programs view](/readme_images/programs.png "Programs view")

Click on _Add new program_ to create a new program.

![Add program view](/readme_images/add_program.png "Programs view")

Enter the name of the program, and then the program code you want to run in each worker. The message itself is a String object, that is `self`. This means you can access the message data using `self`. Click on _Create Program_ to create the program.

Now that you have the program, click on _Workers_ and then click on _Add new worker_ to create a new worker.

![Add worker view](/readme_images/add_worker.png "Add worker view") 

Enter the name of the channel you want to receive messages from and select the program that you created earlier. If you want to pass on variables to the worker here, you can set the name and the value of the variable. The program should be able to use it as an instance variable e.g. if you had a variable named `sendgrid_account_name` then you can acccess it as `@sendgrid_account_name` in your program. Once you're done, click on *Start_Worker*. 

This will create a worker instance from your program.

![Workers view](/readme_images/workers.png "Workers view") 

That's it! You've just created a worker node that will receive messages from the named channel. You can clone multiple copies of the same worker node if you need more processing capacity, or stop them as you like. Note that once you started the worker, changing the program doesn't affect how the worker runs. However you can still change the variables on the worker.


## Client

Clients publish messages on the queue for Anthill workers to process. You can use a number of languages and platforms including Ruby, Python, Java and C#. As long as you can write a client to send a message to a [RabbitMQ](https://www.rabbitmq.com/) server, you can send messages to Anthill for processing.

Here's an example of a simple client in Ruby, using the [Bunny](http://rubybunny.info/) gem.

```ruby
require 'bunny'
require 'json'

message = {from: "Alex Bell", to: "Tom Watson", 
           message: "Mr. Watson, come here, I want to see you."}

conn = Bunny.new
conn.start
ch = conn.create_channel
q = ch.queue "Message", durable: true
q.publish message.to_json, persistent: true
puts "Sent #{message.to_json}"
conn.close
```

This starts a connection with the local RabbitMQ server, creates a channel and a queue named `Message`. A JSON message is then published on the queue. Remember that when you create a worker, you can set the channel name, if you create a worker that will monitor the channel `Message`, that worker will pick up this message and process it.

Here's an example in Java.

```java
import java.io.IOException;
import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.MessageProperties;

public class JavaClient {
  private static final String TASK_QUEUE_NAME = "Message";
  public static void main(String[] argv) 
                      throws java.io.IOException {

    ConnectionFactory factory = new ConnectionFactory();
    factory.setHost("localhost");
    Connection connection = factory.newConnection();
    Channel channel = connection.createChannel();
    channel.queueDeclare(TASK_QUEUE_NAME, true, false, false, null);
    String message = "Hello World";
    channel.basicPublish( "", TASK_QUEUE_NAME, 
            MessageProperties.PERSISTENT_TEXT_PLAIN,
            message.getBytes());
    System.out.println("Sent '" + message + "'");

    channel.close();
    connection.close();
  }      
}
```

Here's another example, with response into a reply queue.

```ruby
require 'bunny'
require 'json'
require 'securerandom'

message = {from: "Alex Bell", to: "Tom Watson", 
          message: "Mr. Watson, come here, I want to see you."}

conn = Bunny.new
conn.start
ch = conn.create_channel
reply_q = ch.queue ""
exchange = ch.default_exchange

correlation_id = SecureRandom.uuid
exchange.publish message.to_json, routing_key: "Reply", 
                 correlation_id: correlation_id, reply_to: reply_q.name

response = nil
reply_q.subscribe block: true do |delivery_info, properties, payload|
  if properties[:correlation_id] == correlation_id
    response = payload.to_s      
    delivery_info.consumer.cancel
  end
end

puts response

conn.close
```

The `reply_to` tells the client which queue to monitor for the response, while the `correlation_id` makes sure it's the correct response to the message it sent earlier. The `routing_key` is the name of the queue, so you should create a worker that monitors a channel with that name.

You can find more samples of client code in the _samples_ directory.

## Workers

Workers are started in independent threads. Anthill uses [JRuby](http://www.jruby.org/) by default, meaning these are OS threads. You can also run in MRI 1.9 and above, though it will mean that the workers will run in green threads instead.

Workers run in parallel and fetches 1 message at a time from the queue for processing. With more workers you can process more messages, increasing throughput of your processing. 

Workers can run in two modes -- it can run in a _process-and-forget mode_ by taking the messages and processing them, or it can run in an _RPC mode_ by taking messages and processing them, then returning a response by publishing the response to a reply queue.

Whether a worker runs as in either mode depends on the calling client. By default it will run in _process-and-forget_ mode. If the client passes a *reply_to* and a *correlation_id* the worker will run in *RPC mode*.

When you start workers you can set variables that are used during its execution. These variables are accessed by the program as instance variables. For example if you set a variable named `sendgrid_account_name` then you can acccess it as `@sendgrid_account_name` in your program. Every worker can run the same program but with completely different variable values.

Workers are transient -- when Anthill is shut down, they will not be persisted and restarted when Anthill is restarted.

## Programs

Programs are small snippets of Ruby script that you run to process messages that have been published on a queue. Programs are not meant to be full-fledged Ruby programs, so you should not write large complicated pieces of software.

As with any Ruby scripts, the last line of your program will be returned as response. If you have added a *reply_to* and a *correlation_id* to the message in the send queue (remember that the message is created by the client), the response message will be published on a reply queue with the same name as *reply_to*.

To access the message in the queue, you can use `self`. `self` is always a String object. For example, if the message is in JSON format (typically this is what you would do), then to access the message you can parse it like this:

    message = JSON.parse self

The program can also access variables that are set on the worker during its execution. To access a variable you can treat it as an instance variable e.g. simply append a `@` in front of the variable name.

## Use cases

Anthill's main use case is in scaling up multiple small tasks quickly. Here are some examples:

### Fire and forget emails

Sending emails is often a necessary part of any application. A common example is firing off an email for account activation after registering for an account. If your web application sends the email directly, it will hog out the response back to the user and provide a bad user experience. Ideally you would pass this off as a job to run in the background while you send the user to another page.

With Anthill you can simply publish a fire-and-forget message to the queue for an Anthill worker to pick up and send the email. If you need to know if the email has been sent successfully you can publish a message with *reply_to* and *correlation_id*. In your program, simply return the status of email sending task.

### Mass processing

Your user uploads an Excel spreadsheet with 1,000 addresses and you need to verify them to make sure they are valid addresses. Fortunately there are API services available for that, but unfortunately you have addresses from multiple countries, and there is no single provider who can process them all. 

Firstly Anthill takes away the task of processing them in real-time, so you can respond to the user after the upload so that he can do other stuff. Instead of sending a big chunk of data to Anthill, you should publish 1,000 messages to Anthill, each with an address. You can write an Anthill program to parse the address and extract the country, then figure out the provider to use and call the provider API accordingly. To expedite the processing you can start up a worker with that program, and clone it 19 times to make up 20 workers processing in parallel. As each worker completes its job, it will publish the result to a reply queue.

Once the processing completes, your Anthill program can detect if the send queue is empty and publish a special message on a notify queue (which you are going to subscribe to). This will trigger you to collect the results from the reply queue.


### Scalable API interface

APIs need to be scalable. Anthill can provide a simple, scalable data source to your APIs, feeding it data. Or it can be the API point itself, since it can accept clients in multiple languages.


## Installing Anthill

### Dependencies

Anthill is dependent on the following software:

* [RabbitMQ](https://www.rabbitmq.com/) - you need to install this before Anthill can run
* [Postgres](http://www.postgresql.org/) - this allows you to persist your programs in the database (if you want something smaller, you can switch to another relational database with some minor modification of the code)
* [authserv] (https://github.com/sausheong/authserv) - this is the authentication service for Anthill. You should clone the repo, set it up (it uses Postgres for persistence too) and run it at port 8108.

### Steps

1. Make sure you have RabbitMQ, Postgres and authserv installed. Postgres and authserv should be started.
2. Make sure you have JRuby installed, or change .ruby-version to reflect the version of Ruby you can want to use
3. Run `bundle install`. This will install the necessary gems
4. Run the setup script `./setup`. This will set up the database for you and run migration.
5. Run `foreman start`. This will start RabbitMQ server and Anthill at the same time
6. Done!

