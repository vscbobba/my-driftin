resource "aws_vpc" "driftin-vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
       name = "driftin-vpc"
    }
}

resource "aws_subnet" "public_1" {
     cidr_block = var.public_1_cidr
     vpc_id = aws_vpc.driftin-vpc.id
     availability_zone = "ap-south-1a"
     map_public_ip_on_launch = true
     tags = {
        name = var.public_1_name
     }
}
resource "aws_subnet" "public_2" {
     cidr_block = var.public_2_cidr
     vpc_id = aws_vpc.driftin-vpc.id
     availability_zone = "ap-south-1b"
     map_public_ip_on_launch = true
     tags = {
        name = var.public_2_name
     }
}
resource "aws_subnet" "private_1" {
     cidr_block = var.private_1_cidr
     vpc_id = aws_vpc.driftin-vpc.id
     availability_zone = "ap-south-1a"
     map_public_ip_on_launch = true
     tags = {
        name = var.private_1_name
     }
}
resource "aws_subnet" "private_2" {
     cidr_block = var.private_2_cidr
     vpc_id = aws_vpc.driftin-vpc.id
     availability_zone = "ap-south-1b"
     tags = {
        name = var.private_2_name
     }
}
resource "aws_internet_gateway" "driftin-gw" {
   vpc_id = aws_vpc.driftin-vpc.id
   tags = {
    name = var.IGW
   }
}
resource "aws_route_table" "public_table" {
    vpc_id = aws_vpc.driftin-vpc.id
}
resource "aws_route_table" "private_table" {
    vpc_id = aws_vpc.driftin-vpc.id
}
resource "aws_route_table_association" "pub1_sub_association" {
   subnet_id = aws_subnet.public_1.id
   route_table_id = aws_route_table.public_table.id
}
resource "aws_route_table_association" "pub2_sub_association" {
   subnet_id = aws_subnet.public_2.id
   route_table_id = aws_route_table.public_table.id
}
resource "aws_route_table_association" "priv1_sub_association" {
   subnet_id = aws_subnet.private_1.id
   route_table_id = aws_route_table.private_table.id
}
resource "aws_route_table_association" "priv2_sub_association" {
   subnet_id = aws_subnet.private_2.id
   route_table_id = aws_route_table.private_table.id
}
resource "aws_route" "main_route" {
    route_table_id = aws_route_table.public_table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.driftin-gw.id
}
/*
resource "aws_eip" "elasticip"{
      domain = "vpc"
}
resource "aws_nat_gateway" "Driftin-NAT" {
     allocation_id = aws_eip.elasticip.id
     subnet_id = aws_subnet.public_1.id
     tags = {
        Name = "Driftin-NAT"
     }
}
resource "aws_route" "nat_route" {
    route_table_id = aws_route_table.private_table.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Driftin-NAT.id
}
*/
resource "aws_vpc" "driftin-vpc-remote" {
    cidr_block = var.vpc_cidr_remote
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
       name = "driftin-vpc-remote"
    }
}
resource "aws_subnet" "private-remote" {
     cidr_block = var.subnet_cidr_remote
     vpc_id = aws_vpc.driftin-vpc-remote.id
     availability_zone = "ap-south-1a"
     tags = {
        name = var.remote_name
     }
}
/*
resource "aws_route_table" "rt-remote" {
      vpc_id = aws_vpc.driftin-vpc-remote.id
}
resource "aws_route_table_association" "example_association" {
  subnet_id      = aws_subnet.private-remote.id
  route_table_id = aws_route_table.rt-remote.id
}

resource "aws_vpc_peering_connection" "peering" {
  peer_vpc_id = aws_vpc.driftin-vpc-remote.id
  vpc_id = aws_vpc.driftin-vpc.id

  tags = {
    Name = "vpc1-to-vpc2-peering"
  }
}

# Accept peering connection on the other side
resource "aws_vpc_peering_connection_accepter" "accepter" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  auto_accept = true
}

# Configure route tables to allow traffic between VPCs
resource "aws_route" "route_to_vpc2" {
  route_table_id = aws_route_table.public_table.id
  destination_cidr_block = aws_vpc.driftin-vpc-remote.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}
resource "aws_route" "route_to_vpc1" {
  route_table_id = aws_route_table.rt-remote.id
  destination_cidr_block = aws_vpc.driftin-vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

*/