resource "aws_instance" "sonar_instance" {
    ami           = "ami-0cc9838aa7ab1dce7" # Amazon Linux 2 AMI
    instance_type = "t2.small"
    subnet_id = data.terraform_remote_state.infrastructure.outputs.aws_pub_1
    vpc_security_group_ids = ["${data.terraform_remote_state.platform.outputs.aws_jump_SG}"]
    key_name = "driftin"
    tags = {
      Name = "sonar-instance"
    }
    provisioner "remote-exec" {
        inline = [
        "sudo dnf update -y",
        "sudo dnf install -y java-11-amazon-corretto.x86_64",
        "sudo yum install -y wget unzip",
        "wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.4.0.54424.zip",
        "unzip sonarqube-9.4.0.54424.zip",
        "sudo mv sonarqube-9.4.0.54424 /opt/sonarqube",
        "sudo useradd sonar",
        "sudo chown -R sonar:sonar /opt/sonarqube",
        "sudo chmod -R 775 /opt/sonarqube",
        "sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<EOL",
        "[Unit]",
        "Description=SonarQube service",
        "After=syslog.target network.target",

        "[Service]",
        "Type=forking",

        "ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start",
        "ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop",

        "User=sonar",
        "Group=sonar",
        "Restart=always",

        "LimitNOFILE=65536",
        "LimitNPROC=4096",

        "[Install]",
        "WantedBy=multi-user.target",
        "EOL",
      "sudo systemctl enable sonarqube",
      "sudo systemctl start sonarqube"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/home/venkat/Downloads/driftin.pem") // Replace with your private key file path
      host        = self.public_ip
    }
  }
}

output "sonarqube_public_ip" {
  value = aws_instance.sonar_instance.public_ip
}

resource "aws_route53_record" "jenkins_dns" {
    zone_id = "Z04538961L8QK9TOW8IBT"
    type = "A"
    name = "sonar.bobbascloud.online"
    ttl = 300
    records = [aws_instance.sonar_instance.public_ip]
}