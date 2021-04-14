echo '==> Setting time zone'

timedatectl set-timezone Canada/Pacific
timedatectl | grep 'Time zone:'

echo '==> Cleaning yum cache'

dnf -q -y makecache
rm -rf /var/cache/yum

echo '==> Installing Linux tools'

cp $VM_CONFIG_PATH/bashrc /home/vagrant/.bashrc
chown vagrant:vagrant /home/vagrant/.bashrc
dnf -q -y install nano tree zip unzip whois

echo '==> Installing Subversion and Git'

dnf -q -y install svn git

echo '==> Installing Apache'

dnf -q -y install httpd mod_ssl openssl
usermod -a -G apache vagrant
chown -R root:apache /var/log/httpd
cp $VM_CONFIG_PATH/localhost.conf /etc/httpd/conf.d/localhost.conf
cp $VM_CONFIG_PATH/virtualhost.conf /etc/httpd/conf.d/virtualhost.conf
sed -i 's|GUEST_SYNCED_FOLDER|'$GUEST_SYNCED_FOLDER'|' /etc/httpd/conf.d/virtualhost.conf
sed -i 's|FORWARDED_PORT_80|'$FORWARDED_PORT_80'|' /etc/httpd/conf.d/virtualhost.conf

echo '==> Fixing localhost SSL certificate'

cp $VM_CONFIG_PATH/localhost.crt /etc/pki/tls/certs/localhost.crt
cp $VM_CONFIG_PATH/localhost.key /etc/pki/tls/private/localhost.key
chmod u=rw /etc/pki/tls/certs/localhost.crt
chmod u=rw /etc/pki/tls/private/localhost.key

echo '==> Setting MariaDB 10.5 repository'

rpm --import --quiet https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
cp $VM_CONFIG_PATH/MariaDB.repo /etc/yum.repos.d/MariaDB.repo

echo '==> Installing MariaDB'

dnf -q -y install mariadb-server

echo '==> Setting PHP 7.4 repository'

rpm --import --quiet https://archive.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8
dnf -q -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
rpm --import --quiet https://rpms.remirepo.net/RPM-GPG-KEY-remi2018
dnf -q -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf -q -y module enable php:remi-7.4

echo '==> Installing PHP'

dnf -q -y install php php-cli php-common \
    php-bcmath php-devel php-gd php-intl php-ldap php-mcrypt php-mysqlnd \
    php-pear php-soap php-xdebug php-xmlrpc
cp $VM_CONFIG_PATH/php.ini.htaccess /var/www/.htaccess
cp /etc/httpd/conf.modules.d/00-mpm.conf /etc/httpd/conf.modules.d/00-mpm.conf~
cp $VM_CONFIG_PATH/00-mpm.conf /etc/httpd/conf.modules.d/00-mpm.conf

echo '==> Installing Python'

dnf -q -y install python2 python3

echo '==> Installing Adminer'

if [ ! -d /usr/share/adminer ]; then
    mkdir -p /usr/share/adminer
    curl -LsS https://www.adminer.org/latest-en.php -o /usr/share/adminer/adminer.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/designs/nicu/adminer.css -o /usr/share/adminer/adminer.css
fi
cp $VM_CONFIG_PATH/adminer.conf /etc/httpd/conf.d/adminer.conf
sed -i 's|FORWARDED_PORT_80|'$FORWARDED_PORT_80'|' /etc/httpd/conf.d/adminer.conf
sed -i 's|login($we,$F){if($F=="")return|login($we,$F){if(true)|' /usr/share/adminer/adminer.php

echo '==> Starting Apache'
ln -s /usr/lib/systemd/system/httpd.service /etc/systemd/system/multi-user.target.wants/httpd.service
apachectl configtest
systemctl start httpd
systemctl enable httpd

echo '==> Starting MariaDB'

ln -s /usr/lib/systemd/system/mariadb.service /etc/systemd/system/multi-user.target.wants/mariadb.service
systemctl start mariadb
systemctl enable mariadb
mysqladmin -u root password ""

echo '==> Versions:'

cat /etc/redhat-release
echo $(openssl version)
echo $(curl --version | head -n1)
echo $(svn --version | grep svn,)
echo $(git --version)
echo $(httpd -V | head -n1)
echo $(mysql -V)
echo $(php -v | head -n1)
echo $(python2 --version)
echo $(python3 --version)
