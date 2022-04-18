# 安装 keepalived
sudo yum install keepalived

# 或者源码安装
wget https://www.keepalived.org/software/keepalived-2.1.5.tar.gz
tar xf keepalived-2.1.5.tar.gz
cd keepalived-2.1.5
./configure
make
sudo make install


# 安装配置PgBouncer

## 1. 安装PgBouncer（PG1，PG2）
sudo yum install pgbouncer -y

## 2. 配置PgBouncer（PG1，PG2一样）
sudo cat >> /etc/pgbouncer/pgbouncer.ini <<EOF
;
; pgbouncer configuration example
[databases]
* = host=localhost
[pgbouncer]
listen_port = 6432
listen_addr = *
admin_users = optima 
auth_type = md5

; Place it in secure location
auth_file = /etc/pgbouncer/userlist.txt
logfile = /var/log/pgbouncer/pgbouncer.log
pidfile = /var/run/pgbouncer/pgbouncer.pid
; default values
pool_mode = session
default_pool_size = 80

EOF

## 3.运行PgBouncer
sudo systemctl enable pgbouncer
sudo systemctl start pgbouncer
sudo systemctl status pgbouncer

# 安装配置HaProxy

## 1.安装HaProxy（LB1，LB2）
sudo yum install haproxy -y

## 2.配置HaProxy
sudo cat >> /etc/haproxy/haproxy.cfg <<EOF
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
    bind *:5432
    
    option pgsql-check user optima
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    balance roundrobin
    server pg1 192.168.0.102:6432 check port 6432
    server pg2 192.168.0.103:6432  check port 6432 backup

listen postgres_ro
    bind *:5433
    option pgsql-check user optima
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    balance roundrobin
    server pg1 192.168.0.102:6432 check port 6432
    server pg2 192.168.0.103:6432 check port 6432   weight 100
EOF


## 3.运行HaProxy
systemctl enable haproxy
systemctl start haproxy
systemctl status haproxy


# 安装keepalived

## 1.安装keepalived（LB1和LB2均安装）
sudo yum install keepalived -y

## 2.配置keepalived

### LB1（主节点）的Keepalived配置文件
sudo cat >> /etc/keepalived/keepalived.conf <<EOF
# 通知的全局设置（略）  
# 定义用于检查haproxy是否仍在工作的脚本
vrrp_script chk_haproxy { 
    script "/usr/bin/killall -0 haproxy"
    interval 2 
    weight 2 
}
  
# 虚拟接口配置
vrrp_instance LB_VIP {
    interface eth1
    state MASTER        # set to BACKUP on the peer machine
    priority 101        # set to 99 on the peer machine
    virtual_router_id 51  
    authentication {
        auth_type AH
        auth_pass myP@ssword	# 接入vrrpd的密码。在所有设备上都一样
    }
    # 两个负载均衡器共享的虚拟ip地址

virtual_ipaddress {
        192.168.0.99
    }
    # 使用定义的脚本检查是否启动故障转移
    track_script {
        chk_haproxy
    }
}
EOF


### LB2（备节点）的Keepalived配置
sudo cat >> /etc/keepalived/keepalived.conf <<EOF
vrrp_script chk_haproxy { 
    script "/usr/bin/killall -0 haproxy"
    interval 2 
    weight 2 
}
  
vrrp_instance LB_VIP {
    interface eth1
    state BACKUP
    priority 100
    virtual_router_id 51  
    authentication {
        auth_type AH
        auth_pass myP@ssword
    }  
    virtual_ipaddress {
        192.168.0.99
    }
    track_script {
        chk_haproxy
    }
}
EOF


## 3.运行keepalived
sudo systemctl enable keepalived
sudo systemctl start keepalived
sudo systemctl status keepalived