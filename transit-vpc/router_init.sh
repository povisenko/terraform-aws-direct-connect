#! /bin/bash

# Install Docker
apt-get update

apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

apt-key fingerprint 0EBFCD88

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update

apt-get install -y docker-ce

usermod -a -G docker ubuntu

chown -R ubuntu:ubuntu /home/ubuntu/.docker/

# Create restart script
cat > /home/ubuntu/haproxy.cfg <<- "EOF"
       global
           log stdout local0
           daemon
           maxconn 4000

       defaults
           log               global
           mode              http
           option            httplog
           timeout connect   5s
           timeout check     5s
           timeout client    60s
           timeout server    60s
           timeout tunnel    3600s

       frontend http-in
           bind *:80

           #hosts acls
           acl domain1_acl             hdr(host) -i domain-name-1.internal.com
           acl domain2_acl             hdr(host) -i domain-name-2.internal.com


           use_backend domain1         if domain1_acl
           use_backend domain2         if domain2_acl

       backend domain1
           mode http
           option forwardfor
           http-request replace-header Host .* domain-name-1.internal.com
           server domain1 domain-name-1.internal.com:443 ssl verify none

       backend domain2
           mode http
           option forwardfor
           http-request replace-header Host .* domain-name-2.internal.com
           server domain2 domain-name-2.internal.com:443 ssl verify none
EOF


docker run -d --restart always --name haproxy --net=host -v /home/ubuntu:/usr/local/etc/haproxy:ro haproxy:2.1-alpine