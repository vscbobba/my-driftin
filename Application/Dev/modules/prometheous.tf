
// Create a new EC2 instance
resource "aws_instance" "prometheus_instance" {
  ami = var.amazon_linux_2023 // Amazon Linux 2 AMI, change to your desired AMI
  instance_type = var.jenkins_type // Change instance type as needed
  subnet_id = data.terraform_remote_state.infrastructure.outputs.aws_pub_1
  vpc_security_group_ids = [data.terraform_remote_state.platform.outputs.aws_jump_SG]
  key_name = "driftin"
  tags = {
    Name = "prometheus-instance"
  }

  provisioner "remote-exec" {
  inline = [
    // Update package repositories and install Prometheus
    "sudo yum update -y",
    "sudo yum install -y wget",
    "sudo wget https://github.com/prometheus/prometheus/releases/download/v2.52.0/prometheus-2.52.0.linux-amd64.tar.gz", // Replace X.X.X with the desired version
    "sudo tar -xzf prometheus-2.52.0.linux-amd64.tar.gz",
    "sudo rm -rf prometheus-2.52.0.linux-amd64.tar.gz",
    "sudo mv prometheus-2.52.0.linux-amd64 prometheus-files",
    "sudo useradd --no-create-home --shell /bin/false prometheus",
    "sudo mkdir /etc/prometheus",
    "sudo mkdir /var/lib/prometheus",
    "sudo chown prometheus:prometheus /etc/prometheus",
    "sudo chown prometheus:prometheus /var/lib/prometheus",
    "sudo cp prometheus-files/prometheus /usr/local/bin/",
    "sudo cp prometheus-files/promtool /usr/local/bin/",
    "sudo chown prometheus:prometheus /usr/local/bin/prometheus",
    "sudo chown prometheus:prometheus /usr/local/bin/promtool",
    "sudo cp -r prometheus-files/consoles /etc/prometheus",
    "sudo cp -r prometheus-files/console_libraries /etc/prometheus",
    "sudo chown -R prometheus:prometheus /etc/prometheus/consoles",
    "sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries",
    "sudo cat <<EOF | sudo tee /etc/prometheus/prometheus.yml > /dev/null",
    "global:",
    "  scrape_interval: 10s",
    "scrape_configs:",
    "- job_name: 'prometheus'",
    "  scrape_interval: 5s",
    "  static_configs:",
    "  - targets:",
    "    - 'localhost:9090'",
    "- job_name: 'jenkins'",
    "  scrape_interval: 5s",
    "  dns_sd_configs:",
    "  - names:", 
    "    - 'jenkins.bobbascloud.online'",
    "    type: 'A'",
    "    port: 9100",
    "EOF",
    "sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml",
    "sudo cat <<EOF | sudo tee /etc/systemd/system/prometheus.service > /dev/null",
    "[Unit]",
    "Description=Prometheus",
    "Wants=network-online.target",
    "After=network-online.target",
    
    "[Service]",
    "User=prometheus",
    "Group=prometheus",
    "Type=simple",
    "ExecStart=/usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml --storage.tsdb.path /var/lib/prometheus/ --web.console.templates=/etc/prometheus/consoles --web.console.libraries=/etc/prometheus/console_libraries",
    
    "[Install]",
    "WantedBy=multi-user.target",
    "EOF",
    "sudo systemctl daemon-reload",
    "sudo systemctl restart prometheus",
    "sudo systemctl enable prometheus",
    "sudo wget https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-amd64.tar.gz",
    "sudo tar xvfz node_exporter-*.tar.gz",
    "sudo rm -rf node_exporter-1.2.2.linux-amd64.tar.gz",
    "cd node_exporter-1.2.2.linux-amd64/",
    "sudo mv node_exporter /usr/local/bin/",
    "sudo useradd --no-create-home --shell /bin/false node_exporter",
    "sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter",
    "sudo cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service > /dev/null",
    "[Unit]",
    "Description=Node Exporter",
    "Wants=network-online.target",
    "After=network-online.target",
    
    "[Service]",
    "User=node_exporter",
    "Group=node_exporter",
    "Type=simple",
    "ExecStart=/usr/local/bin/node_exporter",
    
    "[Install]",
    "WantedBy=multi-user.target",
    "EOF",
    "sudo systemctl enable node_exporter",
    "sudo systemctl restart node_exporter",
    "sudo yum update -y",
    "sudo cat <<EOF | sudo tee /etc/yum.repos.d/grafana.repo > /dev/null",
    "[grafana]",
    "name=grafana",
    "baseurl=https://packages.grafana.com/oss/rpm",
    "repo_gpgcheck=1",
    "enabled=1",
    "gpgcheck=1",
    "gpgkey=https://packages.grafana.com/gpg.key",
    "sslverify=1",
    "sslcacert=/etc/pki/tls/certs/ca-bundle.crt",
    "EOF",
    "sudo yum install grafana -y",
    "sudo systemctl daemon-reload",
    "sudo systemctl restart grafana-server",
    "sudo systemctl enable grafana-server.service",
  ]  
    
    connection {
      type        = "ssh"
      host        = aws_instance.prometheus_instance.public_ip
      user        = "ec2-user" // Change user based on your AMI
      private_key = file("/home/venkat/Downloads/driftin.pem") // Replace with your private key file path
    }
  }
}


// Create a new EC2 instance
resource "aws_instance" "jenkins_instance" {
  ami = var.amazon_linux_2023 // Amazon Linux 2 AMI, change to your desired AMI
  instance_type = var.jenkins_type // Change instance type as needed
  subnet_id = data.terraform_remote_state.infrastructure.outputs.aws_pub_1
  vpc_security_group_ids = ["${data.terraform_remote_state.platform.outputs.aws_jump_SG}"]
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
    "sudo wget https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-amd64.tar.gz",
    "sudo tar xvfz node_exporter-*.tar.gz",
    "sudo rm -rf node_exporter-1.2.2.linux-amd64.tar.gz",
    "cd node_exporter-1.2.2.linux-amd64/",
    "sudo mv node_exporter /usr/local/bin/",
    "sudo useradd --no-create-home --shell /bin/false node_exporter",
    "sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter",
    "sudo cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service > /dev/null",
    "[Unit]",
    "Description=Node Exporter",
    "Wants=network-online.target",
    "After=network-online.target",
    
    "[Service]",
    "User=node_exporter",
    "Group=node_exporter",
    "Type=simple",
    "ExecStart=/usr/local/bin/node_exporter",
    
    "[Install]",
    "WantedBy=multi-user.target",
    "EOF",
    "sudo systemctl enable node_exporter",
    "sudo systemctl start node_exporter",
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
    zone_id = var.zone_id
    type = "A"
    name = var.jenkins_dns
    ttl = 300
    records = [aws_instance.jenkins_instance.public_ip]
}


resource "aws_route53_record" "prometheus_dns" {
    zone_id = var.zone_id
    type = "A"
    name = var.prometheus_dns
    ttl = 300
    records = [aws_instance.prometheus_instance.public_ip]
}
