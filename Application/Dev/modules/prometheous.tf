
// Create a new EC2 instance
resource "aws_instance" "prometheus_instance" {
  ami = "ami-0cc9838aa7ab1dce7" // Amazon Linux 2 AMI, change to your desired AMI
  instance_type = "t2.medium" // Change instance type as needed
  subnet_id = data.terraform_remote_state.infrastructure.outputs.aws_pub_1
  security_groups = [data.terraform_remote_state.platform.outputs.aws_jump_SG]
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
    "sudo systemctl start prometheus",
  ]  
    
    connection {
      type        = "ssh"
      host        = aws_instance.prometheus_instance.public_ip
      user        = "ec2-user" // Change user based on your AMI
      private_key = file("/home/venkat/Downloads/driftin.pem") // Replace with your private key file path
    }
  }
}
