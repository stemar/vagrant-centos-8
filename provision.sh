timedatectl set-timezone $TIMEZONE

echo '==> Setting '$(timedatectl | grep 'Time zone:' | xargs)

echo '==> Setting Centos 8 yum repositories'

sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-Linux-*
sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.epel.cloud|g' /etc/yum.repos.d/CentOS-Linux-*

echo '==> Resetting dnf cache'

dnf -q -y clean all
rm -rf /var/cache/dnf
dnf -q -y makecache

echo '==> Installing Linux tools'

cp /vagrant/config/bashrc /home/vagrant/.bashrc
chown vagrant:vagrant /home/vagrant/.bashrc
dnf -q -y install nano tree zip unzip whois

echo '==> Installing Git and Subversion'

dnf -q -y install git svn

echo '==> Installing Apache'

dnf -q -y install httpd mod_ssl openssl
usermod -a -G apache vagrant
chown -R root:apache /var/log/httpd
cp /vagrant/config/localhost.conf /etc/httpd/conf.d/localhost.conf
cp /vagrant/config/virtualhost.conf /etc/httpd/conf.d/virtualhost.conf
sed -i 's|GUEST_SYNCED_FOLDER|'$GUEST_SYNCED_FOLDER'|' /etc/httpd/conf.d/virtualhost.conf
sed -i 's|FORWARDED_PORT_80|'$FORWARDED_PORT_80'|' /etc/httpd/conf.d/virtualhost.conf

echo '==> Fixing localhost SSL certificate'

if [ ! -f /etc/pki/tls/certs/localhost.crt ]; then
    cp /vagrant/config/localhost.crt /etc/pki/tls/certs/localhost.crt
    chmod u=rw /etc/pki/tls/certs/localhost.crt
fi
if [ ! -f /etc/pki/tls/private/localhost.key ]; then
    cp /vagrant/config/localhost.key /etc/pki/tls/private/localhost.key
    chmod u=rw /etc/pki/tls/private/localhost.key
fi

echo '==> Setting MariaDB 10.6 repository'

rpm --import --quiet https://mirror.rackspace.com/mariadb/yum/RPM-GPG-KEY-MariaDB
cp /vagrant/config/MariaDB.repo /etc/yum.repos.d/MariaDB.repo

echo '==> Installing MariaDB'

dnf -q -y install mariadb-server

echo '==> Setting PHP 7.4 repository'

{
    rpm --import --quiet https://archive.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8
    dnf -q -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    rpm --import --quiet https://rpms.remirepo.net/RPM-GPG-KEY-remi
    dnf -q -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
    dnf -q -y module enable php:remi-7.4
} &>/dev/null

echo '==> Installing PHP'

dnf -q -y install php php-cli php-common \
    php-bcmath php-devel php-gd php-intl php-ldap php-mcrypt php-mysqlnd \
    php-pear php-soap php-xdebug php-xmlrpc
cp /etc/httpd/conf.modules.d/00-mpm.conf /etc/httpd/conf.modules.d/00-mpm.conf~
cp /vagrant/config/00-mpm.conf /etc/httpd/conf.modules.d/00-mpm.conf
cp /vagrant/config/php.ini.htaccess /var/www/.htaccess
PHP_ERROR_REPORTING_INT=$(php -r 'echo '"$PHP_ERROR_REPORTING"';')
sed -i 's|PHP_ERROR_REPORTING_INT|'$PHP_ERROR_REPORTING_INT'|' /var/www/.htaccess

echo '==> Installing Adminer'

if [ ! -d /usr/share/adminer ]; then
    mkdir -p /usr/share/adminer
    curl -LsS https://www.adminer.org/latest-en.php -o /usr/share/adminer/adminer.php
    sed -i 's|{if($F=="")return|{if(true)|' /usr/share/adminer/adminer.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/designs/nicu/adminer.css -o /usr/share/adminer/adminer.css
fi
cp /vagrant/config/adminer.conf /etc/httpd/conf.d/adminer.conf
sed -i 's|FORWARDED_PORT_80|'$FORWARDED_PORT_80'|' /etc/httpd/conf.d/adminer.conf

echo '==> Installing Python'

dnf -q -y install python2 python3

echo '==> Testing Apache configuration'

if [ ! -L /etc/systemd/system/multi-user.target.wants/httpd.service ] ; then
    ln -s /usr/lib/systemd/system/httpd.service /etc/systemd/system/multi-user.target.wants/httpd.service
fi
apachectl configtest

echo '==> Starting Apache'

systemctl restart httpd
systemctl enable httpd

echo '==> Starting MariaDB'

if [ ! -L /etc/systemd/system/multi-user.target.wants/mariadb.service ] ; then
    ln -s /usr/lib/systemd/system/mariadb.service /etc/systemd/system/multi-user.target.wants/mariadb.service
fi
systemctl restart mariadb
systemctl enable mariadb
mysqladmin -u root password ""

echo '==> Versions:'

cat /etc/redhat-release
openssl version
curl --version | head -n1 | cut -d '(' -f 1
svn --version | grep svn,
git --version
httpd -V | head -n1 | cut -d ' ' -f 3-
mysql -V
php -v | head -n1
python2 --version &>/dev/stdout
python3 --version
