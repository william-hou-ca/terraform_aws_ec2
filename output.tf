output "amz2_ami_id" {
  value = data.aws_ami.amz2.id
}

output "default_vpcs" {
  value = data.aws_security_groups.default_sg.ids
}