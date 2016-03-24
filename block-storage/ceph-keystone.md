# Ceph 與 Keystone 整合
在 ```controller``` (keystone api 所在主機）執行下面指令，並將 controller 的 /var/ceph/nss 內的檔案(cert8.db  key3.db  secmod.db)複製到 radosgw 主機的 /var/ceph/nss 目錄：
```sh
$ sudo mkdir -p /var/ceph/nss
$ openssl x509 -in /etc/keystone/ssl/certs/ca.pem -pubkey | \
certutil -d /var/ceph/nss -A -n ca -t "TCu,Cu,Tuw"
        
$ openssl x509 -in /etc/keystone/ssl/certs/signing_cert.pem -pubkey | \
certutil -A -d /var/ceph/nss -n signing_cert -t "P,P,P"
```

在能執行 keystone 指令的任意電腦，執行以下指令：
```sh
# 建立 Swift User
$ openstack user create --password SWIFT_PASS --email swift@example.com swift

# 建立 Swift Role
$ openstack role add --project service --user swift admin

# 建立 Swift service
$ openstack service create --name swift  --description "OpenStack Object Storage" object-store

# 建立 Swift URL
$ openstack endpoint create \
 --publicurl 'http://10.0.0.11:8080/swift/v1'  \
 --internalurl 'http://10.0.0.11:8080/swift/v1'  \
 --adminurl 'http://10.0.0.11:8080/swift/v1'  \
 --region RegionOne  object-store
```

### 變更 ceph.conf 設定
到部署 server 上，或手動修改每台 gateway node(s) ，增加以下內容：
```
[client.radosgw.controller1]
host = controller1
keyring = /etc/ceph/ceph.client.radosgw.controller1.keyring
rgw socket path = /tmp/radosgw.sock
log file = /var/log/ceph/radosgw.controller1.log
rgw dns name = controller1

rgw keystone url = http://10.0.0.11:5000
rgw keystone admin token = e0cae61b16320e8569fd
rgw keystone accepted roles = Member, _member_, admin
rgw keystone token cache size = 500
rgw keystone revocation interval = 500
rgw s3 auth use keystone = true
rgw nss db path = /var/ceph/nss
```
重啟服務：
```sh
$ sudo /etc/init.d/radosgw restart
```

設定 Boot 時啟動：
```sh
$ sudo update-rc.d radosgw defaults
```