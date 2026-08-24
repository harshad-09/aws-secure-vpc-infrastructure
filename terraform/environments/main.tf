module "vpc" {
  source = "../modules/vpc"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  public_subnet      = var.public_subnet
  private_subnet     = var.private_subnet
  single_nat_gateway = var.single_nat_gateway
}

module "security" {
  source = "../modules/security"

  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  ssh_allowed_cidr = var.ssh_allowed_cidr
  app_port         = var.app_port
}

module "iam" {
  source = "../modules/iam"

  project_name = var.project_name
}

module "alb" {
  source = "../modules/alb"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids_list
  alb_sg_id          = module.security.alb_sg_id
  app_port           = var.app_port
  health_check_path  = var.health_check_path
}

module "asg" {
  source = "../modules/asg"

  project_name               = var.project_name
  ami_id                     = var.ami_id
  instance_type              = var.instance_type
  key_pair_name              = var.key_pair_name
  user_data_base64 = filebase64("${path.module}/../user_data.sh")
  instance_profile_name      = module.iam.app_instance_profile_name
  app_sg_id                  = module.security.app_sg_id
  private_subnet_ids         = module.vpc.private_subnet_ids_list
  target_group_arn           = module.alb.target_group_arn
  asg_desired_capacity       = var.asg_desired_capacity
  asg_min                    = var.asg_min
  asg_max                    = var.asg_max
  health_check_grace_period  = var.health_check_grace_period
}

module "bastion" {
  source = "../modules/bastion"

  project_name           = var.project_name
  enable_bastion         = var.enable_bastion
  ami_id                 = var.ami_id
  instance_type          = var.instance_type
  public_subnet_id       = module.vpc.public_subnet_ids[keys(var.public_subnet)[0]]
  bastion_sg_id          = module.security.bastion_sg_id
  key_pair_name          = var.key_pair_name
  instance_profile_name  = module.iam.bastion_instance_profile_name
}
