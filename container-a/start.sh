#!/bin/bash

# Add sanctum IP for player discovery
echo "172.19.0.13   sanctum" >> /etc/hosts

# Start SSH daemon
/usr/sbin/sshd

# Start FTP daemon
/usr/sbin/vsftpd /etc/vsftpd.conf &

# Start Node.js backend (foreground — keeps container alive)
cd /opt/server && PORT=80 node server.js
