output "aws_vpc" {
   value = aws_vpc.driftin-vpc.id
}

output "aws_pub_1"{
   value = aws_subnet.public_1.id
}
output "aws_pub_2" {
  value = aws_subnet.public_2.id
}

output "aws_priv_1" {
  value = aws_subnet.private_1.id
}

output "aws_priv_2" {
  value = aws_subnet.private_2.id
}

output "aws_vpc_remote" {
  value = aws_vpc.driftin-vpc-remote.id
}

output "aws_subnet_remote" {
  value = aws_subnet.private-remote.id
}

output "aws_vpc_cidr" {
   value = aws_vpc.driftin-vpc.cidr_block
}