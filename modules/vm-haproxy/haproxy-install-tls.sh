#!/bin/bash

echo "10.230.1.10 haproxy-a.local haproxy-a" | sudo tee -a /etc/hosts
echo "10.230.1.20 haproxy-b.local haproxy-b" | sudo tee -a /etc/hosts
echo "10.230.2.110 web-a.local web-a" | sudo tee -a /etc/hosts
echo "10.230.2.120 web-b.local web-b" | sudo tee -a /etc/hosts
echo "10.230.2.130 web-c.local web-c" | sudo tee -a /etc/hosts

sudo apt-get update
sudo apt-get upgrade -y
apt install -y build-essential
apt install -y libreadline-dev

# kernel configuration
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
sysctl -p

# Install LUA
cd /tmp
wget https://www.lua.org/ftp/lua-5.4.3.tar.gz --no-check-certificate
tar xvfz lua-5.4.3.tar.gz
cd lua-5.4.3/
make INSTALL_TOP=/opt/lua-5.4.3 linux install

echo 'export PATH="/opt/lua-5.4.3/bin/:$PATH"' | tee -a /etc/profile

apt -y install libssl-dev libpcre++-dev libz-dev libsystemd-dev

# Create user haproxy
id -u haproxy &> /dev/null || useradd -s /usr/sbin/nologin -r haproxy

# HA-Proxy source
cd /tmp
wget http://www.haproxy.org/download/2.5/src/haproxy-2.5.0.tar.gz
tar xvfz haproxy-2.5.0.tar.gz
cd haproxy-2.5.0
make clean
make -j $(nproc) TARGET=linux-glibc USE_OPENSSL=1 USE_ZLIB=1 USE_LUA=1 USE_PCRE=1 USE_SYSTEMD=1 LUA_INC=/opt/lua-5.4.3/include LUA_LIB=/opt/lua-5.4.3/lib
make install

ln -s /usr/local/sbin/haproxy  /usr/sbin/

# HA-proxy Error files
mkdir -p /etc/haproxy/errors/
cp -fr examples/errorfiles/* /etc/haproxy/errors/

# Create manual page
mkdir -p /usr/share/doc/haproxy/
wget -qO - https://raw.githubusercontent.com/horms/haproxy/master/doc/configuration.txt | gzip -c > /usr/share/doc/haproxy/configuration.txt.gz

# Create Socket and Stats Directory
mkdir /run/haproxy
mkdir /var/lib/haproxy

# Add global, default and frontend statistic config

# Generate admin password
ADMPASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 15; echo)

cat > /etc/haproxy/haproxy.cfg <<EOF
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy-admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    tune.ssl.default-dh-param 2048
    daemon

    # Default SSL material location
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # Default ciphers to use on SSL-enabled listening sockets.
    # For more information see ciphers(1SSL). This list is from:
    # https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
    # An alternative list with additional directives can be obtained from
    # https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=haproxy
    ssl-default-bind-ciphers ECDH+AESGCM:DH:AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA:AESGCM:RSA+AES:!aNULL:!MD5:!DSS
    ssl-default-bind-options no-sslv3

defaults
    log global
    mode http
    option httplog
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    timeout http-request 5s
    # option http-use-htx # add this for grpc support
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

frontend stats
    bind *:8080
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:$ADMPASS

frontend frontend_ssl_termination
    bind *:80
    mode http
    default_backend http_port_80
    option forwardfor

backend http_port_80
  balance roundrobin # round robin lBA
  server web-a.local 10.230.2.110:80 weight 1 maxconn 512 check
  server web-b.local 10.230.2.120:80 weight 1 maxconn 512 check
  server web-c.local 10.230.2.130:80 weight 1 maxconn 512 check

EOF

# SystemD haproxy service file
cat > /etc/systemd/system/haproxy.service <<EOF
[Unit]
Description=HAProxy Load Balancer
After=syslog.target network.target

[Service]
Environment="CONFIG=/etc/haproxy/haproxy.cfg" "PIDFILE=/run/haproxy.pid" "EXTRAOPTS=-S /run/haproxy-master.sock"
#EnvironmentFile=/etc/sysconfig/haproxy
ExecStartPre=/usr/sbin/haproxy -f \$CONFIG -c -q \$EXTRAOPTS
ExecStart=/usr/sbin/haproxy -Ws -f \$CONFIG -p \$PIDFILE \$EXTRAOPTS \$OPTIONS
ExecReload=/usr/sbin/haproxy -f \$CONFIG -c -q \$EXTRAOPTS
ExecReload=/bin/kill -USR2 \$MAINPID
KillMode=mixed
Restart=always
SuccessExitStatus=143
Type=notify

[Install]
WantedBy=multi-user.target
EOF

# rsyslog configuration
cat > /etc/rsyslog.d/49-haproxy.conf <<EOF
$AddUnixListenSocket /var/lib/haproxy/dev/log
if $programname startswith 'haproxy' then /var/log/haproxy.log
&~
EOF

systemctl daemon-reload

# Restart haproxy
systemctl restart rsyslog
systemctl enable haproxy
systemctl restart haproxy


hostnamectl set-hostname ${vm_name}.local
reboot


