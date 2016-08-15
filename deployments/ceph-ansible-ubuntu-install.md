# Deploy Ceph Using Ansible
本節將介紹如何透過 [ceph-ansible](https://github.com/ceph/ceph-ansible) 工具安裝一個測試的 Ceph 環境，一個最簡單的 Ceph 儲存叢集至少要```一個 Monitor```與```三個 OSD```。而 MDS 則是當使用到 CephFS 的時候才需要部署。

## 節點配置
本安裝將使用四台虛擬機器作為部署主機，虛擬機器採用 OpenStack，其規格為以下：

| Role | RAM  | CPUs  | Disk | IP Address |
|------|------|-------|------|------------|
| mon  | 2 GB | 1vCPU | 20 GB|172.16.1.200|
| osd1 | 2 GB | 1vCPU | 20 GB|172.16.1.201|
| osd2 | 2 GB | 1vCPU | 20 GB|172.16.1.202|
| osd3 | 2 GB | 1vCPU | 20 GB|172.16.1.203|


其中若是虛擬機，要額外建立 3 顆虛擬硬碟來作為 OSD 使用，如以下：

| Dev path  |Disk Size|Description|
|-----------|---------|-----------|
| /dev/vdb  |  25 GB  | osd1 掛載  |
| /dev/vdb  |  25 GB  | osd2 掛載  |
| /dev/vdb  |  25 GB  | osd3 掛載  |

## 事前準備
首先在```mon```節點設定 SSH 到其他節點不需要密碼，請依照以下執行：
```sh
$ ssh-keygen -t rsa
$ ssh-copy-id osd1
...
```
> 若虛擬機的話，建立金鑰後可以直接上傳```公有金鑰```提供給其他節點。

接著在每一個節點設定 sudo 不需要密碼：
```sh
$ echo "ubuntu ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ubuntu && sudo chmod 440 /etc/sudoers.d/ubuntu
```
> 一般虛擬機映像檔預設就有設定。


然後在每一台節點新增以下內容到```/etc/hosts```：
```
127.0.0.1 localhost

10.21.20.99 ceph-deploy
172.16.1.200 mon
172.16.1.201 osd1
172.16.1.202 osd2
172.16.1.203 osd3
```

回到```mon```節點安裝部署將使用到的 ansible 工具：
```sh
$ sudo apt-get install -y software-properties-common git cowsay
$ sudo apt-add-repository -y ppa:ansible/ansible
$ sudo apt-get update && sudo apt-get install -y ansible
```

在```mon```節點編輯```/etc/ansible/hosts```，加入以下內容：
```
[mons]
mon

[osds]
osd[1:3]
```
> 若要安裝 rgw 與 mds 的話，可再添加以下：
```sh
[rgws]
mon
[mdss]
mon
```

完成後透過以下指令檢查節點是否可以溝通：
```sh
$ ansible all -m ping
172.16.1.200 | success >> {
    "changed": false,
    "ping": "pong"
}
...
```

## 部署 Ansible Ceph 叢集
首先在`mon`節點透過 git 來下載 ceph-ansible 專案：
```sh
$ git clone https://github.com/ceph/ceph-ansible.git
$ cd ceph-ansible
$ cp site.yml.sample site.yml
$ cp group_vars/all.sample group_vars/all
$ cp group_vars/mons.sample group_vars/mons
$ cp group_vars/osds.sample group_vars/osds
```
> 若要部署 rgw 與 mds 的話，需再執行以下指令：
```sh
$ cp group_vars/mdss.sample group_vars/mdss
$ cp group_vars/rgws.sample group_vars/rgws
```

接著編輯```group_vars/all```檔案，修改以下內容：
```yml
ceph_origin: 'upstream'
ceph_stable: true
monitor_interface: eth0
journal_size: 5000
public_network: 172.16.1.0/24
```
> 其他版本可以參考官方的說明 [ceph-ansible](https://github.com/ceph/ceph-ansible)。

完成後再編輯```group_vars/osds```檔案，修改以下內容：
```yml
journal_collocation: true
devices:
  - /dev/vdb
```
> 這邊使用 journal，也可以選擇其他使用。若有多顆 OSD則修改```devices```。

上述都確認無誤後，編輯```site.yml```檔案，並修改一下內容：
```yml
---
- hosts: mons
  become: True
  roles:
  - ceph-mon

- hosts: osds
  become: True
  roles:
  - ceph-osd
```
> 若要部署 rgw 與 mds 的話，需再加入以下內容：
```yml
- hosts: mdss
  become: True
  roles:
  - ceph-mds
```
與
```yml
- hosts: rgws
  become: True
  roles:
  - ceph-rgw
```

完成後就可以透過以下指令來進行部署：
```sh
$ ansible-playbook site.yml
```
