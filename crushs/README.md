# Ceph CRUSH 基本規則整理
Ceph 透過 CRUSH（Controlled, Scalable, Decentralized Placement of Replicated Data） 演算法來計算資料儲存位置，來確認如何儲存和檢索資料，CRUSH 授權 Ceph client 可以直接連接 OSD，而不再是透過集中式伺服器或者中介者來儲存與讀取資料。該演算法與架構特性使 Ceph 可以避免單一節點故障問題、效能瓶頸與擴展的限制。

CRUSH 是一種偽隨機資料分散算法，能夠再階層結構的儲存叢集很好地分散物件的副本，該演算法實作了偽隨機(確定性)的函式，會透過輸入```o​​bject id```、```object group id```等參數，來回傳一組儲存裝置（即儲存物件的副本）。CRUSH 有以下兩個重要的資訊，
* **Cluster Map**：被用來描述儲存叢集的階層結構。
* **CRUSH Rule**：被用來描述副本的分散策略。

CRUSH 有以下幾個特色：
* 任何元件都可以被獨立的計算出每個物件的所在位置，即去中心化。
* 只需要少量的 Metadata（Cluster Map），通常在刪除或新增 OSD 時，Metadata 才會變動。

### CRUSH 簡單操作
要取得目前叢集的 CRUSH Map 可以執行以下指令：
```sh
$ ceph osd getcrushmap -o {compiled-crushmap-filename}
```

由於取得的 CRUSH Map 需要經過反編譯才能看到正確資訊，可以執行以下指令來進行反編譯：
```sh
$ crushtool -d {compiled-crushmap-filename} -o {decompiled-crushmap-filename}
```
> ```-d```為 binary 的 map 檔，```-o```要輸出的檔案名稱。

當完成編輯自己的 map 後，可以透過以下指令來編譯：
```sh
$ crushtool -c {decompiled-crush-map-filename} -o {compiled-crush-map-filename}
```

最後要將 map 應用在自己的叢集，可以透過以下指令：
```sh
$ ceph osd setcrushmap -i {compiled-crushmap-filename}
```

### Ceph CRUSH Rule: 1 Copy SSD and 1 Copy SATA
該範例將讓我們使 primary 副本放置在屬於 SSD 裝置的 OSD，而第二副本放置於 SATA 裝置的 OSD。
```sh
rule ssd-primary-affinity {
    ruleset 0
    type replicated
    min_size 2
    max_size 3
    step take ssd
    step chooseleaf firstn 1 type host
    step emit
    step take sata
    step chooseleaf firstn -1 type host
    step emit
}
```
> 這亦需要正確設定 ```Primary Affinity```，首先將編輯```ceph.conf```檔案，加入以下內容：
```sh
[mon]
...
mon osd allow primary affinity = true
...
```
然後透過指令來修改：
```sh
$ ceph osd primary-affinity osd.<id> 0
```

###Ceph CRUSH Two Copies in One Rack
該範例有關如何儲存三副本數，在第一個 rack 會儲存兩份，在第二個 rack 會儲存一份。
```sh
rule 3_rep_2_racks {
   ruleset 1
   type replicated
   min_size 2
   max_size 3
   step take default
   step choose firstn 2 type rack
   step chooseleaf firstn 2 type host
   step emit
}
```
