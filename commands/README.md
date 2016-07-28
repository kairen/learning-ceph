# Ceph 叢集操作
### 低階的操作
低階的叢集操作包含了啟動、停止、重新啟動叢集內的某個具體daemons、更改某個daemon或者子系統設定、增加或拆除daemon。低階的操作經常遇到擴展、搬移Ceph 叢集，以及更換老舊、損壞的硬體。

* **Adding/Removing OSDs**
* **Adding/Removing Monitors**
* **Command Reference**

### 高階的操作
高階的叢集操作，主要包括用 Ceph 服務管理腳本的啟動、停止、重啟叢集，和叢集健康狀態檢查、監控與操作叢集。

* **Operating a Cluster**
* **Monitoring a Cluster**
* **Monitoring OSDs and PGs**
* **User Management**

### 資料放置
當叢集開始運作時，就可以嘗試資料放置了。Ceph 是 PB 等級的資料儲存叢集，它用 CRUSH 演算法，並透過 storage pool 與 placement groups 叢集來分散資料。

* **Data Placement Overview**
* **Pools**
* **Erasure code**
* **Cache Tiering**
* **Placement Groups**
* **CRUSH Maps**

### 故障排除
Ceph 仍在積極開發中，所以可能會碰到一些問題，這需要評估 Ceph 設定檔案，並修改 Logging 與 Debugging 選項來解決問題。

* **The Ceph Community**
* **Troubleshooting Monitors**
* **Troubleshooting OSDs**
* **Troubleshooting PGs**
* **Logging and Debugging**
* **CPU Profiling**
* **Memory Profiling**
