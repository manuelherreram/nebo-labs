#!/bin/bash
set -euxo pipefail

# Update + install nginx across common distros
if command -v dnf >/dev/null 2>&1; then
  dnf -y update
  dnf -y install nginx
elif command -v yum >/dev/null 2>&1; then
  yum -y update
  yum -y install nginx
elif command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y nginx
fi

# Simple homepage
cat > /usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>NEBo — Hello</title></head>
<body><h1>Hello NEBo</h1><p>Provisioned by user-data (nginx).</p></body>
</html>
HTML

# Enable + start nginx
systemctl enable nginx
systemctl start nginx
