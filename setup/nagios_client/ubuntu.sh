#!/bin/bash

#ubuntu nagios客户端一键安装脚本
#作者：章郎虫
#博客：http://www.sijitao.net/

mkdir /usr/local/nagios
/usr/sbin/useradd -m -s/sbin/nologin nagios
chown nagios.nagios /usr/local/nagios/
groupadd nagcmd
usermod -a -G nagcmd nagios

apt-get -y install build-essential gcc libssl-dev libssl0.9.8 make openssl

wget http://download.chekiang.info/nagios/setup/nagios_client/nagios-plugins-2.0.3.tar.gz

tar zxvf nagios-plugins-2.0.3.tar.gz
cd nagios-plugins-2.0.3
./configure --with-nagios-user=nagios --with-nagios-group=nagios --prefix=/usr/local/nagios
make && make install
chown -R nagios.nagios /usr/local/nagios/libexec
cd ..

wget http://download.chekiang.info/nagios/setup/nagios_client/nrpe-2.15.tar.gz

tar zxvf nrpe-2.15.tar.gz
cd nrpe-2.15
./configure --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu
make all
make install
make install-plugin
make install-daemon
make install-daemon-config
cd ..
sed -i 's/allowed_hosts=.*/allowed_hosts=127.0.0.1,192.168.0.253,122.227.239.134,192.168.188.2/g' /usr/local/nagios/etc/nrpe.cfg
cnt=`grep -c "/usr/local/nagios/bin/nrpe -c /usr/local/nagios/etc/nrpe.cfg -d" /etc/rc.local`
if [ $cnt -eq 0 ];then
	sed -i '/.*exit 0.*/i\/usr/local/nagios/bin/nrpe -c /usr/local/nagios/etc/nrpe.cfg -d' /etc/rc.local
fi
cat >>/usr/local/nagios/etc/nrpe.cfg<<"EOF"
command[check_swap]=/usr/local/nagios/libexec/check_swap -w 90% -c 60%
command[check_/]=/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /
EOF

/usr/local/nagios/bin/nrpe -c /usr/local/nagios/etc/nrpe.cfg -d

cat >restart_nrpe.sh<<"EOF"
#!/bin/bash
export PATH="$PATH"
killall nrpe
/usr/local/nagios/bin/nrpe -c /usr/local/nagios/etc/nrpe.cfg -d
sleep 1
ps -ef|grep nagios
EOF
chmod +x restart_nrpe.sh
