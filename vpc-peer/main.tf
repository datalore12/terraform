provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAVDLEKJZGAFLLI26S"
  secret_key = "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"
}

#1
resource "aws_vpc" "vpc-1" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc-1"
  }
}

resource "aws_vpc" "vpc-2" {
  cidr_block       = "10.2.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc-2"
  }
}

# 2. create Internet Gateway
resource "aws_internet_gateway" "vpc-1-IG" {
  vpc_id = aws_vpc.vpc-1.id

  tags = {
    Name = "vpc-1-IG"
  }
}





# 4. Create a Subnet

resource "aws_subnet" "vpc-1-public" {
  vpc_id     = aws_vpc.vpc-1.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "vpc-1-public"
  }
}
resource "aws_subnet" "vpc-2-net" {
  vpc_id     = aws_vpc.vpc-2.id
  cidr_block = "10.2.1.0/24"
  availability_zone = "us-east-1a"
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "vpc-2-net"
  }
}




# 6. Create Security Group to allow port 22, 80, 443
resource "aws_security_group" "webdmz-sg-vpc-1" {
  name        = "WebDMZ"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.vpc-1.id

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

resource "aws_security_group" "webdmz-sg-vpc-2" {
  name        = "WebDMZ"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.vpc-2.id

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

  ingress {
      description      = "All ICMP - IPv4"
      protocol         = "icmp"
      from_port        = -1
      to_port          = -1
      cidr_blocks      = ["0.0.0.0/0"]
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
#7 Create EC2 Instance

resource "aws_instance" "vpc-1-web-server" {
  ami           = "ami-0e1d30f2c40c4c701"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "tf2"
  subnet_id = aws_subnet.vpc-1-public.id
  vpc_security_group_ids = [aws_security_group.webdmz-sg-vpc-1.id]

  tags = {
    Name = "WebServer"
  }
}

resource "aws_instance" "db-server" {
  ami           = "ami-0e1d30f2c40c4c701"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "tf2"
  subnet_id = aws_subnet.vpc-2-net.id
  vpc_security_group_ids = [aws_security_group.webdmz-sg-vpc-2.id]

  tags = {
    Name = "DB-Server"
  }
}

# Create VPC Peering

resource "aws_vpc_peering_connection" "vpc-1-2-peer" {
  peer_vpc_id   = aws_vpc.vpc-2.id
  vpc_id        = aws_vpc.vpc-1.id
  auto_accept   = true

  tags = {
      Name = "VPC Peering between VPC-1 and VPC-2"
  }
}


resource "aws_route_table" "vpc-1-def-rte" {
  vpc_id = aws_vpc.vpc-1.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.vpc-1-IG.id
    }
  route {
      cidr_block = "10.2.0.0/16"
      gateway_id = aws_vpc_peering_connection.vpc-1-2-peer.id
  }

  tags = {
    Name = "vpc-1-def-rte"
  }
}

resource "aws_route_table" "vpc-2-peer-rte" {
  vpc_id = aws_vpc.vpc-2.id

  route {
      cidr_block = "10.1.0.0/16"
      gateway_id = aws_vpc_peering_connection.vpc-1-2-peer.id
    }
}

resource "aws_route_table_association" "vpc-1-peer-route" {
  subnet_id      = aws_subnet.vpc-1-public.id
  route_table_id = aws_route_table.vpc-1-def-rte.id
}

resource "aws_route_table_association" "vpc-2-peer-route" {
  subnet_id      = aws_subnet.vpc-2-net.id
  route_table_id = aws_route_table.vpc-2-peer-rte.id
}


# Steps

# 1: Create VPC
# 2: Create Internet GW
# 3: Create Default-Route per VPC