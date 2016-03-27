#!/bin/bash
# Program:
#       This program is install ceph-radosgw on your server.
# History:
# 2015/12/19 Kyle.b Release

wget -q -O- https://raw.github.com/ceph/ceph/master/keys/autobuild.asc | sudo apt-key add -
echo deb http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-$(lsb_release -sc)-x86_64-basic/ref/master $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph-fastcgi.list
HOSTNAME=$(hostname)

sudo apt-get update
sudo apt-get install apache2 libapache2-mod-fastcgi radosgw -y

sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.radosgw.${HOSTNAME}.keyring

sudo chmod +r /etc/ceph/ceph.client.radosgw.${HOSTNAME}.keyring
sudo ceph-authtool /etc/ceph/ceph.client.radosgw.${HOSTNAME}.keyring -n client.radosgw.${HOSTNAME} --gen-key
sudo ceph-authtool -n client.radosgw.${HOSTNAME} --cap osd 'allow rwx' --cap mon 'allow rwx' /etc/ceph/ceph.client.radosgw.${HOSTNAME}.keyring
sudo ceph -k /etc/ceph/ceph.client.admin.keyring auth add client.radosgw.${HOSTNAME} -i /etc/ceph/ceph.client.radosgw.${HOSTNAME}.keyring

echo -n "
[client.radosgw.${HOSTNAME}]
host = ${HOSTNAME}
keyring = /etc/ceph/ceph.client.radosgw.${HOSTNAME}.keyring
rgw socket path = /tmp/radosgw.sock
log file = /var/log/ceph/radosgw.${HOSTNAME}.log
rgw dns name = ${HOSTNAME}
" | sudo tee -a /etc/ceph/ceph.conf

echo -n "#!/bin/sh
exec /usr/bin/radosgw -c /etc/ceph/ceph.conf -n client.radosgw.${HOSTNAME}" | sudo tee -a /var/www/s3gw.fcgi

sudo chmod +x /var/www/s3gw.fcgi

echo -n "FastCgiExternalServer /var/www/s3gw.fcgi -socket /tmp/radosgw.sock

<VirtualHost *:8080>
        ServerName ${HOSTNAME}
        DocumentRoot /var/www
        RewriteEngine On
        RewriteRule  ^/(.*) /s3gw.fcgi?%{QUERY_STRING} [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]

        <IfModule mod_fastcgi.c>
        <Directory /var/www>
                        Options +ExecCGI
                        AllowOverride All
                        SetHandler fastcgi-script
                        Order allow,deny
                        Allow from all
                        AuthBasicAuthoritative Off
        </Directory>
        </IfModule>

        AllowEncodedSlashes On
        ErrorLog /var/log/apache2/error.log
        CustomLog /var/log/apache2/access.log combined
        ServerSignature Off
</VirtualHost>
" | sudo tee /etc/apache2/sites-available/rgw.conf

sudo a2enmod rewrite
sudo a2enmod fastcgi
sudo a2ensite rgw.conf
sudo a2dissite default
sudo service ceph restart
sudo service apache2 restart
sudo /etc/init.d/radosgw start
