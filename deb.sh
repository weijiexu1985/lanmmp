#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH

if [ $(id -u) != "0" ]; then
	printf "Error: You must be root to run this script!"
	exit 1
fi

LANMP_PATH=`pwd`
if [ `echo $LANMP_PATH | awk -F/ '{print $NF}'` != "lanmp" ]; then
	clear && echo "Please enter lanmp script path:"
	read -p "(Default path: ${LANMP_PATH}/lanmp):" LANMP_PATH
	[ -z "$LANMP_PATH" ] && LANMP_PATH=$(pwd)/lanmp
	cd $LANMP_PATH/
fi

clear
echo "#############################################################"
echo "# Linux + Apache + Nginx + MariaDB + Moodle + PHP Auto Install Script"
echo "# Env: Debian/Ubuntu"
echo "# Intro: "
echo "# Version: $(awk '/version/{print $2}' $LANMMP_PATH/Changelog)"
echo "#"
echo "# Copyright (c) 2014, weijiexu <weijiexu1985@163.com>"
echo "# WangYan lanmp modification based on,Thanks wangyan"
echo "# All rights reserved."
echo "# Distributed under the GNU General Public License, version 1.0."
echo "#"
echo "#############################################################"
echo ""

echo "Please enter the server IP address:"
TEMP_IP=`ifconfig |grep 'inet' | grep -Evi '(inet6|127.0.0.1)' | awk '{print $2}' | cut -d: -f2 | tail -1`
read -p "(e.g: $TEMP_IP):" IP_ADDRESS
if [ -z $IP_ADDRESS ]; then
	IP_ADDRESS="$TEMP_IP"
fi
echo "---------------------------"
echo "IP address = $IP_ADDRESS"
echo "---------------------------"
echo ""

echo "Please enter the webroot dir:"
read -p "(Default webroot dir: /var/www):" WEBROOT
if [ -z $WEBROOT ]; then
	WEBROOT="/var/www"
fi
echo "---------------------------"
echo "Webroot dir=$WEBROOT"
echo "---------------------------"
echo ""

echo "Please enter the MySQL root password:"
read -p "(Default password: 123456):" MYSQL_ROOT_PWD
if [ -z $MYSQL_ROOT_PWD ]; then
	MYSQL_ROOT_PWD="123456"
fi
echo "---------------------------"
echo "MySQL root password = $MYSQL_ROOT_PWD"
echo "---------------------------"
echo ""

echo "Please enter the MySQL pma password:"
read -p "(Default password: 123456):" PMAPWD
if [ -z $PMAPWD ]; then
	PMAPWD="123456"
fi
echo "---------------------------"
echo "PMA password = $PMAPWD"
echo "---------------------------"
echo ""

echo "Please choose webserver software! (1:nginx,2:apache,3:nginx+apache) (1/2/3)"
read -p "(Default: 3):" SOFTWARE
if [ -z $SOFTWARE ]; then
	SOFTWARE="3"
fi
echo "---------------------------"
echo "You choose = $SOFTWARE"
echo "---------------------------"
echo ""

echo "Please choose the version of PHP: (1:php-5.2.x,2:php-5.5.x) (1/2)"
read -p "(Default version: 2):" PHP_VER
if [ -z $PHP_VER ]; then
	PHP_VER="2"
fi
echo "---------------------------"
echo "PHP Version = $PHP_VER"
echo "---------------------------"
echo ""

echo "Do you want to initialize aliyun ? (y/n)"
read -p "(Default: n):" INIT_ALIYUN
if [ -z $INIT_ALIYUN ]; then
	INIT_ALIYUN="n"
fi
echo "---------------------------"
echo "You choose = $INIT_ALIYUN"
echo "---------------------------"
echo ""

echo "Do you want to install xcache ? (y/n)"
read -p "(Default: y):" INSTALL_XC
if [ -z $INSTALL_XC ]; then
	INSTALL_XC="y"
fi
echo "---------------------------"
echo "You choose = $INSTALL_XC"
echo "---------------------------"
echo ""

echo "Do you want to install ioncube ? (y/n)"
read -p "(Default: y):" INSTALL_IONCUBE
if [ -z $INSTALL_IONCUBE ]; then
	INSTALL_IONCUBE="y"
fi
echo "---------------------------"
echo "You choose = $INSTALL_IONCUBE"
echo "---------------------------"
echo ""

echo "Do you want to install Zend Optimizer ? (y/n)"
read -p "(Default: y):" INSTALL_ZEND
if [ -z $INSTALL_ZEND ]; then
	INSTALL_ZEND="y"
fi
echo "---------------------------"
echo "You choose = $INSTALL_ZEND"
echo "---------------------------"
echo ""

get_char()
{
SAVEDSTTY=`stty -g`
stty -echo
stty cbreak
dd if=/dev/tty bs=1 count=1 2> /dev/null
stty -raw
stty echo
stty $SAVEDSTTY
}
echo "Press any key to start install..."
echo "Or Ctrl+C cancel and exit ?"
echo ""
char=`get_char`

echo "---------- Network Check ----------"

ping -c 1 baidu.com &>/dev/null && PING=1 || PING=0

if [ -d "$LANMP_PATH/src" ];then
	\mv $LANMP_PATH/src/* $LANMP_PATH
fi

if [ "$PING" = 0 ];then
	echo "Network Failed!"
	[ ! -s mysql-*.tar.gz ] && exit
else
	echo "Network OK"
fi

echo "---------- Aliyun Initialize ----------"

if [ "$INIT_ALIYUN" = "y" ]; then
	$LANMP_PATH/aliyun_init.sh
fi

echo "---------- Remove Packages ----------"

dpkg -P apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils
dpkg -P mysql-common libmysqlclient15off libmysqlclient15-dev
dpkg -P php

if [ -s /etc/ld.so.conf.d/libc6-xen.conf ]; then
	sed -i 's/hwcap 1 nosegneg/hwcap 0 nosegneg/g' /etc/ld.so.conf.d/libc6-xen.conf
fi

echo "---------- Set Timezone ----------"

rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

apt-get -y install ntpdate
[ "$PING" = 1 ] && ntpdate -d cn.pool.ntp.org

echo "---------- Disable SeLinux ----------"

if [ -s /etc/selinux/config ]; then
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi

echo "---------- Set Library  ----------"

if [ ! `grep -iqw /lib /etc/ld.so.conf` ]; then
	echo "/lib" >> /etc/ld.so.conf
fi

if [ ! `grep -iqw /usr/lib /etc/ld.so.conf` ]; then
	echo "/usr/lib" >> /etc/ld.so.conf
fi

if [ -d "/usr/lib64" ] && [ ! `grep -iqw /usr/lib64 /etc/ld.so.conf` ]; then
	echo "/usr/lib64" >> /etc/ld.so.conf
fi

if [ ! `grep -iqw /usr/local/lib /etc/ld.so.conf` ]; then
	echo "/usr/local/lib" >> /etc/ld.so.conf
fi

ldconfig

echo "---------- Set Environment  ----------"

if [ "$INIT_ALIYUN" != "y" ];then
	cat >>/etc/security/limits.conf<<-EOF
	* soft nproc 65535
	* hard nproc 65535
	* soft nofile 65535
	* hard nofile 65535
	EOF
	ulimit -v unlimited

	cat >>/etc/sysctl.conf<<-EOF
	fs.file-max=65535
	EOF
	sysctl -p
fi

echo "---------- Dependent Packages ----------"

apt-get update
apt-get -y autoremove
apt-get -fy install
apt-get -y --force-yes install make cmake autoconf2.13 gcc g++ libtool build-essential
apt-get -y --force-yes install wget elinks bison unzip tar
apt-get -y --force-yes install openssl libssl0.9 libssl-dev libsasl2-2 libsasl2-dev
apt-get -y --force-yes install zlibc zlib1g zlib1g-dev
apt-get -y --force-yes install libfreetype6 libfreetype6-dev
apt-get -y --force-yes install libxml2 libxml2-dev
apt-get -y --force-yes install libmhash2 libmhash-dev
apt-get -y --force-yes install curl libcurl3 libcurl4-openssl-dev
apt-get -y --force-yes install libxmlrpc-c3 libxmlrpc-c3-dev
apt-get -y --force-yes install libevent-dev
apt-get -y --force-yes install libncurses5 libncurses5-dev
apt-get -y --force-yes install libltdl7 libltdl-dev
apt-get -y --force-yes install libc-client2007e libc-client2007e-dev
apt-get -y autoremove
apt-get -fy install

####################### Extract Function ########################

Extract(){
	local TARBALL_TYPE
	if [ -n $1 ]; then
		SOFTWARE_NAME=`echo $1 | awk -F/ '{print $NF}'`
		TARBALL_TYPE=`echo $1 | awk -F. '{print $NF}'`
		wget -c -t3 -T3 $1 -P $LANMP_PATH/
		if [ $? != "0" ];then
			rm -rf $LANMP_PATH/$SOFTWARE_NAME
			wget -c -t3 -T60 $2 -P $LANMP_PATH/
			SOFTWARE_NAME=`echo $2 | awk -F/ '{print $NF}'`
			TARBALL_TYPE=`echo $2 | awk -F. '{print $NF}'`
		fi
	else
		SOFTWARE_NAME=`echo $2 | awk -F/ '{print $NF}'`
		TARBALL_TYPE=`echo $2 | awk -F. '{print $NF}'`
		wget -c -t3 -T3 $2 -P $LANMP_PATH/ || exit
	fi
	EXTRACTED_DIR=`tar tf $LANMP_PATH/$SOFTWARE_NAME | tail -n 1 | awk -F/ '{print $1}'`
	case $TARBALL_TYPE in
		gz|tgz)
			tar zxf $LANMP_PATH/$SOFTWARE_NAME -C $LANMP_PATH/ && cd $LANMP_PATH/$EXTRACTED_DIR || return 1
		;;
		bz2|tbz)
			tar jxf $LANMP_PATH/$SOFTWARE_NAME -C $LANMP_PATH/ && cd $LANMP_PATH/$EXTRACTED_DIR || return 1
		;;
		tar|Z)
			tar xf $LANMP_PATH/$SOFTWARE_NAME -C $LANMP_PATH/ && cd $LANMP_PATH/$EXTRACTED_DIR || return 1
		;;
		*)
		echo "$SOFTWARE_NAME is wrong tarball type ! "
	esac
}

echo "===================== MySQL Install ===================="

cd $LANMP_PATH
rm -rf /etc/my.cnf /etc/mysql/

groupadd mysql
useradd -g mysql -s /bin/false mysql

if [ ! -s mysql-*.tar.gz ]; then
	LATEST_MYSQL_LINK=`elinks ftp://mirror.csclub.uwaterloo.ca/mysql/Downloads/MySQL-5.6/ | awk '/ftp:.+\.[0-9][0-9][a-z]?\.tar\.gz$/{print $2}' | tail -n 1`
	BACKUP_MYSQL_LINK='http://wangyan.org/download/lanmp-src/mysql-latest.tar.gz'
	Extract ${LATEST_MYSQL_LINK} ${BACKUP_MYSQL_LINK}
else
	tar -zxf mysql-*.tar.gz
	cd mysql-*
fi

cmake . \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_MEMORY_STORAGE_ENGINE=1 \
-DWITH_READLINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DENABLE_DOWNLOADS=0
make install

#cd ../
#cp conf/my.cnf /etc/my.cnf
cp support-files/my-default.cnf /etc/my.cnf

cd /usr/local/mysql
scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --explicit_defaults_for_timestamp
chown -R root:root /usr/local/mysql/.
chown -R mysql /usr/local/mysql/data

cp support-files/mysql.server /etc/init.d/mysql
chmod 755 /etc/init.d/mysql
update-rc.d -f mysql defaults

if [ ! `grep -iqw /usr/local/mysql/lib /etc/ld.so.conf` ]; then
	echo "/usr/local/mysql/lib" >> /etc/ld.so.conf
fi
ldconfig

cd /usr/local/mysql/bin
for i in *; do ln -s /usr/local/mysql/bin/$i /usr/bin/$i; done

/etc/init.d/mysql start
/usr/local/mysql/bin/mysqladmin -u root password $MYSQL_ROOT_PWD

echo "===================== Apache Install ===================="

if [ "$SOFTWARE" != "1" ]; then

	echo "---------- Apache ----------"

	cd $LANMP_PATH/

	if [ ! -s httpd-*.tar.gz ]; then
		LATEST_APACHE_LINK="https://gitcafe.com/wangyan/files/raw/master/httpd-2.2.25.tar.gz"
		BACKUP_APACHE_LINK="http://wangyan.org/download/lanmp-src/httpd-2.2.25.tar.gz"
		Extract ${LATEST_APACHE_LINK} ${BACKUP_APACHE_LINK}
	else
		tar -zxf httpd-*.tar.gz
		cd httpd-*/
	fi

	./configure  --prefix=/usr/local/apache --enable-mods-shared=most --enable-ssl=shared --with-mpm=prefork
	make && make install

	echo "---------- Apache config ----------"

	cd $LANMP_PATH/

	groupadd www
	useradd -g www -s /bin/false www

	for i in `ls /usr/local/apache/bin/`; do ln -s /usr/local/apache/bin/$i /usr/bin/$i; done

	cp conf/init.d.httpd /etc/init.d/httpd
	chmod 755 /etc/init.d/httpd
	update-rc.d -f httpd defaults

	mv /usr/local/apache/conf/httpd.conf /usr/local/apache/conf/httpd.conf.old
	cp conf/httpd.conf /usr/local/apache/conf/httpd.conf
	chmod 644 /usr/local/apache/conf/httpd.conf

	mv /usr/local/apache/conf/extra/httpd-mpm.conf /usr/local/apache/conf/extra/httpd-mpm.conf.bak
	cp conf/httpd-mpm.conf /usr/local/apache/conf/extra/httpd-mpm.conf
	chmod 644 /usr/local/apache/conf/extra/httpd-mpm.conf

	mkdir /usr/local/apache/conf/vhosts
	chmod 711 /usr/local/apache/conf/vhosts
	mkdir -p $WEBROOT
	cp conf/p.php $WEBROOT

	echo "---------- Apache SSL ----------"

	cd $LANMP_PATH/

	mkdir /usr/local/apache/conf/ssl
	chmod 711 /usr/local/apache/conf/ssl
	cp conf/server* /usr/local/apache/conf/ssl
	chmod 644 /usr/local/apache/conf/ssl/*

	mv /usr/local/apache/conf/extra/httpd-ssl.conf /usr/local/apache/conf/extra/httpd-ssl.conf.bak
	cp conf/httpd-ssl.conf /usr/local/apache/conf/extra/httpd-ssl.conf
	chmod 644 /usr/local/apache/conf/extra/httpd-ssl.conf
	sed -i 's,WEBROOT,'$WEBROOT',g' /usr/local/apache/conf/extra/httpd-ssl.conf

	if [ "$SOFTWARE" = "2" ]; then
		sed -i 's,#Include conf/extra/httpd-s,Include conf/extra/httpd-s,g' /usr/local/apache/conf/httpd.conf
	fi

	echo "---------- Apache frontend ----------"

	cd $LANMP_PATH/

	if [ "$SOFTWARE" = "2" ]; then
		sed -i 's/\#Listen 80/Listen 80/g' /usr/local/apache/conf/httpd.conf

		cat >/usr/local/apache/conf/extra/httpd-vhosts.conf<<-EOF
		NameVirtualHost *:80

		<VirtualHost _default_:80>
			ServerAdmin webmaster@example.com
			DocumentRoot "$WEBROOT"
			ServerName 127.0.0.1
			ErrorLog "logs/error_log"
			CustomLog "logs/access_log" combinedio
			<Directory "$WEBROOT">
			    Options +Includes +Indexes
			    php_admin_flag engine ON
			    php_admin_value open_basedir "$WEBROOT:/tmp:/proc"
			</Directory>
		</VirtualHost>

		Include /usr/local/apache/conf/vhosts/*.conf
		EOF
	fi

	echo "---------- Apache backend ----------"

	cd $LANMP_PATH/

	if [ "$SOFTWARE" = "3" ]; then

		echo "---------- RPAF Moudle ----------"

		if [ ! -s mod_rpaf-*.tar.gz ]; then
			LATEST_RPAF_LINK="https://gitcafe.com/wangyan/files/raw/master/mod_rpaf-0.6.tar.gz"
			BACKUP_RPAF_LINK="http://wangyan.org/download/lanmp-src/mod_rpaf-latest.tar.gz"
			Extract ${LATEST_RPAF_LINK} ${BACKUP_RPAF_LINK}
		else
			tar zxf mod_rpaf-*.tar.gz
			cd mod_rpaf-*/
		fi
		/usr/local/apache/bin/apxs -i -c -n mod_rpaf-2.0.so mod_rpaf-2.0.c

		sed -i 's/\#Listen 127/Listen 127/g' /usr/local/apache/conf/httpd.conf
		sed -i 's/\#LoadModule rpaf/LoadModule rpaf/g' /usr/local/apache/conf/httpd.conf

		echo "---------- Backend Config ----------"

		cat >/usr/local/apache/conf/extra/httpd-vhosts.conf<<-EOF
		NameVirtualHost 127.0.0.1:8080

		<VirtualHost 127.0.0.1:8080>
			ServerAdmin webmaster@example.com
			DocumentRoot "$WEBROOT"
			ServerName 127.0.0.1
			ErrorLog "logs/error_log"
			CustomLog "logs/access_log" combinedio
			<Directory "$WEBROOT">
				Options +Includes +Indexes
				php_admin_flag engine ON
				php_admin_value open_basedir "$WEBROOT:/tmp:/proc"
			</Directory>
		</VirtualHost>

		Include /usr/local/apache/conf/vhosts/*.conf
		EOF
	fi
fi

echo "===================== PHP5 Install ===================="

echo "---------- libpng ----------"

cd $LANMP_PATH/

if [ ! -s libpng-*.tar.gz ]; then
	LATEST_LIBPNG_LINK="https://gitcafe.com/wangyan/files/raw/master/libpng-1.6.3.tar.gz"
	BACKUP_LIBPNG_LINK="http://wangyan.org/download/lanmp-src/libpng-latest.tar.gz"
	Extract ${LATEST_LIBPNG_LINK} ${BACKUP_LIBPNG_LINK}
else
	tar -zxf libpng-*.tar.gz
	cd libpng-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- libjpeg ----------"

cd $LANMP_PATH/

if [ ! -s jpegsrc.*.tar.gz ]; then
	LATEST_LIBJPEG_LINK="https://gitcafe.com/wangyan/files/raw/master/jpegsrc.v9.tar.gz"
	BACKUP_LIBJPEG_LINK="http://wangyan.org/download/lanmp-src/jpegsrc.latest.tar.gz"
	Extract ${LATEST_LIBJPEG_LINK} ${BACKUP_LIBJPEG_LINK}
else
	tar -zxf jpegsrc.*.tar.gz
	cd jpeg-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- libiconv ----------"

cd $LANMP_PATH/

if [ ! -s libiconv-*.tar.gz ]; then
	LATEST_LIBICONV_LINK="https://gitcafe.com/wangyan/files/raw/master/libiconv-1.14.tar.gz"
	BACKUP_LIBICONV_LINK="http://wangyan.org/download/lanmp-src/libiconv-latest.tar.gz"
	Extract ${LATEST_LIBICONV_LINK} ${BACKUP_LIBICONV_LINK}
else
	tar -zxf libiconv-*.tar.gz
	cd libiconv-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- libmcrypt ----------"

cd $LANMP_PATH/

if [ ! -s libmcrypt-*.tar.gz ]; then
	LATEST_LIBMCRYPT_LINK="https://gitcafe.com/wangyan/files/raw/master/libmcrypt-2.5.8.tar.gz"
	BACKUP_LIBMCRYPT_LINK="http://wangyan.org/download/lanmp-src/libmcrypt-latest.tar.gz"
	Extract ${LATEST_LIBMCRYPT_LINK} ${BACKUP_LIBMCRYPT_LINK}
else
	tar -zxf libmcrypt-*.tar.gz
	cd libmcrypt-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- mhash ----------"

cd $LANMP_PATH/

if [ ! -s mhash-*.tar.gz ]; then
	LATEST_MHASH_LINK="https://gitcafe.com/wangyan/files/raw/master/mhash-0.9.9.9.tar.gz"
	BACKUP_MHASH_LINK="http://wangyan.org/download/lanmp-src/mhash-latest.tar.gz"
	Extract ${LATEST_MHASH_LINK} ${BACKUP_MHASH_LINK}
else
	tar -zxf mhash-*.tar.gz
	cd mhash-*/
fi
./configure --prefix=/usr/local
make && make install && ldconfig

echo "---------- mcrypt ----------"

cd $LANMP_PATH/

if [ ! -s mcrypt-*.tar.gz ]; then
	LATEST_MCRYPT_LINK="https://gitcafe.com/wangyan/files/raw/master/mcrypt-2.6.8.tar.gz"
	BACKUP_MCRYPT_LINK="http://wangyan.org/download/lanmp-src/mcrypt-latest.tar.gz"
	Extract ${LATEST_MCRYPT_LINK} ${BACKUP_MCRYPT_LINK}
else
	tar -zxf mcrypt-*.tar.gz
	cd mcrypt-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- php5 ----------"

cd $LANMP_PATH/

groupadd www
useradd -g www -s /bin/false www

if [ "$PHP_VER" = "1" ]; then
	if [ ! -s php-5.2.17.tar.gz ]; then
		wget -c -t3 -T3 https://gitcafe.com/wangyan/files/raw/master/php-5.2.17.tar.gz
		if [ $? != "0" ];then
			rm -rf php-5.2.17.tar.gz
			wget -c -t3 -T60 http://wangyan.org/download/lanmp-src/php-5.2.17.tar.gz
		fi
	fi
	tar -zxf php-5.2.17.tar.gz

	if [ ! -s php-5.2.17-fpm-0.5.14.diff.gz ]; then
		wget -c -t3 -T3 https://gitcafe.com/wangyan/files/raw/master/php-5.2.17-fpm-0.5.14.diff.gz
		if [ $? != "0" ];then
			rm -rf php-5.2.17-fpm-0.5.14.diff.gz
			wget -c -t3 -T60 http://wangyan.org/download/lanmp-src/php-5.2.17-fpm-0.5.14.diff.gz
		fi
	fi
	gzip -cd php-5.2.17-fpm-0.5.14.diff.gz | patch -d php-5.2.17 -p1

	if [ ! -s php-5.2.17-max-input-vars.patch ]; then
		wget -c -t3 -T3 https://gitcafe.com/wangyan/files/raw/master/php-5.2.17-max-input-vars.patch
		if [ $? != "0" ];then
			rm -rf php-5.2.17-max-input-vars.patch
			wget -c -t3 -T60 http://wangyan.org/download/lanmp-src/php-5.2.17-max-input-vars.patch
		fi
	fi
	patch -d php-5.2.17 -p1 < php-5.2.17-max-input-vars.patch

	if [ ! -s debian_patches_disable_SSLv2_for_openssl_1_0_0.patch ]; then
		wget -c -t3 -T3 https://gitcafe.com/wangyan/files/raw/master/debian_patches_disable_SSLv2_for_openssl_1_0_0.patch
		if [ $? != "0" ];then
			rm -rf debian_patches_disable_SSLv2_for_openssl_1_0_0.patch
			wget -c -t3 -T60 http://wangyan.org/download/lanmp-src/debian_patches_disable_SSLv2_for_openssl_1_0_0.patch
		fi
	fi
	patch -d php-5.2.17/ext/openssl/ -p3 < debian_patches_disable_SSLv2_for_openssl_1_0_0.patch
	cd php-5.2.17/
else
	if [ ! -s php-5.5.*.tar.gz ]; then
		LATEST_PHP_VERSION=`curl -s http://php.net/downloads.php | awk '/Current Stable/{print $3}'`
		LATEST_PHP_LINK="http://php.net/distributions/php-${LATEST_PHP_VERSION}.tar.gz"
		BACKUP_PHP_LINK="http://wangyan.org/download/lanmp-src/php-latest.tar.gz"
		Extract ${LATEST_PHP_LINK} ${BACKUP_PHP_LINK}
	else
		tar -zxf php-5.5.*.tar.gz
		cd php-5.5.*/
	fi
fi

if [[ "$SOFTWARE" = "1" && "$PHP_VER" = "1" ]]; then
	./buildconf --force
	./configure \
	--prefix=/usr/local/php \
	--with-curl \
	--with-curlwrappers \
	--with-freetype-dir \
	--with-gettext \
	--with-gd \
	--with-iconv-dir \
	--with-jpeg-dir \
	--with-libxml-dir \
	--with-mcrypt \
	--with-mhash \
	--with-mysql=/usr/local/mysql \
	--with-mysqli=/usr/local/mysql/bin/mysql_config \
	--with-mime-magic \
	--with-openssl \
	--with-pear \
	--with-png-dir \
	--with-xmlrpc \
	--with-zlib \
	--enable-bcmath \
	--enable-calendar \
	--enable-discard-path \
	--enable-exif \
	--enable-fastcgi \
	--enable-force-cgi-redirect \
	--enable-fpm \
	--enable-ftp \
	--enable-gd-native-ttf \
	--enable-inline-optimization \
	--enable-magic-quotes \
	--enable-mbregex \
	--enable-mbstring \
	--enable-pcntl \
	--enable-shmop \
	--enable-soap \
	--enable-sockets \
	--enable-sysvsem \
	--enable-sysvshm \
	--enable-xml \
	--enable-zend-multibyte \
	--enable-zip
elif [[ "$SOFTWARE" = "1" && "$PHP_VER" = "2" ]]; then
	./configure \
	--prefix=/usr/local/php \
	--with-curl \
	--with-freetype-dir \
	--with-gettext \
	--with-gd \
	--with-iconv-dir \
	--with-jpeg-dir \
	--with-libxml-dir \
	--with-mcrypt \
	--with-mhash \
	--with-mysql=/usr/local/mysql \
	--with-mysqli=/usr/local/mysql/bin/mysql_config \
	--with-openssl \
	--with-pear \
	--with-png-dir \
	--with-xmlrpc \
	--with-zlib \
	--enable-bcmath \
	--enable-calendar \
	--enable-exif \
	--enable-fpm \
	--enable-ftp \
	--enable-gd-native-ttf \
	--enable-inline-optimization \
	--enable-mbregex \
	--enable-mbstring \
	--enable-pcntl \
	--enable-shmop \
	--enable-soap \
	--enable-sockets \
	--enable-sysvsem \
	--enable-sysvshm \
	--enable-xml \
	--enable-zip
elif [ "$SOFTWARE" != "1" ]; then
	./configure \
	--prefix=/usr/local/php \
	--with-apxs2=/usr/local/apache/bin/apxs \
	--with-curl \
	--with-curlwrappers \
	--with-freetype-dir \
	--with-gettext \
	--with-gd \
	--with-iconv-dir \
	--with-jpeg-dir \
	--with-libxml-dir \
	--with-mcrypt \
	--with-mhash \
	--with-mysql=/usr/local/mysql \
	--with-mysqli=/usr/local/mysql/bin/mysql_config \
	--with-openssl \
	--with-pear \
	--with-png-dir \
	--with-xmlrpc \
	--with-zlib \
	--enable-bcmath \
	--enable-calendar \
	--enable-exif \
	--enable-ftp \
	--enable-gd-native-ttf \
	--enable-inline-optimization \
	--enable-mbregex \
	--enable-mbstring \
	--enable-shmop \
	--enable-soap \
	--enable-sockets \
	--enable-sysvsem \
	--enable-sysvshm \
	--enable-xml \
	--enable-zip
fi

make ZEND_EXTRA_LIBS='-liconv'
make install

echo "---------- PDO MYSQL Extension ----------"

cd ext/pdo_mysql/
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config --with-pdo-mysql=/usr/local/mysql
make && make install

echo "---------- Memcache Extension ----------"

cd $LANMP_PATH/

if [ ! -s memcache-*.tgz ]; then
	LATEST_MEMCACHE_LINK="https://gitcafe.com/wangyan/files/raw/master/memcache-2.2.6.tgz"
	BACKUP_MEMCACHE_LINK="http://wangyan.org/download/lanmp-src/memcache-latest.tgz"
	Extract ${LATEST_MEMCACHE_LINK} ${BACKUP_MEMCACHE_LINK}
else
	tar -zxf memcache-*.tgz
	cd memcache-*/
fi
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config --with-zlib-dir --enable-memcache
make && make install

echo "---------- PHP Config ----------"

cd $LANMP_PATH/

for i in `ls /usr/local/php/bin`; do ln -s /usr/local/php/bin/$i /usr/bin/$i; done

if [ "$PHP_VER" = "1" ];then
	cp php-*/php.ini-recommended /usr/local/php/lib/php.ini
	sed -i 's#extension_dir = "./"#extension_dir = "/usr/local/php/lib/php/extensions/no-debug-non-zts-20060613/"\nextension = "memcache.so"\nextension = "pdo_mysql.so"\n#g' /usr/local/php/lib/php.ini
else
	cp php-*/php.ini-production /usr/local/php/lib/php.ini
	sed -i 's#; extension_dir = "./"#extension_dir = "/usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/"\nextension = "memcache.so"\nextension = "pdo_mysql.so"\n#g' /usr/local/php/lib/php.ini
fi

sed -i 's/short_open_tag = Off/short_open_tag = On/g' /usr/local/php/lib/php.ini
sed -i 's/disable_functions =/disable_functions = system,passthru,exec,shell_exec,popen,symlink,dl/g' /usr/local/php/lib/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /usr/local/php/lib/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 80M/g' /usr/local/php/lib/php.ini
sed -i 's/magic_quotes_gpc = Off/magic_quotes_gpc = On/g' /usr/local/php/lib/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /usr/local/php/lib/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 20M/g' /usr/local/php/lib/php.ini
sed -i 's#;date.timezone =#date.timezone = Asia/Shanghai#g' /usr/local/php/lib/php.ini
sed -i 's#;sendmail_path =#sendmail_path = /usr/sbin/sendmail -t -i#g' /usr/local/php/lib/php.ini

if [[ "$SOFTWARE" = "1" && "$PHP_VER" = "1" ]]; then
	cp conf/init.d.php-fpm /etc/init.d/php-fpm
	chmod 755 /etc/init.d/php-fpm
	update-rc.d -f php-fpm defaults
	cp conf/php-fpm-p2.conf /usr/local/php/etc/php-fpm.conf
	/etc/init.d/php-fpm start
elif [[ "$SOFTWARE" = "1" && "$PHP_VER" = "2" ]]; then
	cp php-5.5.*/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
	chmod 755 /etc/init.d/php-fpm
	update-rc.d -f php-fpm defaults
	cp conf/php-fpm-p4.conf /usr/local/php/etc/php-fpm.conf
	/etc/init.d/php-fpm start
elif [ "$SOFTWARE" != "1" ]; then
	/etc/init.d/httpd start
fi

echo "---------- Xcache Extension ----------"

cd $LANMP_PATH/

if [[ "$INSTALL_XC" = "y" && $PHP_VER = "1" ]];then

	if [ ! -s xcache-*.tar.gz ]; then
		LATEST_XCACHE_LINK="https://gitcafe.com/wangyan/files/raw/master/xcache-3.0.3.tar.gz"
		BACKUP_XCACHE_LINK="http://wangyan.org/download/lanmp-src/xcache-latest.tar.gz"
		Extract ${LATEST_XCACHE_LINK} ${BACKUP_XCACHE_LINK}
	else
		tar zxf xcache-*.tar.gz
		cd xcache-*/
	fi
	/usr/local/php/bin/phpize
	./configure --enable-xcache --enable-xcache-optimizer --enable-xcache-coverager
	make && make install

	mkdir -p $WEBROOT/
	cp -r admin/ $WEBROOT/xcache
	chmod -R 755 $WEBROOT/xcache

	mkdir /tmp/{pcov,phpcore}
	chown www:www /tmp/{pcov,phpcore}
	chmod 700 /tmp/{pcov,phpcore}

	if [ "$PHP_VER" = "1" ]; then
		cat >>/usr/local/php/lib/php.ini<<-EOF
		[xcache-common]
		zend_extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20060613/xcache.so
		EOF
	else
		cat >>/usr/local/php/lib/php.ini<<-EOF
		[xcache-common]
		zend_extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/xcache.so
		EOF
	fi
	cat >>/usr/local/php/lib/php.ini<<-EOF

	[xcache.admin]
	xcache.admin.user = admin
	xcache.admin.pass = e10adc3949ba59abbe56e057f20f883e
	xcache.admin.enable_auth = On
	xcache.test = Off
	xcache.coredump_directory = /tmp/phpcore
	xcache.disable_on_crash = ""

	[xcache]
	xcache.cacher = On
	xcache.size = 64M
	xcache.count = 4
	xcache.slots = 8K
	xcache.ttl = 3600
	xcache.gc_interval = 60
	xcache.var_size = 1M
	xcache.var_count = 4
	xcache.var_slots = 8K
	xcache.var_ttl = 3600
	xcache.var_maxttl = 0
	xcache.var_gc_interval = 60
	xcache.readonly_protection = Off
	xcache.mmap_path = /dev/zero

	[xcache.optimizer]
	xcache.optimizer = On

	[xcache.coverager]
	xcache.coverager = On
	xcache.coveragedump_directory = /tmp/pcov

	EOF
elif [[ "$INSTALL_XC" = "y" && $PHP_VER = "2" ]]; then
	cat >>/usr/local/php/lib/php.ini<<-EOF

	[opcache]
	zend_extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/opcache.so
	opcache.enable_cli=1
	opcache.memory_consumption=128
	opcache.interned_strings_buffer=8
	opcache.max_accelerated_files=4000
	opcache.revalidate_freq=1
	opcache.fast_shutdown=1

	EOF
fi

echo "---------- Ioncube Extension ----------"

cd $LANMP_PATH/

if [[ "$INSTALL_IONCUBE" = "y" && $PHP_VER = "1" ]];then
	if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
		if [ ! -s ioncube_loaders_lin_x86-64.tar.gz ]; then
			LATEST_IONCUBE_LINK="https://gitcafe.com/wangyan/files/raw/master/ioncube_loaders_lin_x86-64.tar.gz"
			BACKUP_IONCUBE_LINK="http://wangyan.org/download/lanmp-src/ioncube_loaders_lin_x86-64.tar.gz"
			Extract ${LATEST_IONCUBE_LINK} ${BACKUP_IONCUBE_LINK}
		else
			tar -zxf ioncube_loaders_lin_x86-64.tar.gz
			cd ioncube/
		fi
	else
		if [ ! -s ioncube_loaders_lin_x86.tar.gz ]; then
			LATEST_IONCUBE_LINK="https://gitcafe.com/wangyan/files/raw/master/ioncube_loaders_lin_x86.tar.gz"
			BACKUP_IONCUBE_LINK="http://wangyan.org/download/lanmp-src/ioncube_loaders_lin_x86.tar.gz"
			Extract ${LATEST_IONCUBE_LINK} ${BACKUP_IONCUBE_LINK}
		else
			tar -zxf ioncube_loaders_lin_x86.tar.gz
			cd ioncube/
		fi
	fi

	mkdir -p /usr/local/zend/
	if [ "$PHP_VER" = "1" ]; then
		cp ioncube_loader_lin_5.2.so /usr/local/zend/
		cat >>/usr/local/php/lib/php.ini<<-EOF
		[ioncube loader]
		zend_extension = /usr/local/zend/ioncube_loader_lin_5.2.so
		EOF
	else
		cp ioncube_loader_lin_5.4.so /usr/local/zend/
		cat >>/usr/local/php/lib/php.ini<<-EOF
		[ioncube loader]
		zend_extension = /usr/local/zend/ioncube_loader_lin_5.4.so
		EOF
	fi
fi

echo "---------- ZendOptimizer Extension ----------"

cd $LANMP_PATH/

if [ "$INSTALL_ZEND" = "y" ];then

	if [ "$PHP_VER" = "1" ]; then
		if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
			if [ ! -s ZendOptimizer-*-linux-glibc23-x86_64.tar.gz ]; then
				LATEST_ZEND_LINK="https://gitcafe.com/wangyan/files/raw/master/ZendOptimizer-3.3.9-linux-glibc23-x86_64.tar.gz"
				BACKUP_ZEND_LINK="http://wangyan.org/download/lanmp-src/ZendOptimizer-latest-linux-glibc23-x86_64.tar.gz"
				Extract ${LATEST_ZEND_LINK} ${BACKUP_ZEND_LINK}
			else
				tar zxf ZendOptimizer-*-linux-glibc23-x86_64.tar.gz
				cd ZendOptimizer-*-linux-glibc23-x86_64/
			fi
		else
			if [ ! -s ZendOptimizer-*-linux-glibc23-i386.tar.gz ]; then
				LATEST_ZEND_LINK="https://gitcafe.com/wangyan/files/raw/master/ZendOptimizer-3.3.9-linux-glibc23-i386.tar.gz"
				BACKUP_ZEND_LINK="http://wangyan.org/download/lanmp-src/ZendOptimizer-latest-linux-glibc23-i386.tar.gz"
				Extract ${LATEST_ZEND_LINK} ${BACKUP_ZEND_LINK}
			else
				tar zxf ZendOptimizer-*-linux-glibc23-i386.tar.gz
				cd ZendOptimizer-*-linux-glibc23-i386/
			fi
		fi
		mkdir -p /usr/local/zend/
		cp data/5_2_x_comp/ZendOptimizer.so /usr/local/zend/
		cat >>/usr/local/php/lib/php.ini<<-EOF

		[Zend Optimizer]
		zend_extension = /usr/local/zend/ZendOptimizer.so
		zend_loader.enable = 1
		EOF
	else
		if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
			if [ ! -s ZendGuardLoader-*-linux-glibc23-x86_64.tar.gz ]; then
				LATEST_GUARD_LINK="https://gitcafe.com/wangyan/files/raw/master/ZendGuardLoader-70429-PHP-5.4-linux-glibc23-x86_64.tar.gz"
				BACKUP_GUARD_LINK="http://wangyan.org/download/lanmp-src/ZendGuardLoader-70429-PHP-5.4-linux-glibc23-x86_64.tar.gz"
				Extract ${LATEST_GUARD_LINK} ${BACKUP_GUARD_LINK}
			else
				tar -zxf ZendGuardLoader-*-linux-glibc23-x86_64.tar.gz
				cd ZendGuardLoader-*-linux-glibc23-x86_64/
			fi
		else
			if [ ! -s ZendGuardLoader-*-linux-glibc23-i386.tar.gz ]; then
				LATEST_GUARD_LINK="https://gitcafe.com/wangyan/files/raw/master/ZendGuardLoader-70429-PHP-5.4-linux-glibc23-i386.tar.gz"
				BACKUP_GUARD_LINK="http://wangyan.org/download/lanmp-src/ZendGuardLoader-70429-PHP-5.4-linux-glibc23-i386.tar.gz"
				Extract ${LATEST_GUARD_LINK} ${BACKUP_GUARD_LINK}
			else
				tar -zxf ZendGuardLoader-*-linux-glibc23-i386.tar.gz
				cd ZendGuardLoader-*-linux-glibc23-i386/
			fi
		fi
		mkdir -p /usr/local/zend/
		cp php-5.4.x/ZendGuardLoader.so /usr/local/zend/
		cat >>/usr/local/php/lib/php.ini<<-EOF

		[Zend GuardLoader]
		zend_extension = /usr/local/zend/ZendGuardLoader.so
		zend_loader.enable = 1
		EOF
	fi
fi

if [ "$SOFTWARE" = "1" ]; then
	/etc/init.d/php-fpm restart
else
	/usr/local/apache/bin/httpd -k restart
fi

echo "===================== Nginx Install ===================="

if [ "$SOFTWARE" != "2" ]; then

	groupadd www
	useradd -g www -s /bin/false www

	echo "---------- Pcre ----------"

	cd $LANMP_PATH/

	if [ ! -s pcre-*.tar.gz ]; then
		LATEST_PCRE_LINK="https://gitcafe.com/wangyan/files/raw/master/pcre-8.33.tar.gz"
		BACKUP_PCRE_LINK="http://wangyan.org/download/lanmp-src/pcre-latest.tar.gz"
		Extract ${LATEST_PCRE_LINK} ${BACKUP_PCRE_LINK}
	else
		tar -zxf pcre-*.tar.gz
		cd pcre-*/
	fi
	./configure
	make && make install && ldconfig

	echo "---------- Nginx ----------"

	cd $LANMP_PATH/
	mkdir -p /var/tmp/nginx

	if [ ! -s nginx-*.tar.gz ]; then
		LATEST_NGINX_VERSION=`curl -s http://nginx.org/| awk -F- '/nginx-/{print $6}' | head -1|cut -d '<' -f 1`
		LATEST_NGINX_LINK="http://nginx.org/download/nginx-${LATEST_NGINX_VERSION}.tar.gz"
		BACKUP_NGINX_LINK="http://wangyan.org/download/lanmp-src/nginx-latest.tar.gz"
		Extract ${LATEST_NGINX_LINK} ${BACKUP_NGINX_LINK}
	else
		tar -zxf nginx-*.tar.gz
		cd nginx-*/
	fi

	./configure \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/lock/nginx.lock \
	--user=www \
	--group=www \
	--with-http_ssl_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_realip_module \
	--with-http_gzip_static_module \
	--with-http_stub_status_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-pcre \
	--with-debug \
	--with-ipv6 \
	--http-client-body-temp-path=/var/tmp/nginx/client \
	--http-proxy-temp-path=/var/tmp/nginx/proxy \
	--http-fastcgi-temp-path=/var/tmp/nginx/fastcgi \
	--http-uwsgi-temp-path=/var/tmp/nginx/uwsgi \
	--http-scgi-temp-path=/var/tmp/nginx/scgi
	make && make install

	echo "---------- Nginx Config----------"

	cd $LANMP_PATH/
	mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak
	cp conf/nginx.conf /usr/local/nginx/conf/nginx.conf
	chmod 644 /usr/local/nginx/conf/nginx.conf

	mkdir /usr/local/nginx/conf/ssl
	chmod 711 /usr/local/nginx/conf/ssl
	cp conf/server* /usr/local/nginx/conf/ssl/
	chmod 644 /usr/local/nginx/conf/ssl/*

	mkdir /usr/local/nginx/conf/vhosts
	chmod 711 /usr/local/nginx/conf/vhosts
	mkdir /usr/local/nginx/logs/localhost

	if [ "$SOFTWARE" = "1" ]; then
		cp conf/nginx-vhost-original.conf /usr/local/nginx/conf/vhosts/localhost.conf
	else
		cp conf/nginx-vhost-localhost.conf /usr/local/nginx/conf/vhosts/localhost.conf
		cp conf/proxy_cache.inc /usr/local/nginx/conf/proxy_cache.inc
	fi
	chmod 644 /usr/local/nginx/conf/vhosts/localhost.conf
	sed -i 's,www.DOMAIN,,g' /usr/local/nginx/conf/vhosts/localhost.conf
	sed -i 's,DOMAIN/,localhost/,g' /usr/local/nginx/conf/vhosts/localhost.conf
	sed -i 's,DOMAIN,'$IP_ADDRESS',g' /usr/local/nginx/conf/vhosts/localhost.conf
	sed -i 's,ROOTDIR,'$WEBROOT',g' /usr/local/nginx/conf/vhosts/localhost.conf

	if [ ! -d $WEBROOT ]; then
		mkdir -p $WEBROOT
	fi
	\cp conf/p.php $WEBROOT

	cp conf/init.d.nginx /etc/init.d/nginx
	chmod 755 /etc/init.d/nginx
	update-rc.d -f nginx defaults

	ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx
	/etc/init.d/nginx stop
	/etc/init.d/nginx start
fi

echo "================phpMyAdmin Install==============="

cd $LANMP_PATH/
/etc/init.d/mysql restart

if [ ! -s phpMyAdmin-*-all-languages.tar.gz ]; then
	PMA_VERSION=`elinks http://nchc.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/ | awk -F/ '{print $7F}' | sort -n | grep -iv '-' | tail -1`
	PMA_LINK="http://nchc.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/"
	LATEST_PMA_LINK="${PMA_LINK}${PMA_VERSION}/phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz"
	BACKUP_PMA_LINK="http://wangyan.org/download/lanmp-src/phpMyAdmin-latest-all-languages.tar.gz"
	Extract ${LATEST_PMA_LINK} ${BACKUP_PMA_LINK}
	mkdir -p $WEBROOT/phpmyadmin
	mv * $WEBROOT/phpmyadmin
else
	PMA_VERSION=`ls phpMyAdmin-*-all-languages.tar.gz | awk -F- '{print $2}'`
	tar -zxf phpMyAdmin-*-all-languages.tar.gz -C $WEBROOT
	mv $WEBROOT/phpMyAdmin-*-all-languages $WEBROOT/phpmyadmin
fi

cd $LANMP_PATH/
cp conf/config.inc.php $WEBROOT/phpmyadmin/config.inc.php
sed -i 's/PMAPWD/'$PMAPWD'/g' $WEBROOT/phpmyadmin/config.inc.php

cp conf/control_user.sql /tmp/control_user.sql
sed -i 's/PMAPWD/'$PMAPWD'/g' /tmp/control_user.sql
/usr/local/mysql/bin/mysql -u root -p$MYSQL_ROOT_PWD -h localhost < /tmp/control_user.sql

if [ -s $WEBROOT/phpmyadmin/scripts/create_tables.sql ]; then
	cp $WEBROOT/phpmyadmin/scripts/create_tables.sql /tmp/create_tables.sql
else
	cp $WEBROOT/phpmyadmin/examples/create_tables.sql /tmp/create_tables.sql
	sed -i 's/pma__/pma_/g' $WEBROOT/phpmyadmin/examples/create_tables.sql
fi

/usr/local/mysql/bin/mysql -u root -p$MYSQL_ROOT_PWD -h localhost < $WEBROOT/phpmyadmin/examples/create_tables.sql

rm -rf /usr/local/mysql/data/test/

echo -e "phpmyadmin\t${PMA_VERSION}" >> version.txt 2>&1

if [ ! -d "src/" ];then
	mkdir -p src/
fi
\mv ./{*gz,*-*/,*patch,ioncube,package.xml} ./src >/dev/null 2>&1

clear
echo ""
echo "===================== Install completed ====================="
echo ""
echo "LANMP install completed!"
echo "For more information please visit http://wangyan.org/blog/lanmp.html"
echo ""
echo "Server ip address: $IP_ADDRESS"
echo "MySQL root password: $MYSQL_ROOT_PWD"
echo "MySQL pma password: $PMAPWD"
echo ""
echo "php config file at: /usr/local/php/lib/php.ini"
echo "Pear config file at: /usr/local/php/etc/pear.conf"
[ "$SOFTWARE" = "1" ] && echo "php-fpm config file at: /usr/local/php/etc/php-fpm.conf"
[ "$SOFTWARE" != "2" ] && echo "nginx config file at: /usr/local/nginx/conf/nginx.conf"
[ "$SOFTWARE" != "1" ] && echo "httpd config file at: /usr/local/apache/conf/httpd.conf"
echo ""
echo "WWW root dir: $WEBROOT"
echo "PHP prober: http://$IP_ADDRESS/p.php"
echo "phpMyAdmin: http://$IP_ADDRESS/phpmyadmin/"
echo ""
echo "============================================================="
echo ""
