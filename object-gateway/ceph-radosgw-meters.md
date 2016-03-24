# Ceph Object Storage
若透過```Ceph 分散式儲存系統```來取代 OpenStack Swift 的話，可以參考 [安裝 Rados GW](http://docs.ceph.com/docs/master/radosgw/)。若要讓 Ceilometer 能夠取得 Ceph 的物件儲存資料的話，需要到```/etc/ceph/ceph.conf```設定以下內容：
```
[client.radosgw.gateway]
...
rgw enable usage log = true
rgw usage log tick interval = 30
rgw usage log flush threshold = 1024
rgw usage max shards = 32
rgw usage max user shards = 1
```
完成後編輯```/etc/ceilometer/ceilometer.conf```，並在```[rgw_admin_credentials]```部分加入以下：
```sh
[rgw_admin_credentials]
# Access key for Radosgw Admin. (string value)
access_key = <None>
 
# Secret key for Radosgw Admin. (string value)
secret_key = <None>
```

在```[service_types]```部分加入以下：
```sh
[service_types]

# Radosgw service type. (string value)
radosgw = object-store
```

完成後，重新啟動服務：
```sh
sudo service ceilometer-agent-central restart
sudo service ceilometer-agent-notification restart
sudo service ceilometer-api restart
sudo service ceilometer-collector restart
sudo service ceilometer-alarm-evaluator restart
sudo service ceilometer-alarm-notifier restart
```
下面是 Ceph object storage 會收集的 meters：
![](images/Ceph_object_storage.png)