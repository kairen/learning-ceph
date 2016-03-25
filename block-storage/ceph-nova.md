# Ceph Nova 整合
首先在```Controller```與```Compute```上安裝 Ceph，並將 conf 檔推給串接節點：
```sh
$ ceph-deploy install <node>
```
> ```ceph-deploy``` 可以用```pip install ceph-deploy```安裝。
> 注意最後要在 deploy node 使用以下指令```ceph-deploy --overwrite-conf config push ```來將 conf 檔傳到特定節點。


在```Controller```建立一個 Pool 用來給 Nova 使用：
```sh
$ ceph osd pool create vms 128
```

在```Controller```建立 Ceph 驗證與權限：
```sh
$ ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images'
$ ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'
$ ceph auth get-or-create client.cinder-backup mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=backups'
```

在```Controller```將```client.cinder.keyring```傳給```Compute```：
```sh
$ ceph auth get-or-create client.cinder | ssh <compute_node> sudo tee /etc/ceph/client.cinder.keyring
```

在```Controller```建立一個臨時 Key 副本來傳給```Compute```使用：
```sh
$ ceph auth get-key client.cinder -o client.cinder.key
```
在```Controller```建立```secret.xml```來傳給```Compute```的 libvirt 使用：
```sh
$ cat > secret.xml <<EOF
<secret ephemeral='no' private='no'>
  <uuid>457eb676-33da-42ec-9a8c-9293d545c337</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>
EOF
```
> ```<uuid>``` 可以自行變更。

複製上面兩個檔案到```Compute```節點：
```sh
$ scp ./secret.xml compute:~/
$ scp ./client.cinder.key compute:~/
```

來到```Compute```節點，為```libvirt```建立 Ceph 認證，先定義證書：
```sh
$ sudo virsh secret-define --file secret.xml
Secret 457eb676-33da-42ec-9a8c-9293d545c337 created
```
然後設定金鑰：
```sh
$ sudo virsh secret-set-value --secret 457eb676-33da-42ec-9a8c-9293d545c337 --base64 $(cat client.cinder.key) && rm client.cinder.key secret.xml
```

在```Compute```節點編輯```/etc/ceph/ceph.conf```，並在```[client]```部分加入以下：
```sh
[client]
rbd cache = true
rbd cache size = 268435456
rbd cache max dirty = 134217728
rbd cache max dirty age = 5
rbd cache writethrough until flush = true
admin socket = /var/run/ceph/guests/$cluster-$type.$id.$pid.$cctid.asok
log file = /var/log/qemu/qemu-guest-$pid.log
rbd concurrent management ops = 20

[client.cinder]
keyring = /etc/ceph/client.cinder.keyring

[client.cinder-backup]
keyring = /etc/ceph/client.cinder-backup.keyring

[client.glance]
keyring = /etc/ceph/client.glance.keyring
```
> 也可以在```deploy 節點```修改完後，使用```ceph-deploy --overwrite-conf config push <host>```來 push。

建立 qume 檔案，並修改權限：
```sh
$ sudo mkdir -p /var/run/ceph/guests/ /var/log/qemu/
$ sudo chown qemu:libvirtd /var/run/ceph/guests /var/log/qemu/
```

接著編輯```/etc/nova/nova.conf```，在```[libvirt]```加入以下：
```sh
[libvirt]
virt_type=kvm
inject_password=False
inject_key=False
inject_partition=-2
block_migration_flag=VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_NON_SHARED_INC
live_migration_flag=VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST
disk_cachemodes = "network=writeback"
hw_disk_discard = unmap
cpu_mode=host-model
images_type=rbd
images_rbd_pool=vms
rbd_user=cinder
rbd_secret_uuid=457eb676-33da-42ec-9a8c-9293d545c337
```

完成後，重起服務：
```sh
$ sudo service nova-compute restart
```
