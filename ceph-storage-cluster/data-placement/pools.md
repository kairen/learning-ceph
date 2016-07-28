# Pools（儲存池）
如果您開始部署叢集時，沒有建立一個 pool，Ceph會使用預設的 pools 來儲存資料。Pool提供了以下功能：
* **Resilience**：可以設定在不遺失資料的前提下，允許多少的OSD失效，對多個副本Pool來說，此值是一個物件應達到的```副本數```。典型的設定儲存物件與一個額外的副本（即 size = 2），但是你可以更改複製與副本的數量。對於 [erasure coded pools](http://ceph.com/docs/master/rados/operations/erasure-code) 來說，這個值是 coding chunks 的數量（即 m = 2 的 **erasure code profile**）
* **Placement Groups**：你可以設定一個Pool的 placement groups 數量。典型的設定會給每個OSD分配大約```100個``` placement groups，這樣不用過多的運算資源就能得到較優的平衡。設定了多個 Pool 時，要考慮到這些 Pools 與整個叢集的 placement groups 數量是否合理。
* **CRUSH Rules**：當你在 Pool 存資料的時候，與此 Pool 相關聯的 CRUSH ruleset 可以更改 CRUSH 算法，並以此操作叢集內的物件以及副本的複製（或者erasure coded pools 的 data chunks）。你可以自訂 Pool 的 CRUSH ruleset。
* **Snapshots**：用 ceph osd pool mksnap 建立快照時，實際上會建立某個特定的 Pool 的快照。
* **Set Ownership**：你可以設定一個使用者 ID，來提供一個 Pool 的擁有者。

## 列出所有 Pool
要列出叢集中的所有 Pool，可以使用以下指令：
```sh
ceph osd lspools
```
預設的 Pool 有以下：
* **data**
* **metadata**
* **rbd**

## 建立一個 Pool
建立 Pool 前，要先看過 [Pool, PG and CRUSH Config Reference](http://docs.ceph.com/docs/master/rados/configuration/pool-pg-config-ref/)。最好在設定文件裡面，重置預設的 PG 數量，因為預設並不理想，例如：
```sh
osd pool default pg num = 100
osd pool default pgp num = 100
```

要建立一個 pool ，可以執行：
```sh
ceph osd pool create {pool-name} {pg-num} [{pgp-num}] [replicated]  [crush-ruleset-name]
ceph osd pool create {pool-name} {pg-num} {pgp-num} erasure  [erasure-code-profile] [crush-ruleset-name]
```
參數意義如下：
#### {pool-name}
* **Description**：	pool 名稱，必須唯一。
* **Type**：String。
* **Required**：必需，沒指定的話，會讀取預設值、或Ceph 設定檔案裡的值。

#### {pg-num}
* **Description**：Pool擁有的 PG 總數。關於如何計算合適的數值，可以參考[Placement Groups](http://ceph.com/docs/master/rados/operations/placement-groups)。預設值為8，不適合大多數系統。
* **Type**：Integer
* **Required**：Yes
* **Default**：	8

#### {pgp-num}
* **Description**：用於 PG群組的總數。此值應當要與 pg-num 相同，但 PGP 分割的情況則例外。
* **Type**：Integer
* **Required**：沒有指定的話，讀取預設值或者 Ceph 設定檔的值。
* **Default**：	8

#### {replicated|erasure}
* **Description**： Pool 的類型，可以是 ```replicated```（保存多份物件副本，以便從遺失的 OSD 復原）或是 ```erasure```。多副本 Pool 需要更多的原始儲存空間，但已實現所有 Ceph 操作;然而 ```erasure``` 有較少的空間使用率，但目前僅有部分 Ceph 操作。
* **Type**：String
* **Required**：NO
* **Default**：	replicated

#### [crush-ruleset-name]
* **Description**：此 Pool 所用的 ``CRUSH``` 規則集合名稱。指定的規則集合必須存在。
* **Type**：String
* **Required**：NO
* **Default**：	若為 ```erasure``` 則為 **erasure-code** ; 若為 ```replicated``` 則為 **osd_pool_default_crush_replicated_ruleset**。

#### [erasure-code-profile=profile]
* **Description**：只用於 erasure-code 的 Pool上，用來指定 [erasure code profile](http://ceph.com/docs/master/rados/operations/erasure-code-profile) 框架，只設定必須由 ```osd erasure-code-profile set``` 定義。
* **Type**：String
* **Required**：NO

建立 pool 時，要設定一個合理的 placement groups 數量（ex: 100）。也要考慮到每個 OSD 的 placement groups 總數，因為  placement groups 很耗運算資源，所以很多 pool 與很多  placement groups 會導致效能下降（如：50個 pool，個包含 100 placement groups）。收益得遞減點取決於 OSD 主機的好壞。

可以參考 [Placement Groups](http://ceph.com/docs/master/rados/operations/placement-groups) 來設定 pool 合適的 placement groups 值。

## 設定 Pool 的 Quotas（配額）
Pool Quotas 可以設定最大的 bytes 數、每個 Pool 的最大 and/or 物件數。透過以下指令設定：
```sh
ceph osd pool set-quota {pool-name} [max_objects {obj-count}] [max_bytes {bytes}]
```
以下為一個範例：
```sh
ceph osd pool set-quota data max_objects 10000
```
> 若要刪除一個 quota，可以設定該值為 0。

## 刪除一個 Pool
以下指令可以刪除一個 pool：
```sh
ceph osd pool delete {pool-name} [{pool-name} --yes-i-really-really-mean-it]
```
> 如果該 pool 建立一個自定義的規則集合的話，不需要 pool 時最好刪除它。如果有建立使用者以及權限給一個 pool，但是 pool 已不存在了，最好也刪除那些使用者。

## 重新命名 Pool
以下指令可重新命名一個 pool 名稱：
```sh
ceph osd pool rename {current-pool-name} {new-pool-name}
```
> 如果重新命名一個 pool，且認證使用者有存取每個 pool 的權限，必須用新的 pool 名稱來更新使用者權限（即caps）。```適用0.48 Argonaut及以上。```

## 顯示一個 pool 統計資訊
要查看某個 pool 的使用統計，可以執行以下指令：
```sh
rados df
```

## 建立一個 pool 的快照
建立 pool 的快照，可以利用以下指令達到：
```sh
ceph osd pool mksnap {pool-name} {snap-name}
```
> ```Note 適用0.48 Argonaut及以上。```

## 刪除一個 poll 的快照
要刪除某個 pool 的快照，可以用以下指令達到：
```sh
ceph osd pool rmsnap {pool-name} {snap-name}
```

## 設定 pool 的參數值
要設定一個 pool 的參數，可以執行以下指令：
```sh
ceph osd pool set {pool-name} {key} {value}
```
有以下 ```{key}``` 參數值可以設定：
#### size
* **Description**：設定 pool 中物件的副本數。可參考 [Set the Number of Object Replicas](http://ceph.com/docs/master/rados/operations/pools/#set-the-number-of-object-replicas)。僅適用於副本 pool。
* **Type**：Integer。

#### min_size
* **Description**：設定 I/O 需要的最小副本數。可參考 [Set the Number of Object Replicas](http://ceph.com/docs/master/rados/operations/pools/#set-the-number-of-object-replicas)。僅適用於副本 pool。
* **Type**：Integer。
* **Version**：	0.54及以上。

#### crash_replay_interval
* **Description**：允許 client 重新確認而未提交的請求秒數
* **Type**：Integer。

#### pgp_num
* **Description**：計算資料放置時，使用的有效 placement groups 數量。
* **Type**：Integer。

#### crush_ruleset
* **Description**：叢集內映射物件放置時，使用的規則集合。
* **Type**：Integer。

#### hashpspool
* **Description**：給指定 pool 設定與取消 ```HASHPSPOOL``` 標示。
* **Type**：Integer。
* **Valid Range**：1：開啟，0：取消。
* **Version**：0.48以上版本。

#### nodelete
* **Description**：給指定 pool 設定與取消 ```NODELETE``` 標示。
* **Type**：Integer。
* **Valid Range**：1：開啟，0：取消。
* **Version**：```FIXME``` 版本。

#### nopgchange
* **Description**：給指定 pool 設定與取消 ```NOPGCHANGE``` 標示。
* **Type**：Integer。
* **Valid Range**：1：開啟，0：取消。
* **Version**：```FIXME``` 版本。

#### nosizechange
* **Description**：給指定 pool 設定與取消 ```NOSIZECHANGE``` 標示。
* **Type**：Integer。
* **Valid Range**：1：開啟，0：取消。
* **Version**：```FIXME``` 版本。

#### hit_set_type
* **Description**：開啟 cache pool 的 hit set 追蹤，可參考 [ Bloom Filter](http://en.wikipedia.org/wiki/Bloom_filter)。
* **Type**：String。
* **Valid Settings**：```bloom```, ```explicit_hash```, ```explicit_object```。
* **Default**：bloom，其它是用於測試的。

#### hit_set_count
* **Description**：為 cache pool 保留的 hit set 數量。此值越高。ceph-osd daemon 消耗的記憶體越多。
* **Type**：Integer。
* **Valid Range**：```1```，Agent 無法處理 > 1。

#### hit_set_period
* **Description**：為 cache pool 保留的 hit set 有效期限。此值越高。ceph-osd daemon 消耗的記憶體越多。
* **Type**：Integer。
* **Example**：```3600```，1hr。

#### hit_set_fpp
* **Description**： ```bloom``` hit set類型的報錯概率，可參考 [ Bloom Filter](http://en.wikipedia.org/wiki/Bloom_filter)。
* **Type**：Double。
* **Valid Range**：0.0 - 1.0。
* **Default**：```0.05```。

#### cache_target_dirty_ratio
* **Description**：cache pool 包含的 dirty 物件達到多少比例時，就會把它們回寫到後台的 pool。
* **Type**：Double。
* **Default**：```0.4```。

#### cache_target_dirty_high_ratio
* **Description**：cache pool 包含修改（dirty）的物件達到多少的比例時，在 cache tiering agent 將物件 flush 到後台儲存 pool時，具有更高的速度
* **Type**：Double。
* **Default**：```0.6```。

#### cache_target_full_ratio
* **Description**：cache pool 包含的 clean 物件達到多少比例時，cache agent 就會把它們趕出 cache pool。
* **Type**：Double。
* **Default**：```0.8```。

#### target_max_bytes
* **Description**：達到 ```max_bytes``` 門檻值時，Ceph 就會回寫或趕出物件。
* **Type**：Integer。
* **Example**：```1000000000000```，1TB。

#### target_max_objects
* **Description**：達到 ```max_objects``` 門檻值時，Ceph 就會回寫或者趕出物件。
* **Type**：Integer。
* **Example**：```1000000```，1M Objects。

#### cache_min_flush_age
* **Description**：達到此時間（單位為秒）時，cache agent 會把某些物件從cache pool flush回到 pool。
* **Type**：Integer。
* **Example**：```600```，10 min。

#### cache_min_evict_age
* **Description**：達到此時間（單位為秒）時，cache agent 會把某些物件從 cache pool 趕出。
* **Type**：Integer。
* **Example**：```1800```，30 min。

## 設定物件的副本數
要設定多副本的 pool 物件副本數，可以執行以下指令：
```sh
ceph osd pool set {poolname} size {num-replicas}
```
> {num-replicas} 包含了物件本身，如果想要物件本身及其兩份複製共計三份，可指定3 。

一個簡單範例：
```sh
ceph osd pool set data size 3
```
可以在每個 pool 上執行這個指令，注意！一個處於 ```degraded mode``` 的物件其副本數小於規範值 ```pool size```，但仍可以接受I/O請求。為保證I/O正常，可用 ```min_size```來設定最低副本數：
```sh
ceph osd pool set data min_size 2
```
這確保資料 pool 裡任何副本數小於 ```min_size```的物件都不會接收到 I/O。

## 獲得物件副本數
若要獲取副本數，可以透過以下指令：
```sh
ceph osd dump | grep 'replicated size'
```
Ceph 會列出 Pool，且顯示``` replicated size```屬性。在預設情況下，Ceph 會建立一個物件的兩個副本（一共三個副本，或是```size```為3）

