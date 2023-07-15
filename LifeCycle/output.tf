output "webserver_instance_id" {
  value = aws_instance.web.id
  
}

output "web_piblic_ip" {
  value = aws_eip.web.public_ip
}

output "aws_instance_web" {
  value = aws_instance.web.availability_zone
}
