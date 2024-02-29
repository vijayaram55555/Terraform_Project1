resource "aws_vpc" "project1vpc" {
    cidr_block = var.cidr

  
}

resource "aws_subnet" "public1" {
    vpc_id = aws_vpc.project1vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
  
}

resource "aws_subnet" "public2" {
    vpc_id = aws_vpc.project1vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
  
}

resource "aws_internet_gateway" "ig" {
    vpc_id = aws_vpc.project1vpc.id

  
}

resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.project1vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.ig.id
    }
  
}

resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.public1.id
    route_table_id = aws_route_table.rt.id
  
}

resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.public2.id
    route_table_id = aws_route_table.rt.id
  
}


resource "aws_security_group" "project1sg" {
  name        = "web-sg"
  vpc_id = aws_vpc.project1vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }





}



resource "aws_s3_bucket" "project1s3" {
    bucket = "project1-28feb2024-vijayaram"
  
}


resource "aws_instance" "webserver1" {
    ami = "ami-07761f3ae34c4478d"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.project1sg.id ]
    subnet_id = aws_subnet.public1.id
    #user_data = base64encode("file(user_data.sh"))
    user_data = base64encode("${file("./userdata.sh")}")


}

resource "aws_instance" "webserver2" {
    ami = "ami-07761f3ae34c4478d"       
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.project1sg.id ]
    subnet_id = aws_subnet.public2.id
    #user_data = base64encode(file(user_data2.sh))
    user_data = base64encode("${file("./userdata2.sh")}")

}

#load balancer

resource "aws_lb" "mylb" {

    name               = "webloadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.project1sg.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

}

resource "aws_lb_target_group" "tg" {

  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.project1vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
  
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.mylb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

output "loadbalancerdns" {
  value = aws_lb.mylb.dns_name
}
