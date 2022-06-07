# Configure the AWS Provider
provider "aws" {
  region     = "us-east-1"
  access_key = ""
  secret_key = ""
}


resource "aws_vpc" "my-first-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "production"
  } 
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.my-first-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}




# resource "aws_instance" "my-first-server" {
#  ami           = "ami-09e67e426f25ce0d7"
#  instance_type = "t2.micro"

# tags = {
#    Name = "WebServer"
#  }
#}

# terraform init
# terraform plan
# terraform appl