# Ceph Object Gateway

Ceph對象網關是個對象存儲接口，在librgw之上為應用程序構建了一個RESTful風格的Ceph存儲集群網關。Ceph對象存儲支持2種接口：

* **S3-compatible**：提供了對象存儲接口，與亞馬遜的S3 RESTful風格的接口兼容。
* **Swift-compatible**：提供了對象存儲接口，與OpenStack的Swift接口兼容。

Ceph對象存儲使用Ceph對象網關守護進程（radosgw），它是個與Ceph存儲集群交互的FastCGI模塊。因為它提供了與OpenStack Swift和Amazon S3兼容的接口， RADOS要有它自己的用戶管理。Ceph對象網關可與Ceph FS客戶端或Ceph塊設備客戶端共用一個存儲集群。S3和Swift API共用一個通用命名空間，所以你可以用一個API寫、然後用另一個檢出。

![Object Storage](images/Object Storage.png)


# Ceph radosgw manual install
### 建立 Pool 
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
 
> 可以參考 [PG Calc](http://ceph.com/pgcalc/) 的 PG Number。

# Ceph deploy radosgw
```sh
ceph-deploy install <host>
ceph-deploy rgw create <host>:rgw1
```
建立使用者(如果有出現特殊字元就刪除再重建使用者，刪除指令參考下一項)
```sh
radosgw-admin user create \
--uid=melon \
--display-name="melon" \
--email=melon@test.com
```

刪除使用者的指令：
```sh
radosgw-admin user rm --uid=melon
```

建立subuser，建完請確認要有紅字的內容，沒有subuser，swift client無法連線
```sh
radosgw-admin subuser create --uid=melon --subuser=melon:swift --access=full
```

產生secret-key(如果有secret有特殊字元就重複執行產生key的指令)
```sh
radosgw-admin key create --gen-secret --subuser=melon:swift --key-type=swift
```

Status
```sh
swift -v -A http://10.0.0.11:7480/auth/v1.0 \
-U melon:swift \
--key='GjW5HP7SkvPGbOKadByjT8nSr6b2znSOcAa4R4ym' \
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

### 使用 Admin REST API
Ceph radosgw 提供以 REST API 方式來管理 radosgw，首先需要到 radosgw 節點的```/etc/ceph/ceph.conf```設定以下資訊：
```sh
[client.radosgw.1]
rgw admin entry = "497cb9238bed1002b95704d8bcf18514"
rgw enable apis = s3, admin
```
> ```rgw admin entry```預設為 admin。

重新啟動 rgw：
```sh
sudo /etc/init.d/radosgw restart
```

在開始使用時，需要先建立一個 admin user：
```sh
radosgw-admin user create --uid="admin" --display-name="Admin API User"
```
分配 admin user 擁有權限：
```sh
radosgw-admin caps add --uid=admin --caps="users=*"
```
> 目前 caps 有以下：
```
--caps="[users|buckets|metadata|usage|zone]=[*|read|write|read, write]"
```


透過 python 測試：
```py
#!/usr/bin/env python

import requests
import json
from awsauth import S3Auth

aws_key = 'ACCESS_KEY'
secret = 'SECRET_KEY'
server_url = 'URL'
admin_entry = 'ADMIN_ENRTY_STRING'

uid="admin"

url = "http://{0}/{1}/user?format=json&uid={2}".format(server_url, admin_entry, uid)
print("URL : {}".format(url))

response = requests.get(url, auth=S3Auth(aws_key, secret, server_url))
print("Response : {}".format(response.json()))
```



