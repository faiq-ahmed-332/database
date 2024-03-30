# Remote State Imports

data "terraform_remote_state" "infrastructure" {
    backend = "s3"
    config = {
      bucket     = var.s3_bucket_dev_state
      key        = "aws/fmk/dev/infrastructure/terraform.tfstate"
      region     = var.region
    }
}


data "aws_vpc" "my" {
  filter {
    name = "tag:Owner"
    values = ["Terraform"]
 }
}


# Set Provider and Region
provider "aws" {
    region = var.region
}


resource "aws_db_subnet_group" "sharedaffairs_db_subnet_group" {
  name       = "sharedaffairs_db_subnet_group"
  subnet_ids = "${split(",",data.terraform_remote_state.infrastructure.outputs.private_subnet_appdata_ids)}"

  tags = {
    Name = "sharedaffairs_db_subnet_group"
  }
}


resource "aws_db_instance" "sharedaffairs_db" {

  identifier           = "sharedaffairs"
  engine               = "mysql"
  engine_version       = "5.7"
  name                 = "sharedaffairs"
  username             = "mysqlmaster"
  password             = "mysqlmaster"
  instance_class       = "db.t2.small"
  db_subnet_group_name  = "${aws_db_subnet_group.sharedaffairs_db_subnet_group.name}" 
  allocated_storage     = 50
  max_allocated_storage = 100
  skip_final_snapshot       = true
  vpc_security_group_ids = ["${aws_security_group.rdsSG.id}"]
  storage_encrypted = true

}



###resource "aws_security_group" "database" {
###  name        = "wordpress-database-sg"
####  vpc_id      = "${var.networking_module.vpc_id}"
###
###
###resource "aws_security_group_rule" "wordpress-database-from-instance" {
###  
###type      = "ingress"
###  from_port = 3306
###  to_port   = 3306
###  protocol  = "tcp"
###security_group_id        = aws_security_group.database.id
####source_security_group_id = aws_security_group.wordpress_instance[count.index].id
###}


#variable "vpc_id" {}
#data "aws_vpc" "selected" {
#  id = "${var.vpc_id}"
#}


resource "aws_security_group" "rdsSG" {
    name = "rdsSG"
    description = "RDS security group"
#    vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
    vpc_id = "${data.terraform_remote_state.infrastructure.outputs.vpc_id}"
			 
    ingress {
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      cidr_blocks = "${split(",",data.terraform_remote_state.infrastructure.outputs.vpc_cidr)}"
   }
   egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}


