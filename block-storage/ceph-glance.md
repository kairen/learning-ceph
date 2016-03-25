# Ceph Glance 整合
首先在```Controller```或```Glance Node```上安裝 Ceph，並將 conf 檔推給兩個節點：
```sh
$ ceph-deploy install <node>
```
> ```ceph-deploy``` 可以用```pip install ceph-deploy```安裝。

在```Controller```節點新增一個 Pool 用來給 Glance 使用：
```sh
$ ceph osd pool create images 128
```

在```Controller```建立 Ceph 驗證與權限：
```sh
$ ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images'
$ ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'
$ ceph auth get-or-create client.cinder-backup mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=backups'
```

在```Controller```複製認證金鑰給```Glance```節點使用：
```sh
$ ceph auth get-or-create client.glance | ssh <glance_node> sudo tee /etc/ceph/client.glance.keyring
$ ssh <glance_node> sudo chown glance:glance /etc/ceph/client.glance.keyring
```
> 這邊```<glance_node>```為 controller。

然後在```Glance```節點編輯```/etc/ceph/ceph.conf```，加入以下內容：
```sh
...

[client.glance]
keyring= /etc/ceph/client.glance.keyring
```

接著在```Glance 節點```編輯```/etc/glance/glance-api.conf```檔案，並在```[DEFAULT]```部分，修改一下：
```sh
show_image_direct_url = True
```

在```[glance_store]```部分，修改成以下：
```sh
[glance_store]
stores = glance.store.rbd.Store,glance.store.http.Store
default_store = rbd
rbd_store_pool = images
rbd_store_user = glance
rbd_store_ceph_conf = /etc/ceph/ceph.conf
rbd_store_chunk_size = 8
```

完成後，重起服務:
```sh
$ sudo service glance-api restart
```
