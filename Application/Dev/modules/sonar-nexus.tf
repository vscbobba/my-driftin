resource "aws_instance" "CI_instance" {
  ami = "ami-0d82b4dd52aa37cc3" // Centos AMI, change to your desired AMI
  instance_type = "t2.large" // Change instance type as needed
  subnet_id = data.terraform_remote_state.infrastructure.outputs.aws_pub_1
  vpc_security_group_ids = ["${data.terraform_remote_state.platform.outputs.aws_jump_SG}"]
  key_name = "driftin"
  root_block_device {
    volume_size = 16
  }
  iam_instance_profile = data.terraform_remote_state.platform.outputs.s3full_instance_profile
  tags = {
    Name = "CI-instance"
  }
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              echo 'ClientAliveInterval 60' | sudo tee --append /etc/ssh/sshd_config
              sudo sed -i 's/^StrictHostKeyChecking.*/StrictHostKeyChecking no/' /etc/ssh/ssh_config
              sudo service ssh restart
              sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              sudo apt update -y
              sudo apt  install awscli -y
              sudo apt install -y docker-ce
              sudo usermod -aG docker ubuntu
              echo 'ubuntu ALL=(ALL:ALL) ALL' | sudo tee -a /etc/sudoers

              # Install Docker Compose
              sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

              # Create docker-compose.yml file
              cat <<EOT >> /home/ubuntu/docker-compose.yml
              version: '3'
              services:
                sonarqube:
                  image: sonarqube
                  container_name: sonarqube
                  ports:
                    - "9000:9000"
                  networks:
                    - my_network
                  volumes:
                    - sonarqube_data:/opt/sonarqube/data

                nexus:
                  image: sonatype/nexus3
                  container_name: nexus
                  ports:
                    - "8081:8081"
                  networks:
                    - my_network
                  volumes:
                    - nexus_data:/nexus-data

              networks:
                my_network:
                  driver: bridge

              volumes:
                sonarqube_data:
                  driver: local
                nexus_data:
                  driver: local
              EOT

              # Start Docker Compose
              cd /home/ubuntu
              sudo docker-compose up -d
              EOF
}

resource "aws_route53_record" "CI_dns" {
    zone_id = "Z04538961L8QK9TOW8IBT"
    type = "A"
    name = "sona.bobbascloud.online"
    ttl = 300
    records = [aws_instance.CI_instance.public_ip]
}


