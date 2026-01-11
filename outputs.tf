output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_public_ips" {
  value = aws_instance.backend[*].public_ip
}

output "backend_private_ips" {
  value = aws_instance.backend[*].private_ip
}