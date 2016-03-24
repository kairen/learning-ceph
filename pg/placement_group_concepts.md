# Placement Group Concepts

當你執行像ceph -w，ceph osd dump，和其他跟配置組相關的命令時，Ceph可能返回以下值：

* **Peering**：使存儲在配置組裡的所有OSD對配置組裡的所有對象(和他們的元數據)的狀態達成一致的過程。注意：狀態的達成一致不表示他們都獲得了最新的內容。

* **Acting Set**：OSD(或者一些epoch)的有序集合，這些OSD負責具體的配置組。

* **Up Set**：OSD負責特定配置組為了一個根據CRUSH特定epoch的有序列表。通常這與Acting Set相同，除非在OSD映射裡，Acting Set已經通過pg_temp明顯地被重寫了。

* **Current Interval  or  Past Interval**：在特定的配置組的代理設置和UP設置不會改變的期間，OSD映射epochs的序列。

* **Primary**：代理設置的成員（並且第一按照慣例），負責協調同等操作，也是配置組裡唯一的接受客戶端初始寫數據的OSD。

* **Replica**：配置組裡非主要OSD ( 並且它已被確認為被主要的OSD激活 )。

* **Stray**：不屬於當前Acting Set成員的OSD，但也不是說可以刪除它的副本。

* **Recovery**：確保配置組裡所有對象的副本都在Acting Set的所有OSD上。一旦Peering執行，主OSD開始接受寫操作，恢復操作在後台進行。

* **PG Info**：配置組創建時期的基本元數據，配置組大部分最新寫入版本，最後epoch開始, 最後epoch 狀態為clean, 和在當前時間間隔的開始。任何inter-OSD關於配置組的通訊包含PG信息,為了讓任何知道一個配置組存在的（或曾經存在的）OSD也有一個在最後epoch狀態為clean或最後一個epoch開始的下限

* **PG Log**：配置組裡對象的最新的更新集合。注意：在Acting Set裡所有OSD到達某個點後，這些日誌會被截斷。

* **Missing Set**：每個OSD說明更新日誌條目，如果它們表示更新的對象的內容，增加了該對象所需的更新列表。這個列表為了<OSD,PG>調用  Missing Set。

* **Authoritative History**：所有操作的有序集合，一旦完成，OSD的副本將到達最新。

* **Epoch**：一個（單調遞增）的OSD映射版本號。

* **Last Epoch Start**：擁有為一個特定的配置組的代理設置裡的所有節點的最後時期，這由Authoritative History所決定的。在這一點上，對等操作被視為是成功的。

* **up_thru**：在一個主要部分能順利完成對等的過程之前，它必須通過現有的osd映射Epoch，由在osd映射上設置監視器的up_thru來確認一個狀態為active監視器。這幫助對等操作那些先前對等操作在一系列的失敗後從沒完成的代理設置，例如下面的第二個時間間隔後：
    * acting set  = [A,B]
    * acting set  = [A]
    * acting set  = []之後不久(比如,同時失效，但交錯的檢測等)
    * acting set  = [B] (B重啟了, A沒有)


* **Last Epoch Clean**：最後的版本號，此時配置組的代理設置裡的所有節點已經完全的到達最新（配置組日誌和對象內容）。此時，可以認為恢復成功完成。