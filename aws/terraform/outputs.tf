output "public_ip" {
  description = "public IP addresses assigned to the instances, if applicable"
  value       = aws_spot_instance_request.photogrammetry.public_ip
}

output "id" {
  description = "IDs of instances"
  value       = aws_spot_instance_request.photogrammetry.id
}

output "instance_id" {
  description = "IDs of instances"
  value       = aws_spot_instance_request.photogrammetry.instance_id
}

output "arn" {
  description = "ARNs of instances"
  value       = aws_spot_instance_request.photogrammetry.arn
}

output "availability_zone" {
  description = "availability zones of instances"
  value       = aws_spot_instance_request.photogrammetry.availability_zone
}

output "placement_group" {
  description = "placement groups of instances"
  value       = aws_spot_instance_request.photogrammetry.placement_group
}

output "key_name" {
  description = "key names of instances"
  value       = aws_spot_instance_request.photogrammetry.key_name
}

output "password_data" {
  description = "Base-64 encoded encrypted password data for the instance"
  value       = aws_spot_instance_request.photogrammetry.password_data
}

output "public_dns" {
  description = "public DNS names assigned to the instances. For EC2-VPC, photogrammetry is only available if you've enabled DNS hostnames for your VPC"
  value       = aws_spot_instance_request.photogrammetry.public_dns
}


output "ipv6_addresses" {
  description = "assigned IPv6 addresses of instances"
  value       = aws_spot_instance_request.photogrammetry.ipv6_addresses
}

output "primary_network_interface_id" {
  description = "IDs of the primary network interface of instances"
  value       = aws_spot_instance_request.photogrammetry.primary_network_interface_id
}

output "private_dns" {
  description = "private DNS names assigned to the instances. Can only be used inside the Amazon EC2, and only available if you've enabled DNS hostnames for your VPC"
  value       = aws_spot_instance_request.photogrammetry.private_dns
}

output "private_ip" {
  description = "private IP addresses assigned to the instances"
  value       = aws_spot_instance_request.photogrammetry.private_ip
}

output "security_groups" {
  description = "associated security groups of instances"
  value       = aws_spot_instance_request.photogrammetry.security_groups
}

output "vpc_security_group_ids" {
  description = "associated security groups of instances, if running in non-default VPC"
  value       = aws_spot_instance_request.photogrammetry.vpc_security_group_ids
}

output "subnet_id" {
  description = "IDs of VPC subnets of instances"
  value       = aws_spot_instance_request.photogrammetry.subnet_id
}

output "credit_specification" {
  description = "credit specification of instances"
  value       = aws_spot_instance_request.photogrammetry.credit_specification
}

output "metadata_options" {
  description = "metadata options of instances"
  value       = aws_spot_instance_request.photogrammetry.metadata_options
}

output "instance_state" {
  description = "instance states of instances"
  value       = aws_spot_instance_request.photogrammetry.instance_state
}

output "root_block_device_volume_ids" {
  description = "volume IDs of root block devices of instances"
  value       = [for device in aws_spot_instance_request.photogrammetry.root_block_device : device.*.volume_id]
}

output "ebs_block_device_volume_ids" {
  description = "volume IDs of EBS block devices of instances"
  value       = [for device in aws_spot_instance_request.photogrammetry.ebs_block_device : device.*.volume_id]
}

output "tags" {
  description = "tags of instances"
  value       = aws_spot_instance_request.photogrammetry.tags
}

output "volume_tags" {
  description = "tags of volumes of instances"
  value       = aws_spot_instance_request.photogrammetry.volume_tags
}
