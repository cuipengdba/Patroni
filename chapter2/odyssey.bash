# 检查需求

# 编译
git clone git://github.com/yandex/odyssey.git
cd odyssey
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make

# 安装
## 拷贝相关文件
 mkdir -p /usr/local/odyssey/bin
 mkdir -p /usr/local/odyssey/conf
 cp build/sources/odyssey /usr/local/odyssey/bin
 ln -s  /usr/local/odyssey/bin/odyssey /usr/bin/odyssey
 cp odyssey-dev.conf /usr/local/odyssey/conf/odyssey.conf
 cp -r scripts /usr/local/odyssey/
 
 ## 修改权限
 chown -R postgres:postgres /usr/local/odyssey/
 chmod 775 -R /usr/local/odyssey/

 # 启动
 su postgres
/usr/bin/odyssey /usr/local/odyssey/conf/odyssey.conf