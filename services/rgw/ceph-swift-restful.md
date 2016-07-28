# Ceph Swift RESTful
首先在```Controller```或```Swift Node```上安裝 Ceph：
```sh
$ ceph-deploy install <node>
```
> ```ceph-deploy``` 可以用```pip install ceph-deploy```安裝。:

### 手動安裝 radosgw
首先安裝 Ceph radosgw 與 apache2 相關套件：
```sh
$ wget -q -O- https://raw.github.com/ceph/ceph/master/keys/autobuild.asc | sudo apt-key add -
$ echo deb http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-$(lsb_release -sc)-x86_64-basic/ref/master $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph-fastcgi.list
$ sudo apt-get install apache2 libapache2-mod-fastcgi radosgw -y
```

建立一個 radosgw 認證金鑰：
```sh
$ HOSTNAME=$(hostname)
$ sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.radosgw.${HOSTNAME}.keyring
```
設定該認證的權限：
```sh
$ sudo chmod +r /etc/ceph/ceph.client.radosgw.${HOSTNAME}.keyring
$ sudo ceph-authtool /etc/ceph/ceph.client.radosgw.${HOSTNAME}.keyring -n client.radosgw.${HOSTNAME} --gen-key
$ sudo ceph-authtool -n client.radosgw.${HOSTNAME} --cap osd 'allow rwx' --cap mon 'allow rwx' /etc/ceph/ceph.client.radosgw.${HOSTNAME}.keyring
$ sudo ceph -k /etc/ceph/ceph.client.admin.keyring auth add client.radosgw.${HOSTNAME} -i /etc/ceph/ceph.client.radosgw.${HOSTNAME}.keyring
```
新增以下內容到```/etc/ceph/ceph.conf```檔案：
```sh
$ echo -n "
[client.radosgw.${HOSTNAME}]
host = ${HOSTNAME}
keyring = /etc/ceph/ceph.client.radosgw.${HOSTNAME}.keyring
rgw socket path = /tmp/radosgw.sock
log file = /var/log/ceph/radosgw.${HOSTNAME}.log
rgw dns name = ${HOSTNAME}
" | sudo tee -a /etc/ceph/ceph.conf
```
建立 fcgi 檔案，並設定檔案權限：
```sh
$ echo -n "#!/bin/sh
exec /usr/bin/radosgw -c /etc/ceph/ceph.conf -n client.radosgw.${HOSTNAME}" | sudo tee -a /var/www/s3gw.fcgi
$ sudo chmod +x /var/www/s3gw.fcgi
```

建立一個 apache2 檔案，```/etc/apache2/sites-available/rgw.conf```，並加入以下內容：
```sh
$ echo -n "FastCgiExternalServer /var/www/s3gw.fcgi -socket /tmp/radosgw.sock

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
```
使用 apache2 模組：
```sh
$ sudo a2enmod rewrite
$ sudo a2enmod fastcgi
```
使用 rgw 虛擬主機設定檔：
```sh
$ sudo a2ensite rgw.conf
$ sudo a2dissite default
```
重新啟動相關服務：
```sh
$ sudo service ceph restart
$ sudo service apache2 restart
$ sudo /etc/init.d/radosgw start
```
設定 Boot 時啟動：
```sh
$ sudo update-rc.d radosgw defaults
```

> Keystone 整合可參考 Keystone 安裝。

### 建立  pool
 ```sh
ceph osd pool create {pool-name} {pg-num} [{pgp-num}] [replicated] \
     [crush-ruleset-name] [expected-num-objects]
```
 * rgw.root   
 * rgw.control
 * rgw
 * rgw.gc
 * users.uid
 * users
 * users.email
 * users.swift          
 * rgw.buckets.index     
 * rgw.buckets
 
> 可以參考 [PG Calc](http://ceph.com/pgcalc/) 的 PG Number，並產生指令。

### 使用 cph-deploy 建立 radosgw 與 pool
```sh
ceph-deploy install <host>
ceph-deploy rgw create <host>:rgw1
```

### 基本指令使用
建立使用者（如果有出現特殊字元就刪除再重建使用者，刪除指令參考下一項）
```sh
radosgw-admin user create \
--uid=test.s3 \
--display-name="test.s3" \
--email=test.s3@gmail.com
```

刪除使用者的指令：
```sh
radosgw-admin user rm --uid=yangbx
```

建立subuser，建完請確認要有紅字的內容，沒有subuser，swift client無法連線
```sh
radosgw-admin subuser create --uid=yangbx --subuser=yangbx:swift --access=full
```

產生secret-key(如果有secret有特殊字元就重複執行產生key的指令)
```sh
radosgw-admin key create --gen-secret --subuser=yangbx:swift --key-type=swift
```

Status
```sh
swift -v -A http://10.0.0.11:8080/auth/v1.0 \
-U yangbx:swift \
--key='p4TBc3beiyNayNdPJ7YLq2xpzXQFMpapZI9BdPdC' \
stat

```

Create bucket
```sh
swift -V 1.0 -A http://10.0.0.11:7480/auth \
-U melon:swift \
-K 1kMJX5j6Um4DJ7FLMeqwtgdBVOVBe0WWx6xTLHHX \
post melon-buc

```

List Containers
```sh
swift -V 1.0 -A http://10.0.0.11:7480/auth \
-U melon:swift -K 1kMJX5j6Um4DJ7FLMeqwtgdBVOVBe0WWx6xTLHHX \
list
```

Upload file
```sh
swift -V 1.0 -A http://10.0.0.11:7480/auth -U melon:swift -K 1kMJX5j6Um4DJ7FLMeqwtgdBVOVBe0WWx6xTLHHX upload melon-buc cirr.img
```

List bucket files
```sh
swift -V 1.0 -A http://10.0.0.11:7480/auth -U melon:swift -K 1kMJX5j6Um4DJ7FLMeqwtgdBVOVBe0WWx6xTLHHX list melon-buc
```

Delete files
```
swift -V 1.0 -A http://10.0.0.11:7480/auth -U melon:swift -K 1kMJX5j6Um4DJ7FLMeqwtgdBVOVBe0WWx6xTLHHX delete melen-buc cirr.img
```