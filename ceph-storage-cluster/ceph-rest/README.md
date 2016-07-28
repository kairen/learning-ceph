# Ceph REST APIs
#### 新增client.restapi權限：
```sh
sudo ceph auth get-or-create client.restapi mds 'allow' osd 'allow *' mon 'allow *' | sudo tee -a /etc/ceph/ceph.client.restapi.keyring
```
#### 設置以下資訊到/etc/ceph/ceph.conf最後面：
```sh
sudo vim /etc/ceph/ceph.conf
# 加入以下
[client.restapi]
log_file = /dev/null
keyring = /etc/ceph/ceph.client.restapi.keyring
public addr = 0.0.0.0:5100
restapi base url = /api/v1
# 加入以上
```
#### 開啟 ceph-rest-api
```sh
ceph-rest-api -n client.restapi
```

#### Calamari repository
Install```software-properties-common```:
```sh
sudo apt-get install software-properties-common
```
Replace APT keys (Debian, Ubunt)：
```sh
sudo apt-key del 17ED316D
curl https://git.ceph.com/release.asc | sudo apt-key add -
```
Add repository url：
```sh
echo "deb http://download.ceph.com/calamari/1.3.1/ubuntu/trusty trusty main" | sudo tee /etc/apt/sources.list.d/calamari.list
sudo apt-get update
```

# Ceph Calamari Server

#### Installing Diamond
Install diamond follow below：
```sh
sudo apt-get install diamond salt-master
```

#### Installing Server and Clients
Install server and client follow below：
```sh
sudo apt-get install calamari-server calamari-clients
```

#### Initialization Server
```sh
sudo calamari-ctl initialize
```

# Ceph Calamari agent
Install agent follow below：
```sh
sudo apt-get install salt-minion diamond
```
Configure diamond：
```sh
sudo mv /etc/diamond/diamond.conf.example /etc/diamond/diamond.conf
```
Configure salt-minion connect to server:
```sh
sudo sed -i 's/#master\s*:.*/master: 10.26.1.28/' /etc/salt/minion
```
Restart salt-minion service：
```sh
sudo service salt-minion restart
sudo service diamond restart
```

## 參考
* [Grafana+Diamond+Graphite](http://www.qingpingshan.com/rjbc/qt/27348.html)
* [Ceph calamari](http://www.cnblogs.com/bodhitree/p/5035325.html)
