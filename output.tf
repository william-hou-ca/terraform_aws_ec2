output "amz2_ami_id" {
  value = data.aws_ami.amz2.id
}

output "default_vpcs" {
  value = data.aws_security_groups.default_sg.ids
}

output "ec2_public_hostname" {
  value = aws_instance.web.public_dns
}

output "eip_public_name" {
  value = aws_eip.eip.public_dns
}