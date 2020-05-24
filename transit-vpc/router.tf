variable "router_private_ip" {
  description = "Private IP of router instance in transit VPC t route request back and forward e.g. 10.10.14.90"
}

resource "aws_instance" "router" {
  ami               = "ami-0eb89db7593b5d434" // any AMI you prefer
  instance_type     = "t2.micro" //any type you prefer
  availability_zone = local.main_vpc_az
  key_name          = local.main_vpc_key_name
  subnet_id         = module.transit-vpc.private_subnets.0
  private_ip        = var.router_private_ip


  vpc_security_group_ids = [
    aws_security_group.router_sg.id,
  ]

  user_data = file("router_init.sh")

  associate_public_ip_address = false
  tags = {
    Name    = "transit-vpc-router"
    Managed = "terraform"
  }
}

resource "aws_security_group" "router_sg" {
  name        = "router_security_group"
  description = "router_security_group"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = [
      local.main_vpc_range,
      var.transit_private_subnet
    ]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      local.main_vpc_az,
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  vpc_id = module.transit-vpc.vpc_id

  tags = {
    Managed = "terraform"
  }
}