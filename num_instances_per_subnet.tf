#this will create 1 instance in each subnet.
# each subnet id is added to a list then looped through.

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.vpc.id]
  }

}


locals {
  subnets = [for s in data.aws_subnets.subnets.ids : s]

}

resource "aws_instance" "devops_main" {

    # count = length(local.subnets)
    count = length(local.subnets)
    instance_type = var.main_instance_type
    ami = data.aws_ami.server_ami.id
    #key_name
    vpc_security_group_ids = [aws_security_group.devops_sg.id]
    # subnet_id = aws_subnet.devops_public_subnet[0].id
    subnet_id = local.subnets[count.index]
    root_block_device {
      volume_size = var.main_vol_size
    }
    tags = {
        Name = "devops-main-${count.index + 1}"
    }
}
