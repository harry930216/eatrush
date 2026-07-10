# 環境日誌 — 換第二台機器:Flyway「空庫」與 Eclipse stale build

> 日期:2026-07-09｜**延伸自 Step 2(Flyway V1/V2)— 非新步驟,是「環境/工具鏈」篇**
> 學習意義:Flyway 的「遷移檔」與「套用紀錄」分屬 **git 世界**與**資料庫世界**,跨機器只搬前者不搬後者;而 IDE(Eclipse)的 build 產物會與磁碟脫節,是 `No migrations found` 的真兇。
> 為什麼獨立成篇:這episode 不對應任何施工 step——它是把 Step 2 的成果搬到第二台機器時撞到的環境坑,塞進 step 日誌會誤導。

---

## 情境

在**筆電(User 帳號,Eclipse)** `git pull` 拿到 Step 2 的 V1/V2 後啟動 app,發現 `eatrush` 資料庫**只有庫名、完全沒有表、沒有資料**。桌機那顆是正常的(七表 + seed)。一度誤判「要 drop 重建」。

---

## 誤判 → 修正:空庫不是「壞了」,是「還沒煮」

- **drop 是給「狀態壞掉/髒掉」的 DB 用的**(套到一半、checksum 打架、殘留舊表)。
- **全空的庫 = 乾淨空殼**,drop 完還是空殼,白做工。Flyway 最愛空庫,直接跑就會從 V1 老實套到 V2。
- 判準一句話:**空 = 還沒做,不是做壞了。** 空庫的正確動作是「跑 app 讓 Flyway 套用」,不是 drop。

---

## 核心觀念 1:Flyway 的真相分兩半,走不同的路

| 東西 | 跟著誰走 | 住在哪 | 上 GitHub? |
|---|---|---|---|
| 遷移檔(V1/V2 的 SQL) | **git** | 專案資料夾 | ✅(就兩個文字檔) |
| `flyway_schema_history`(套用紀錄) | **資料庫** | 每台電腦本機的 DB | ❌ |
| 七表 + seed 資料 | 資料庫 | 每台電腦本機的 DB | ❌ |

**關鍵**:git 只搬**檔案**,不搬「已經套用過」這件事。桌機與筆電是兩顆不同的 PostgreSQL = 兩份獨立的 `flyway_schema_history`。**每台第一次啟動,Flyway 才對「那台自己的 DB」套用一次、然後登記進那台的歷史表。** 所以「桌機有 seed、筆電沒有」是正常機制,不是 bug。

> 記憶鉤(食譜比喻):GitHub = **食譜書**(只有文字);每台電腦的 DB = 各自的**廚房+冰箱**;Flyway = **廚師**;`flyway_schema_history` = 冰箱上的**打勾清單**。`git pull` 只影印食譜書到新機器,冰箱還是空的——要**廚師進廚房煮**(跑 app)冰箱才有菜。

---

## 核心觀念 2:遷移不可變 + checksum(複習 Step 2,這次用在跨機器)

`flyway_schema_history` 除了「打勾」,還記了每個檔當初的**指紋(checksum)**。下次啟動 Flyway 拿現在的檔跟清單上的指紋比對,對不上就喊 `checksum mismatch`。這也是「已套用的遷移不可改」的機制面(Step 2 已用反向驗證親眼看過)。

---

## 核心觀念 3:dev 的復原法 vs prod

- **dev(沒有珍貴資料)**:把庫清空 → Flyway 以為第一次 → 從 V1 重放到 V2 = 乾淨的 pristine 狀態。這叫 **roll-forward from clean**(`DROP SCHEMA public CASCADE; CREATE SCHEMA public;` 或整顆 `DROP DATABASE / CREATE DATABASE`)。
- **prod(資料是命)**:**永不 drop**,要修只能寫**新的前進遷移 V3** 去補正。
- 面試句:「dev 可以 drop replay、prod 只能 roll forward。」

---

## 真兇定位:讀 app 啟動 log

Flyway 連上了 DB,卻找不到任何遷移檔。關鍵這幾行:

```
FlywayExecutor : Database: jdbc:postgresql://localhost:5432/eatrush (PostgreSQL 18.4)  ← 成功連上庫
DbValidate     : Successfully validated 0 migrations                                    ← 只驗到 0 個
DbValidate     : No migrations found. Are your locations set up correctly?              ← Flyway 自喊:找不到食譜
DbMigrate      : Current version of schema "public": << Empty Schema >>
DbMigrate      : Schema "public" is up to date. No migration necessary.                 ← 沒東西要煮,收工
```

**不是 Flyway 壞、不是連不上 DB——是它掃到 0 個遷移檔。**

---

## 根因:classpath vs `target/classes`,加上 Eclipse 不察覺 IDE 外的變動

- Flyway 預設去 `classpath:db/migration` 找;**執行期那位置 = `target/classes/db/migration/`**,不是 `src` 底下那份。
- log 首行顯示 app 從 `...\target\classes` 跑。所以問題收斂成:**V1/V2 有沒有被複製進 `target/classes/db/migration/`?**
- **Eclipse 不會自動察覺「在它外面」發生的檔案變動**。在終端機 `git pull`,Eclipse 腦中那份專案還是舊的 → 它 build 出來的 `target/classes` 沒有那兩個新檔 → Flyway 掃到 0 個。
- 這與稍早那次「改了沒炸」同一種病:**stale `target/classes`**(IDE build 產物與磁碟脫節)。

---

## 修法

**繞過 IDE(最省心,實測成功)**
```
./mvnw clean spring-boot:run
```
`clean` 砍掉整個 `target`;重建時 Maven 把 `src` 的 resources(含 V1/V2)**重新複製**進 `target/classes`。→ 本次即以此讓筆電套用 V1/V2、seed 進庫(表已驗證存在)。

**Eclipse 路線(要用綠色 Run 鈕時)**
1. 選中專案按 **F5(重新整理/Refresh)** — 讓 Eclipse 重掃磁碟、看見新檔(最關鍵,最常被忘)。
2. 頂部選單列 **專案(Project) → 清除…(Clean…)** — 砍 build 重做,把 resources 複製進 `target/classes`。※ Clean **不在**右鍵選單,只在頂部「專案」選單。
3. 展開 `target/classes/db/migration/` 確認 **V1、V2 真的在**。
4. 重跑,log 應出現 `Migrating schema "public" to version 1 ... to version 2`。

**習慣**:凡在 IDE 外面 pull / 改檔 → **先 F5 → 再 Clean**;或乾脆命令列 `mvnw` 跑。

---

## 延伸坑 & 紅鯡魚

- **延伸坑(順序反過來的雷)**:若 DB 的 `flyway_schema_history` 已記錄 V1/V2(這次套過了),但之後用**舊的 `target/classes`**(缺檔)去跑 → Flyway 反而報 **`applied migration not resolved`**(歷史說套過、本地卻找不到檔)。所以要用 Eclipse 綠鈕跑,務必先 Clean 讓 build 補上檔。
- **紅鯡魚 1**:`PostgreSQL 18.4 is newer than this version of Flyway ...` — 只是 WARN,PG18 照跑(桌機同樣 PG18,seed 好好的)。
- **紅鯡魚 2**:`Found 0 JPA repository interfaces` — 正常,Repository 還沒寫(Step 3 的事)。

---

## 一句話帶走

**跨機器同步搬的是「食譜」不是「菜」;菜要在每台廚房各煮一次。而 IDE 的 build 產物會偷偷過期——`No migrations found` 十之八九是 `target/classes` 沒跟上,`mvnw clean` 或 F5+Clean 解決。**
