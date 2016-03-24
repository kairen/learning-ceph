# Placement Groups（放置群組）
一個 Placement Group 聚集了一系列的物件到一個 Group，並且映射這個 Group到一系列的 OSD。在每一個物件的基礎上追蹤物件的配置與物件的 metadata在運算上效率並不好，比如擁有上百物件的系統，在每一個物件基礎上追蹤物件的配置是不切實際的。 PG 解決了這一個障礙效能與可延伸性。此外 PG 降低了行程的數目，必須追蹤每個物件的 metadata 數量的 Ceph 儲存與檢索資料。

![](images/pg.png)

每個 PG 需要一些數量的系統資源:

* **Directly**: 每個 PG 需要一些數量的記憶體和 CPU。
* **Indirectly**: PG 的總數增加了同等操作計數。


### 一個預選的 PG_NUM
當建立一個新的 pool 時，可以使用以下指令：
```sh
ceph osd pool create {pool-name} pg_num
```

在建立時，需強制性的設定 ```pg_num```一個值，因為它不能自動計算。以下為一些常用的設定值：
* OSD 少於 5 個時，設定 ```pg_num``` 為 ```128```。
* OSD 介於 5 ~ 10 個之間，設定 ```pg_num``` 為 ```512```。
* OSD 介於 10 ~ 50 個之間，設定 ```pg_num``` 為 ```4096```。
* 如果超過 50 個 OSD，需要了解如何透過自己權衡（tradeoffs）與計算 ```pg_num``` 的值。

作為物件的數量增加，選擇正確的 ```pg_num``` 變得更加重要，因為它會有資料出錯時，對叢集行為的耐久性有顯著的影響（即一定概率的災難性事件導致資料遺失）。

### Placement Groups 是如何使用的？
Pool 內的 PG 把物件聚集在一起，因為追蹤每一個物件的位置與及 metadata 需要大量的計算，好比一個擁有數百萬物件的系統，不可能在物件這一層級追蹤每個位置。
![](pg-use.png)

### PLACEMENT GROUPS TRADEOFFS


#### 記憶體、處理器和網路使用情況
各個 PG、OSD 與 Monitor 都需要記憶體、網路、處理器，在復原期間需求更大。為了消除過載兒把物件聚集成 Group 是 PG 存在的最大主要原因。最小化 PG 數量可以節省不少的資源消耗。

### 選擇一個 Placement Groups 的數量
如果有超過 50 個以上的 OSDs，建議設定 50 ~ 100 的 placement groups 於每個 OSD 上來均衡資源的使用、資料的耐久性與分散。如果少於 50 個 OSDs，選擇其中最好的 [Preselection](http://ceph.com/docs/master/rados/operations/placement-groups/#preselection)。對於單個 pool 的物件，可以使用以下公式來獲取一個基準值：
```
             (OSDs * 100)
Total PGs =  ------------
              pool size
```


### 設定 Placement Groups 的數量
要設定某個 pool 的 placement groups 數量，必須在建立它時就指定，細節可參考 [Create a Pool](http://ceph.com/docs/master/rados/operations/pools#createpool)。一個 pool 的 placement groups 設定好之後，還可以增加（但不可以減少），下列指令可增加該數量：
```sh
ceph osd pool set {pool-name} pg_num {pg_num}
```
增加 placement groups 數量後，還不需增加可用於放置的 placement groups（pgp_num）數量，這樣才會開始重新均衡。pgp_num 應要等於 pg_num，可利用以下指令來增加：
```sh
ceph osd pool set {pool-name} pgp_num {pgp_num}
```

### 獲取 Placement Groups 的數量
要獲得一個 pool 的 placement groups 數量，可以執行以下指令：
```sh
ceph osd pool get {pool-name} pg_num
```

### 獲取叢集裡的 Placement Group 統計資訊
要獲取叢集裡的 placement groups 的統計資訊，可執行以下指令：
```sh
ceph pg dump [--format {format}]
```
可用格式有純文字 ```plain```（預設）和 ```json``` 。

### 獲取卡住（STUCK）的 Placement Groups 統計資訊
要獲取所有卡在某個狀態的 placement groups 統計資訊，可執行指令：
```sh
ceph pg dump_stuck inactive|unclean|stale [--format <format>] [-t|--threshold <seconds>]
```
* **inactive（不活躍）**：placement groups 不能處理讀寫，因為它們在等待一個有最新資料的 OSD 復原且進入叢集。
* **unclean（不乾淨）**：placement groups 含有複製的數量未達到期望數量的物件，它們應該在恢復中。
* **stale（老舊的）**：placement groups 處於未知狀態，儲存它們的 OSD 有段時間沒向 Monitor 回報了（由 ```mon_osd_report_timeout``` 設定）。

可用格式有```plain```（預設）和 ```json```。門檻值定義 placement groups 被認為卡住前等待的最小時間（預設為 ```300秒```）。

### 獲取一個 Placement Group MAP
要獲取一個具體 placement groups 的 placement groups map，可以執行以下指令：
```sh
ceph pg map {pg-id}
```
範例：
```sh
ceph pg map 1.6c
```
Ceph 會回傳 placement groups map、placement groups、OSD狀態：
```
osdmap e13 pg 1.6c (1.6c) -> up [1,0] acting [1,0]
```

### 獲取一個 Placement Groups 統計資訊
要查看一個具體 placement groups 的統計資訊，執行指令：
```sh
ceph pg {pg-id} query
```

### 刷洗一個 Placement Groups
要刷洗一個 placement group，可以執行以下：
```sh
ceph pg scrub {pg-id}
```
Ceph 會檢查原始與任何複製的節點，並產生 placement groups 裡所有物件的目錄，然後在對比，確保沒有物件遺失或不匹配，並且它們的內容一致。

### 恢復遺失
如果叢集遺失了一個或多個物件，而且必須放棄搜索這些資料，這時要把未找到的物件標為 ```lost```。

如果所有可能的位置都查詢過了，仍燃找不到這些物件，可能就得要放棄該物件們。這可能是極少的失敗組合導致，叢集在寫入完成前，未能得知寫入是否已執行而造成。

目前 Ceph 只支援 revert 參數，它使得退回到物件的前一個版本（如果它是新物件），或完全忽略它，要把 ```unfound``` 物件標示為 ```lost```，指令如下：
```sh
ceph pg {pg-id} mark_unfound_lost revert|delete
```
> 要謹慎使用，它可能會考慮那些期望物件存在的應用程式。
