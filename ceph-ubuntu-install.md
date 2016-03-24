# Ubuntu 叢集安裝
![ceph cluster](images/ceph_cluster.png)
### Cluster 拓樸

**一個簡單的叢集拓樸 ：**
```sh
     10.21.20.180                   |           10.21.20.200
     +------------------+           |           +-----------------+
     |  [ Admin Node ]  |           |           |  [ Client PC ]  |
     |                  |-----------+-----------|   Ceph-Deploy   |
     | Meta Data Server |           |           |                 |
     +------------------+           |           +-----------------+
                                    |
        +---------------------------+--------------------------+
        |                           |                          |
        |10.21.20.181                |10.21.20.182             |10.21.20.183
+-------+----------+       +--------+---------+       +--------+---------+
| [ Ceph Node #1 ] |       | [ Ceph Node #2 ] |       | [ Ceph Node #3 ] |
|  Monitor Daemon  +-------+  Monitor Daemon  +-------+  Object Storage  |
|  Object Storage  |       |  Object Storage  |       |                  |
+------------------+       +------------------+       +------------------+

```

### 設定 Ceph Cluster

**如果為『文字介面』，請在所有"節點"修改```/etc/network/interfaces```為以下對應，若為『GUI』則直接設定成固定即可**
```
auto eth0
iface eth0 inet static
        address 10.21.20.xx
        netmask 255.255.255.0
        network 10.21.20.0
        broadcast 10.21.20.255
        gateway 10.21.20.254
        dns-nameservers 8.8.8.8
```
**修改所有"節點"的/etc/hosts為以下：**
```txt
10.21.20.180 ceph-mds
10.21.20.181 ceph-node1
10.21.20.182 ceph-node2
10.21.20.183 ceph-node3
10.21.20.200 ceph-client
```
**設定所有"節點"不需輸入密碼即可使用sudo：**
```sh
echo "ceph ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph && sudo chmod 440 /etc/sudoers.d/ceph
```

**安裝SSH 不需要密碼登入，先產生Key:**
```sh
ssh-keygen
vim ~/.ssh/config
```
**貼到~/.ssh/config 裡面上，並確認對應於Host正確**
```txt
Host ceph-mds
    Hostname ceph-mds
    User ceph
Host ceph-node1
    Hostname ceph-node1
    User ceph
Host ceph-node2
    Hostname ceph-node2
    User ceph
Host ceph-node3
    Hostname ceph-node3
    User ceph
Host ceph-client
    Hostname ceph-client
    User ceph
```
**Copy其他節點金鑰，確保可以直接登入**
```sh
ssh-copy-id ceph-mds
ssh-copy-id ceph-node1
ssh-copy-id ceph-node2
ssh-copy-id ceph-node3
ssh-copy-id ceph-client
```
**安裝與更新Ceph核心於Admin node上，並透過Ceph-deploy進行環境安裝**
```sh
wget -q -O- https://raw.github.com/ceph/ceph/master/keys/release.asc | sudo apt-key add -
echo deb http://ceph.com/debian/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
sudo apt-get update && sudo apt-get -y install ceph-deploy ceph-common ceph-mds
mkdir cluster && cd cluster
```
### 開始架設環境：
```sh
# 新增Monitor
ceph-deploy new ceph-node1 ceph-node2

# 安裝套件
ceph-deploy install ceph-node1 ceph-node2 ceph-node3
# 初始化 Monitor 節點
ceph-deploy mon create-initial

# 準備要使用之osd
ceph-deploy osd prepare ceph-node1:/hdd ceph-node1:/ssd ceph-node2:/osd  ceph-node2:/osd_ssd ceph-node3:/osd  ceph-node3:/osd_ssd  ceph-node4:/osd  ceph-node4:/osd_ssd

# 啟用osd
ceph-deploy osd activate ceph-node1:/hdd ceph-node1:/osd_ssd ceph-node2:/osd  ceph-node2:/osd_ssd ceph-node3:/osd  ceph-node3:/osd_ssd  ceph-node4:/osd  ceph-node4:/osd_ssd

# 建立admin節點
ceph-deploy admin ceph-mds ceph-client

# 建立mds節點
ceph-deploy mds create ceph-mds
```
**檢查ceph狀態**
```sh
ceph status
ceph health
ceph df
ceph -w # Keep Monitor
```
> * 如果出現```ERROR: missing keyring, cannot use cephx for authentication```，請注意這個檔案```/etc/ceph/ceph.client.admin.keyring```是否有權限讀取。
* 如果出現```too few PGs per```，修改```pg_num```與```pgp_num```。範例如下：
```sh
ceph osd pool set rbd pg_num 128
ceph osd pool set rbd pgp_num 128
```

**檢查osd狀態**
```sh
ceph osd stat
ceph osd dump
ceph osd tree
```

#### 如果時間沒有同步請更新以下
```sh
sudo apt-get -y install ntp
sudo vim /etc/ntp.conf
```
**修改配置檔如下所示：**
```sh
server tock.stdtime.gov.tw
server tick.stdtime.gov.tw
server time.stdtime.gov.tw
server clock.stdtime.gov.tw
broadcast 10.21.20.255
```
**重啟服務**
```sh
sudo service ntp restart
sudo ntpq -c lpeer
sudo tail -f /var/log/syslog
```
