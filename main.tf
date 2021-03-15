terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.32.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "ca-central-1"
}


###########################################################################
#
# Use this data source to get the amazon linux 2 ID of a registered AMI for use in other resources.
#
###########################################################################

data "aws_ami" "amz2" {
  most_recent = true
  owners      = ["amazon"] # Canonical

  # more filter conditions are describled in the followed web link
  # https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }
}

###########################################################################
#
# ec2 instance example in the default vpc
#
###########################################################################

resource "aws_instance" "web" {
  #count = 0 #if count = 0, this instance will not be created.

  #required parametres
  ami           = data.aws_ami.amz2.id
  instance_type = "t2.micro"

  #optional parametres
  associate_public_ip_address = true
  key_name = "key-hr123000" #key paire name

  vpc_security_group_ids = data.aws_security_groups.default_sg.ids

  tags = {
    Name = "HelloWorld"
  }

  user_data = <<EOF
            #! /bin/sh
            sudo yum update -y
            sudo amazon-linux-extras install -y nginx1
            sudo systemctl start nginx
            sudo curl -s http://169.254.169.254/latest/meta-data/local-hostname >/tmp/hostname.html
            sudo mv /tmp/hostname.html /usr/share/nginx/html/.
            sudo chmod a+r /usr/share/nginx/html/hostname.html
            EOF

  # root block device configuration
  /*
  root_block_device {
    delete_on_termination = true
    encrypted = false
    volume_size = 8
    volume_type = "gp2"
  }
  */
  
  #you could add additional disks by using ebs_block_device block. same as root_block_device.
  /*
  ebs_block_device {
    device_name = "web_ebs_device1" #required
    delete_on_termination = true
    encrypted = false
    volume_size = 8
    volume_type = "gp2"
  }
  */

}

# get default vpc data
data "aws_vpc" "default_vpc" {
  default = true
}

# get subnetid from default vpc
data "aws_subnet_ids" "default_subnets" {
  vpc_id = data.aws_vpc.default_vpc.id
}

# search a security group in the default vpc and it will be used in ec2 instance's security_groups
data "aws_security_groups" "default_sg" {
  filter {
    name   = "group-name"
    values = ["*SG-STRICT-ACCESS*"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

###########################################################################
#
# add a secondary network interface to the ec2 instance
#
###########################################################################

resource "aws_network_interface" "second_eni" {
  count = 0 # if count = 0, then this resource will not be created.

  subnet_id       = aws_instance.web.subnet_id
  #private_ips     = ["10.0.0.50"]
  security_groups = data.aws_security_groups.default_sg.ids

  attachment {
    instance     = aws_instance.web.id
    device_index = 1
  }

}

