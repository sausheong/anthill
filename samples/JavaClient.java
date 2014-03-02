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