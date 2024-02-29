#!/bin/bash

sudo yum update -y
sudo yum install -y httpd

sudo systemctl start httpd
sudo systemctl enable httpd

echo "Hello from webserver1" > /var/www/html/index.html
