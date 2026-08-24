resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow http/https traffic to Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    to_port     = 80
    from_port   = 80
    protocol    = "tcp"
    description = "http"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    to_port     = 443
    from_port   = 443
    protocol    = "tcp"
    description = "https"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    to_port     = 0
    from_port   = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Allow ssh to bastion host"
  vpc_id      = var.vpc_id

  ingress {
    to_port     = 22
    from_port   = 22
    protocol    = "tcp"
    description = "ssh"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    to_port     = 0
    from_port   = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-bastion-sg"
  }
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Allow traffic from alb and ssh from bastion"
  vpc_id      = var.vpc_id

  ingress {
    to_port         = 22
    from_port       = 22
    protocol        = "tcp"
    description     = "ssh from bastion"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    to_port         = var.app_port
    from_port       = var.app_port
    protocol        = "tcp"
    description     = "app traffic from alb"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    to_port     = 0
    from_port   = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}
