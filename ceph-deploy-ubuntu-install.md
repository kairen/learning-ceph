# Ceph Deploy Ubuntu 叢集安裝
本節將介紹如何透過 [ceph-deploy](https://github.com/ceph/ceph-deploy) 工具安裝一個測試的 Ceph 環境，一個最簡單的 Ceph 儲存叢集至少要```一個 Monitor```與```三個 OSD```。而 MDS 則是當使用到 CephFS 的時候才需要部署。

![](images/Ceph-topo.jpg)

## 環境準備
在開始部署 Ceph 叢集之前，我們需要在每個節點做一些基本的準備，來確保叢集安裝的過程是流暢的，本次安裝會擁有 6 台節點，叢集拓樸圖如下所示：
```sh
                           +------------------+
                           | [ Deploy  Node ] |
                           |   10.21.20.99    |
                           | Ceph deploy tool |
                           +--------+---------+
                                    |
                                    |           
     +------------------+           |           +-----------------+
     |  [ Admin Node ]  |           |           |[ Monitor  Node ]|
     |   10.21.20.100   |-----------+-----------|   10.21.20.101  |
     |  Ceph admin ops  |           |           |  Ceph mon Node  |
     +------------------+           |           +-----------------+
                                    |
        +---------------------------+--------------------------+
        |                           |                          |
        |                           |                          |
+-------+----------+       +--------+---------+       +--------+---------+
|  [ OSD Node 1 ]  |       |  [ OSD Node 2 ]  |       |  [ OSD Node 3 ]  |
|   10.21.20.121   +-------+   10.21.20.122   +-------+   10.21.20.123   |
|  Object Storage  |       |  Object Storage  |       |  Object Storage  |
|   Disk  *  2     |       |   Disk  *  2     |       |   Disk  *  2     |
+------------------+       +------------------+       +------------------+
```
> P.S. 上面磁碟分為兩個，因為這邊教學不將 journal 分開來，故一顆當作系統使用，一顆為資料儲存與 journal 使用。
> P.S. 這邊網路建議設定為```static```，若有支援 Jumbo frame 也可以開啟。

首先在每一台節點新增以下內容到```/etc/hosts```：
```
127.0.0.1 localhost

10.21.20.99 ceph-deploy
10.21.20.100 ceph-admin
10.21.20.101 ceph-mon1
10.21.20.121 ceph-osd1
10.21.20.122 ceph-osd2
10.21.20.123 ceph-osd3
```

然後在每台節點執行以下指令來使```sudo```不需要輸入密碼：
```sh
$ echo "ubuntu ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ubuntu && sudo chmod 440 /etc/sudoers.d/ubuntu
```
> 上面 ```ubuntu``` 是節點的使用者名稱，這邊都是一樣。
> P.S. 當然若要注意安全考量，而不讓該使用者直接使用有權限的資源，可以使用 root user。

接著在設定```Deploy```節點能夠以無密碼方式進行 SSH 登入其他節點，請依照以下執行：
```sh
$ ssh-keygen -t rsa
$ ssh-copy-id ceph-mon1
$ ssh-copy-id ceph-mds
...
```
> 若 Deploy 節點的使用者與其他不同的話，編輯```~/.ssh/config```，加入以下內容：
```sh
Host ceph-admin
    Hostname ceph-admin
    User ubuntu
Host ceph-mds
    Hostname ceph-mds
    User ubuntu
Host ceph-mon1
    Hostname ceph-mon1
    User ubuntu
Host ceph-osd1
    Hostname ceph-osd1
    User ubuntu
Host ceph-osd2
    Hostname ceph-osd2
    User ubuntu
Host ceph-osd3
    Hostname ceph-osd3
    User ubuntu
```

之後在```Deploy```節點安裝部署工具，首先安裝基本相依套件，使用```apt-get```來進行安裝，再透過```python-pip```進行安裝部署工具：
```sh
$ sudo apt-get install -y python-pip
$ sudo pip install ceph-deploy
```
> P.S. ceph-deploy 所安裝的 ceph 版本，會受到 ceph-deply 工具版本不同而有所差異。

完成後即可開始部署 Ceph 環境。

### 環境部署
首先建立一個名稱為```mycluster```的目錄，並進入該目錄：
```
$ sudo mkdir mycluster
$ cd mycluster
```

採用 ceph-deploy 工具部署環境時，需要依照以下步驟進行，首先建立要當任 Monitor 的節點，透過以下方式：
```sh
$ ceph-deploy new ceph-mon1 <other_nodes>
```
> 當執行該指令時，不是直接讓 ceph-mon1 節點安裝成為 Monitor，而只是新增一個```conf```，並標示誰是 Monitor，當在初始化階段時，才將該設定檔給對應節點，讓它啟動是設定為 Monitor 角色。


接著我們需要先讓每個節點（ceph-deploy除外）安裝 ceph-common 套件，透過以下方式安裝：
```sh
$ ceph-deploy install ceph-admin ceph-mds <other_nodes>
```

當完成安裝後，才能開始真正的部署節點的角色，第一先將 Monitor 都完成部署，才能讓叢集先正常被運作，透過以下指令來將 Monitors 初始化：
```sh
$ ceph-deploy mon create-initial
```

上述沒有問題後，就可以開始部署實際作為儲存的 OSD 節點，我們可以透過以下指令進行：
```sh
$ ceph-deploy osd prepare ceph-osd1:/dev/sdb <other_nodes>:<data_disk>
```
> 若要將 journal 分離，可以使用以下方式：
```sh
$ ceph-deploy osd prepare ceph-osd1:/dev/sdb:/dev/sdc <other_nodes>:<data_disk>:<journal_disk>
```

部署沒有問題的話，即可啟用該 OSD：
```sh
$ ceph-deploy osd activate ceph-osd1:/dev/sdb <other_nodes>:<data_disk>
```
> P.S. 較新的版本該指令可以省略，因為在準備期間就會幫你直接啟動。

這樣一個簡單的叢集就部署完成了，這時候我們可以隨需求加入```admin```與```MDS```節點，可以透過以下方式進行：
```sh
$ ceph-deploy admin ceph-admin
$ ceph-deploy mds create ceph-mds
```

完成後，可以透過以下指令檢查 ceph 叢集狀態：
```sh
$ ceph health
HEALTH_OK

$ ceph status
cluster e2432059-e219-4555-8d37-c32d5b16e4a4
 health HEALTH_OK
 monmap e1: 1 mons at {ceph-mon1=10.21.20.101:6789/0}
        election epoch 6, quorum 0, ceph-mon1
 osdmap e119: 3 osds: 3 up, 3 in
        flags sortbitwise
  pgmap v813: 128 pgs, 2 pools, 91289 kB data, 22856 objects
        691 MB used, 2152 GB / 2152 GB avail
             128 active+clean
```
> * 如果出現```ERROR: missing keyring, cannot use cephx for authentication```，請注意這個檔案```/etc/ceph/ceph.client.admin.keyring```是否有權限讀取。
* 如果出現```too few PGs per```，修改```pg_num```與```pgp_num```。範例如下：
```sh
ceph osd pool set rbd pg_num 128
ceph osd pool set rbd pgp_num 128
```

若要檢查 mds 可以使用以下指令：
```sh
$ ceph mds stat
```

若想檢查 OSDs 的目前狀態可以使用以下幾個指令：
```sh
$ ceph osd stat
osdmap e119: 3 osds: 3 up, 3 in
       flags sortbitwise

$ ceph osd dump
$ ceph osd tree
```

最後如果進行多台 Monitor 的部署的話，要注意讓這些節點的時間同步。Ceph 使用多 Monitort 來避免單點故障問題，部署的比例可自行定義，比如 1 台、3/1 台、5/3 台等等。
