# 安装编译环境
sudo yum install gcc pcre-devel tar make -y

# 下载并解压haproxy
curl -O  http://www.haproxy.org/download/2.2/src/haproxy-2.2.4.tar.gz
tar xf haproxy-2.2.4.tar.gz
cd haproxy-2.2.4

# 编译并安装haproxy
make TARGET=linux-glibc
sudo make install
sudo mkdir -p /etc/haproxy
sudo mkdir -p /var/lib/haproxy 
touch /var/lib/haproxy/stats
ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy


sudo cp haproxy-2.2.4/examples/haproxy.init /etc/init.d/haproxy
sudo chmod 755 /etc/init.d/haproxy
sudo systemctl daemon-reload
sudo chkconfig haproxy on
sudo useradd -r haproxy
haproxy -v

# 配置haproxy.cfg
cat > /usr/local/etc/haproxy/haproxy.cfg <<EOF
global
    maxconn 300

defaults
    log global
    mode tcp
    retries 2
    timeout client 30m
    timeout connect 4s
    timeout server 30m
    timeout check 5s

listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /

listen postgres_rw
    bind *:5000
    
    option pgsql-check user optima
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    balance roundrobin
    server pg_master_1 pg_master_1:5432 check port 5432
    server pg_slave_1 pg_slave_1:5432  check port 5432 backup
    server pg_slave_2 pg_slave_2:5432  check port 5432 backup

listen postgres_ro
    bind *:5001
    option pgsql-check user optima
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    balance roundrobin
    server pg_master_1 pg_master_1:5432 check port 5432
    server pg_slave_1 pg_slave_1:5432 check port 5432   weight 100
    server pg_slave_2 pg_slave_2:5432 check port 5432   weight 100
EOF

# 启动
sudo systemctl start haproxy