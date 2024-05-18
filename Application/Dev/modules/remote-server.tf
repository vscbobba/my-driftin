resource "aws_instance" "remote_server"{
   instance_type = var.jump_type
   ami = var.jump_ami
   key_name = "driftin"
   subnet_id = data.terraform_remote_state.infrastructure.outputs.aws_subnet_remote
   vpc_security_group_ids = ["${data.terraform_remote_state.platform.outputs.aws_remote_SG}"]
}
output "aws_remote"{
    value = aws_instance.remote_server.private_ip
}

