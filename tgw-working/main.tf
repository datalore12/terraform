provider "aws" {
  region     = "us-east-1"
  access_key = ""
  secret_key = ""
}

# Create VPCs

resource "aws_vpc" "Egress-VPC" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Egress-VPC"
  }
}

resource "aws_vpc" "App1-VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "App1-VPC"
  }
}

resource "aws_vpc" "App2-VPC" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "App2-VPC"
  }
}


# 2: Create Subnets

resource "aws_subnet" "Egress-Public-AZ1" {
  vpc_id                                      = aws_vpc.Egress-VPC.id
  cidr_block                                  = "192.168.1.0/24"
  availability_zone                           = "us-east-1a"
  map_public_ip_on_launch                     = true
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "Egress-Public-AZ1"
  }
}

resource "aws_subnet" "Egress-Public-AZ2" {
  vpc_id                                      = aws_vpc.Egress-VPC.id
  cidr_block                                  = "192.168.2.0/24"
  availability_zone                           = "us-east-1b"
  map_public_ip_on_launch                     = true
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "Egress-Public-AZ2"
  }
}

resource "aws_subnet" "Egress-Private-AZ1" {
  vpc_id                                      = aws_vpc.Egress-VPC.id
  cidr_block                                  = "192.168.3.0/24"
  availability_zone                           = "us-east-1a"
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "Egress-Private-AZ1"
  }
}

resource "aws_subnet" "Egress-Private-AZ2" {
  vpc_id                                      = aws_vpc.Egress-VPC.id
  cidr_block                                  = "192.168.4.0/24"
  availability_zone                           = "us-east-1b"
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "Egress-Private-AZ2"
  }
}

resource "aws_subnet" "App1-Private-AZ1" {
  vpc_id                                      = aws_vpc.App1-VPC.id
  cidr_block                                  = "10.0.1.0/24"
  availability_zone                           = "us-east-1a"
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "App1-Private-AZ1"
  }
}
resource "aws_subnet" "App1-Private-AZ2" {
  vpc_id                                      = aws_vpc.App1-VPC.id
  cidr_block                                  = "10.0.2.0/24"
  availability_zone                           = "us-east-1b"
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "App1-Private-AZ2"
  }
}

resource "aws_subnet" "App2-Private-AZ1" {
  vpc_id                                      = aws_vpc.App2-VPC.id
  cidr_block                                  = "10.1.1.0/24"
  availability_zone                           = "us-east-1a"
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "App2-Private-AZ1"
  }
}
resource "aws_subnet" "App2-Private-AZ2" {
  vpc_id                                      = aws_vpc.App2-VPC.id
  cidr_block                                  = "10.1.2.0/24"
  availability_zone                           = "us-east-1b"
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "App2-Private-AZ2"
  }
}

# 3: Create Internet Gateway in Egress-VPC


resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.Egress-VPC.id

  tags = {
    Name = "IGW"
  }
}

# 4: Create NAT Gateway

resource "aws_eip" "nat_ip_1" {
  depends_on = [aws_internet_gateway.IGW]
}

resource "aws_eip" "nat_ip_2" {
  depends_on = [aws_internet_gateway.IGW]
}

resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = aws_eip.nat_ip_1.id
  subnet_id     = aws_subnet.Egress-Public-AZ1.id

  tags = {
    Name = "nat_gw_1"
  }
  depends_on = [aws_internet_gateway.IGW]

}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_ip_2.id
  subnet_id     = aws_subnet.Egress-Public-AZ2.id

  tags = {
    Name = "nat_gw_2"
  }
  depends_on = [aws_internet_gateway.IGW]

}

# 5: Create Custom Route Table

resource "aws_route_table" "Egress-Public-RT" {
  vpc_id = aws_vpc.Egress-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = {
    Name = "Default-Route"
  }
}

resource "aws_route_table" "Egress-Private-RT" {
  vpc_id = aws_vpc.Egress-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw_1.id
  }

  tags = {
    Name = "NAT-Route"
  }
}

resource "aws_route_table_association" "Egress-Public-AZ1-RT" {
  subnet_id      = aws_subnet.Egress-Public-AZ1.id
  route_table_id = aws_route_table.Egress-Public-RT.id
}

resource "aws_route_table_association" "Egress-Public-AZ2-RT" {
  subnet_id      = aws_subnet.Egress-Public-AZ2.id
  route_table_id = aws_route_table.Egress-Public-RT.id
}

resource "aws_route_table_association" "Egress-Private-AZ1-RT" {
  subnet_id      = aws_subnet.Egress-Private-AZ1.id
  route_table_id = aws_route_table.Egress-Private-RT.id
}

resource "aws_route_table_association" "Egress-Private-AZ2-RT" {
  subnet_id      = aws_subnet.Egress-Private-AZ2.id
  route_table_id = aws_route_table.Egress-Private-RT.id
}


# Create Transit Gataway

resource "aws_ec2_transit_gateway" "TGW-Internet" {
  description = "TGW-Internet"
  tags = {
    Name = "TGW-Internet"
  }
  default_route_table_propagation = "disable"
  default_route_table_association = "disable"
}



#resource "aws_ec2_transit_gateway_vpc_attachment" "Egress-Attachment" {
  # (resource arguments)
#}




