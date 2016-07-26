# Ceph Docker 叢集安裝
本節將介紹如何透過 [ceph-docker](https://github.com/ceph/ceph-docker) 工具安裝一個測試的 Ceph 環境，一個最簡單的 Ceph 儲存叢集至少要```一個 Monitor```與```三個 OSD```。而 MDS 則是當使用到 CephFS 的時候才需要部署。


## 節點配置
本安裝將使用一台虛擬機器作為部署主機，虛擬機器採用 OpenStack，其規格為以下：

| Role      |RAM   | CPUs  | IP Address |
|-----------|------|-------|------------|
| ceph-aio  | 4 GB | 2vCPU |172.16.1.115|

其中虛擬硬碟共需要四顆，如以下：

| Dev path  |Disk   | Description|
|-----------|-------|------------|
| /dev/vda  | 30 GB | 作業系統使用 |
| /dev/vdb  | 25 GB | osd-1 使用  |
| /dev/vdc  | 25 GB | osd-2 使用  |
| /dev/vdd  | 25 GB | osd-3 使用  |


## 事前準備
首先在主機安裝相關套件，這邊主要安裝 Docker 即可，透過以下方式安裝：
```sh
$ curl http://files.imaclouds.com/scripts/docker_install.sh | sh
```

## 部署 Docker Ceph 叢集
首先為了方便使用與管理，我們透過 Docker 建立一個額外的網路來提供給 Ceph 叢集使用：
```sh
$ docker network create --driver bridge cluster-net
$ docker network inspect cluster-net
{
    "Subnet": "172.18.0.0/16",
    "Gateway": "172.18.0.1/16"
}
```

### MON 部署
當完成網路建立後，即可以部署 Ceph 叢集的各種角色，一開始我們必須先部署 Monitor 容器：
```sh
$ cd ~ && DIR=$(pwd)
$ docker run -d --net=cluster-net \
-v ${DIR}/ceph:/etc/ceph \
-v ${DIR}/lib/ceph/:/var/lib/ceph/ \
-e MON_IP=172.18.0.2 \
-e CEPH_PUBLIC_NETWORK=172.18.0.0/16 \
--name mon1 \
ceph/daemon mon
```
> 若發生錯誤請刪除以下目錄。如以下指令：
```sh
$ sudo rm -rf ${DIR}/etc/ceph/
$ sudo rm -rf ${DIR}/var/lib/ceph/
```

檢查是否正確部署：
```sh
$ docker exec -ti mon1 ceph -v
ceph version 10.2.2 (45107e21c568dd033c2f0a3107dec8f0b0e58374)

$ docker exec -ti mon1 ceph -s
cluster 2c254496-e948-4abb-a6dc-9aea41bbb56a
 health HEALTH_ERR
        no osds
 monmap e1: 1 mons at {1068f41de69a=172.18.0.2:6789/0}
        election epoch 3, quorum 0 1068f41de69a
 osdmap e1: 0 osds: 0 up, 0 in
        flags sortbitwise
  pgmap v2: 64 pgs, 1 pools, 0 bytes data, 0 objects
        0 kB used, 0 kB / 0 kB avail
              64 creating
```

### OSD 部署
確認無誤後，即可部署 OSD 容器來提供實際的資料儲存，透過以下方式部署：
```sh
$ docker run -d --net=cluster-net \
--privileged=true \
--pid=host \
-v ${DIR}/ceph:/etc/ceph \
-v ${DIR}/lib/ceph/:/var/lib/ceph/ \
-v /dev/:/dev/ \
-e OSD_DEVICE=/dev/vdb \
-e OSD_TYPE=disk \
-e OSD_FORCE_ZAP=1 \
--name osd1 \
ceph/daemon osd
```
> P.S. 若有多個 OSD，請修改```OSD_DEVICE```與```name```。建議建立三顆 OSD 來提供儲存的可靠性。

檢查建立無誤，透過以下指令檢查：
```sh
$ docker exec -ti osd1 df | grep "osd"
/dev/vdb1                           26098208   37616  26060592   1% /var/lib/ceph/osd/ceph-0
```

當建立完成三個 OSD 時，可以在 MON 檢查 PG 是否無誤：
```sh
$ docker exec -ti mon1 ceph -s
cluster 2c254496-e948-4abb-a6dc-9aea41bbb56a
 health HEALTH_OK
 monmap e1: 1 mons at {1068f41de69a=172.18.0.2:6789/0}
        election epoch 3, quorum 0 1068f41de69a
 osdmap e16: 3 osds: 3 up, 3 in
        flags sortbitwise
  pgmap v37: 64 pgs, 1 pools, 0 bytes data, 0 objects
        101 MB used, 76358 MB / 76459 MB avail
              64 active+clean
```

### RGW 部署
當完成一個 RAODS(MON+OSD)叢集後，即可建立物件儲存閘道(RAODS Gateway)提供 S3 與 Swift 相容的 API，來儲存檔案到儲存叢集中，一個 RGW 容器建立如下所示：
```sh
$ docker run -d --net=cluster-net \
-v ${DIR}/lib/ceph/:/var/lib/ceph/ \
-v ${DIR}/ceph:/etc/ceph \
-p 8080:8080 \
--name rgw1 \
ceph/daemon rgw
```

完成後，透過 curl 工具來測試是否正確部署：
```sh
$ curl -H "Content-Type: application/json" http://127.0.0.1:8080
<?xml version="1.0" encoding="UTF-8"?><ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>anonymous</ID><DisplayName></DisplayName></Owner><Buckets></Buckets></ListAllMyBucketsResult>
```

透過 Python Client 進行檔案儲存，首先下載程式：
```sh
$ wget https://gist.githubusercontent.com/kairen/e0dec164fa6664f40784f303076233a5/raw/33add5a18cb7d6f18531d8d481562d017557747c/s3client
$ chmod u+x s3client
$ sudo pip install boto
```

接著透過以下指令建立一個使用者：
```sh
$ docker exec -ti rgw1 radosgw-admin user create --uid="test" --display-name="I'm Test account" --email="test@example.com"

"keys": [
        {
            "user": "test",
            "access_key": "PFMKGXCFD77L8X4CF0T4",
            "secret_key": "SA8RpGO7SoN4TIdRxYtxloc5kRSLQvhOihJdDGG3"
        }
    ],
```

建立一個放置環境參數的檔案```s3key.sh```：
```sh
export S3_ACCESS_KEY="PFMKGXCFD77L8X4CF0T4"
export S3_SECRET_KEY="SA8RpGO7SoN4TIdRxYtxloc5kRSLQvhOihJdDGG3"
export S3_HOST="127.0.0.1"
export S3_PORT="8080"
```

然後 source 檔案，並嘗試執行列出 bucket 指令：
```sh
$ . s3key.sh
$ ./s3client list
---------- Bucket List ----------
```

建立一個 Bucket，並上傳檔案：
```sh
$ ./s3client create files
Create [files] success ...

$ ./s3client upload files s3key.sh /
Upload [s3key.sh] success ...
```

完成後，即可透過 list 與 download 來查看與下載：
```sh
$ ./s3client list files
---------- [files] ----------
s3key.sh            	157                 	2016-07-26T06:48:14.327Z

$ ./s3client download files s3key.sh
Download [s3key.sh] success ...
```

### MDS 部署
當系統需要使用到 CephFS 時，我們將必須建立 MDS(Metadata Server) 來提供詮釋資料的儲存，一個 MDS 容器部署如下：
```sh
$ docker run -d --net=cluster-net \
-v ${DIR}/lib/ceph/:/var/lib/ceph/ \
-v ${DIR}/ceph:/etc/ceph \
-e CEPHFS_CREATE=1 \
--name mds1 \
ceph/daemon mds
```

透過以下指令檢查是否建立無誤：
```sh
$ docker exec -ti mds1 ceph mds stat
e5: 1/1/1 up {0=mds-aea2f53de13a=up:active}

$ docker exec -ti mds1 ceph fs ls
name: cephfs, metadata pool: cephfs_metadata, data pools: [cephfs_data ]
```
