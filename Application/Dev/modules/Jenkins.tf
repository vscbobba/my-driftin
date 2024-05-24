// Create a new EC2 instance
resource "aws_instance" "jenkins_instance" {
  ami = "ami-0cc9838aa7ab1dce7" // Amazon Linux 2 AMI, change to your desired AMI
  instance_type = "t2.medium" // Change instance type as needed
  subnet_id = data.terraform_remote_state.infrastructure.outputs.aws_pub_1
  vpc_security_group_ids = ["${data.terraform_remote_state.platform.outputs.aws_remote_SG}"]
  key_name = "driftin"
  iam_instance_profile = data.terraform_remote_state.platform.outputs.s3full_instance_profile
  tags = {
    Name = "jenkins-instance"
  }
  associate_public_ip_address = true
  
  provisioner "file" {
    source      = "script_jenkins_restore"
    destination = "/home/ec2-user/script_jenkins_backup"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("/home/venkat/Downloads/driftin.pem")
    host        = self.public_ip
  }
  provisioner "remote-exec" {
  inline = [
    // Update package repositories and install Jenkins
    "sudo dnf update -y",
    "sudo dnf install -y wget",
    "sudo dnf install java-17-amazon-corretto -y",
    "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
    "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
    "sudo dnf install jenkins -y",
    "sudo systemctl start jenkins",
    "sudo systemctl enable jenkins",
  ]  
    
    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user" // Change user based on your AMI
      private_key = file("/home/venkat/Downloads/driftin.pem") // Replace with your private key file path
    }
  }
}

resource "aws_route53_record" "jenkins_dns" {
    zone_id = "Z04538961L8QK9TOW8IBT"
    type = "A"
    name = "jenkins.bobbascloud.online"
    ttl = 300
    records = [aws_instance.jenkins_instance.public_ip]
}
