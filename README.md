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

Enter the name of the channel you want to receive messages from and select the program that you created earlier, then click on _Start_Worker_. 

This will create a worker instance from your program.

That's it! You've just created a worker node that will receive messages from the named channel. You can clone multiple copies of the same worker node if you need more processing capacity, or stop them as you like.


## Installing Anthill



## Programs

Programs are small snippets of Ruby script that you run to process messages that have been published on a queue. Programs are not meant to be full-fledged Ruby programs, so you should not write large complicated pieces of software.




