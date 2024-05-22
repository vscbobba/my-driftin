output "aws_jump_SG" {
    value = aws_security_group.jum_sg.id
}
output "aws_remote_SG" {
    value = aws_security_group.remote_sg.id
}
output "lambda_role1_name"{
    value = aws_iam_role.lambda_role.name
}
output "lambda_role1"{
    value = aws_iam_role.lambda_role.arn
}