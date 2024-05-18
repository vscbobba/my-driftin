output "aws_jump_SG" {
    value = aws_security_group.jum_sg.id
}
output "aws_remote_SG" {
    value = aws_security_group.remote_sg.id
}
