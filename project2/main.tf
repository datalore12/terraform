provider "aws" {
  region     = "us-east-1"
  access_key = ""
  secret_key = ""
}



# 1. Create vpc
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}


# 2. create Internet Gateway
resource "aws_internet_gateway" "MyIG" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "MyIG"
  }
}

# 3. Create Custom Route Table

resource "aws_route_table" "default-route" {
  vpc_id = aws_vpc.main.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.MyIG.id
    }

  tags = {
    Name = "Default-Route"
  }
}

# 4. Create a Subnet

resource "aws_subnet" "prod" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Prod-Network"
  }
}


# 5. Associate Subnet with Route Table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prod.id
  route_table_id = aws_route_table.default-route.id
}

# 6. Create Security Group to allow port 22, 80, 443
resource "aws_security_group" "WebDMZ" {
  name        = "WebDMZ"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
      description      = "HTTPS"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  ingress {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  ingress {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }


  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  tags = {
    Name = "WebDMZ"
  }
}


# 7. Create a network interface with an ip in the subnet that was create in step 4

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.prod.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.WebDMZ.id]

}


# 8. Assing an elastic IP to the network interface create in step 7

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.MyIG]
}

# 9. Create Ubuntu server and install/enable apache2

resource "aws_instance" "web-server" {
  ami           = "ami-033b95fb8079dc481"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "tf2"

  network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.web-server-nic.id
    
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF
  tags = {
    Name = "WebServer"
  }
}

