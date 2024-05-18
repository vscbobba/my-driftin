resource "aws_instance" "Jumpserver" {
   instance_type = var.jump_type
   ami = var.jump_ami
   key_name = "driftin"
   subnet_id = data.terraform_remote_state.infrastructure.outputs.aws_pub_1
   vpc_security_group_ids = ["${data.terraform_remote_state.platform.outputs.aws_jump_SG}"]
}
output "aws_jump"{
    value = aws_instance.Jumpserver.public_ip
}