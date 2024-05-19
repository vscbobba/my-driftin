#!/bin/bash
sudo yum update -y
sudo yum install -y nginx
sudo bash -c 'cat <<EOF > /usr/share/nginx/html/index.html
<html>
<head><title>Custom Nginx Page</title></head>
<body>
<h1>Welcome to my custom Nginx page!</h1>
<p>This is a custom Nginx page served by Terraform.</p>
</body>
</html>
EOF'
sudo service nginx restart
