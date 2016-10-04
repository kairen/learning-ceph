# Ceph 相關技術筆記與整理
本書主要整理 Ceph 相關技術與資訊，其中包含環境安裝、指令翻譯、概念翻譯與教學範例等。並隨著需求增加更多整合的內容，除了透過自我筆記來對 Ceph 相關技術窺探與實作，也希望能降低其入門與環境部署的難易度。

# 參與貢獻
如果您想一起參與貢獻的話，您可以協助以下項目：
* 幫忙校正、挑錯別字、語病等等
* 提供一些修改建議
* 提出對某些術語翻譯的建議
* 提供 Ceph 相關安裝與教學
* 提供儲存相關安裝與教學

# 透過 Github 進行協作
1. 在 ```Github``` 上 ```fork``` 到自己的 Repository，例如：```<User>/ceph-tutorial.git```，然後 ```clone```到 Local 端，並設定 Git 使用者資訊。

  ```sh
  $ git clone https://github.com/<User>/ceph-tutorial.git
  $ cd ceph-tutorial
  $ git config user.name "User"
  $ git config user.email user@email.com
  ```

2. 修改程式碼或內容後，透過 ```commit``` 來提交到自己的 Repository：

  ```sh
  $ git commit -am "Fix issue #1: change helo to hello"
  $ git push
  ```
  > 若新增採用一般文字訊息，如 ```Add cephfs command example```。

3. 在 GitHub 上提教一個 Pull Request。
4. 持續針對專案的 Repository 進行更新：

  ```sh
  $ git remote add upstream  https://github.com/imac-cloud/ceph-tutorial.git
  $ git fetch upstream
  $ git checkout master
  $ git rebase upstream/master
  $ git push -f origin master
  ```
