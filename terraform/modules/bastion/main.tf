resource "aws_instance" "this" {
  count = var.enable_bastion ? 1 : 0

  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  iam_instance_profile        = var.instance_profile_name

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-bastion"
  }
}

resource "aws_eip" "this" {
  count = var.enable_bastion ? 1 : 0

  instance = aws_instance.this[0].id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-bastion-eip"
  }
}
