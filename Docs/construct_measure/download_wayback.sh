#!/bin/bash

#This script illustrates how to download large amount of data on Wayback using an AWS instance; 
#It takes the list of links contained in small_1.txt and download them in a dedicated directory;

mkdir us_private
cd /home/ec2-user/us_private
wget -i /home/ec2-user/wayback_list/small_1.txt

#It is possible to execute this script in parallel by using the screen command in Linux. Below is an example:
#To create a new screen session, type screen -S <name_of_your_screen>
#Type Ctrl+A Ctrl+D to detach from the session
#Type screen -r <name_of_your_screen> to reattach
#You can open many screen sessions in parallel, each one downloading the links contained in a text file. Type screen -ls to list the running sessions.
 



