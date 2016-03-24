# Placement Group States

當檢查叢集的狀態時（ex:執行 ceph -w 或者 ceph -s 指令），Ceph  會 report PG 的狀態。一個 PG 有一個或多個狀態。最佳的情況是 ```active + clean ```。

* **Creating**：Ceph仍然在創建配置組。

* **Active**：Ceph將處理到配置組的請求。

* **Clean**：Ceph已經正確同步配置組裡的所有對象。

* **Down**：擁有必要數據的副本down了，所以，配置組下線了。

* **Replay**：配置組正等待客戶端重放操作，在OSD崩潰之後。

* **Splitting**：Ceph的配置組被分裂分成多個配置組. (功能性?)

* **Scrubbing**：Ceph正在檢查配置組的不一致性。

* **Degraded**：Ceph還沒有正確同步配置組裡的一些對象。

* **Inconsistent**：Ceph檢測配置組裡的對象的一個或多個副本的不一致性（比如，對像大小不對，恢復完成後一個副本里的對象丟失了，等）。

* **Peering**：配置組正在進行peering操作

* **Repair**：Ceph正在檢查配置組，並且修復它發現的任何不一致性（如果可能）。

* **Recovering**：Ceph正在移動/同步對象和它們的副本。

* **Backfill**：Ceph正在掃描和同步配置組的所有內容，而不是從最近的操作日誌來推斷哪些內容要同步。回填是恢復的一個特例。

* **Wait-backfill**：配置組正排隊準備回填。

* **Incomplete**：Ceph檢測到配置組缺少一段必要的歷史日誌。如果你看到這個狀態，請報告bug並嘗試啟動任何失敗的可能包含所需信息的OSD。

* **Stale**：配置組處於一個未知的狀態- 自從配置組映射改變後，監視器沒有收到更新。

* **Remapped**：配置組臨時映射到一個跟CRUSH指定的不同的OSD集合。

