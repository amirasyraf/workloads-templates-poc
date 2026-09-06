output "instance_id" {
  description = "EC2 instance ID, or null when desired_state is absent."
  value       = try(aws_instance.server[0].id, null)
}

output "private_ip" {
  description = "Private IPv4 address, or null when desired_state is absent."
  value       = try(aws_instance.server[0].private_ip, null)
}

output "public_ip" {
  description = "Public IPv4 address when assigned, otherwise null."
  value       = try(aws_instance.server[0].public_ip, null)
}

output "ssm_role_arn" {
  description = "Instance role ARN, or null when desired_state is absent."
  value       = try(aws_iam_role.ssm[0].arn, null)
}
