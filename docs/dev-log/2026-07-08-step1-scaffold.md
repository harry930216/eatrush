# Step 1 開發日誌 — 專案骨架與環境

> 日期:2026-07-08｜對應 playbook Step 1(上工日)
> 這一步的學習意義:**環境自足力** —「東西跑不起來」的問題(連線、埠、版本)自己收拾。第一課不是寫碼,是讓專案在自己手上活起來。

---

## Step 1 進度 checklist(playbook 施工小步)

- [x] start.spring.io 產骨架(Boot 3.5.16 / Java 21 / 六依賴 / YAML)→ `C:\Users\User\Desktop\eatrush`
- [x] pom.xml groupId `com.example` → `com.eatrush`
- [x] GitHub repo `eatrush` 建好 + 本機首個 commit 推上(`git remote add origin` + `git push -u origin main`)
- [x] 三份 spec md 複製進 `docs/`
- [~] `eatrush-agents.md` → `AGENTS.md` 放根目錄(**已放,但檔名誤成 `AGENTS.md.md`,待改回**)
- [x] 本機 PostgreSQL 活著 + 建空庫 `eatrush`(app 起得來、Swagger 開得出 = 確認連上)
- [x] 加 `springdoc-openapi-starter-webmvc-ui`(**2.8.17**,手動加進 pom)
- [x] `application.yaml`:資料源指向 `eatrush`、`ddl-auto=validate`(升級成**通用版**:`${VAR:預設}` 外部化,見觀念 7)
- [ ] 手寫 `GET /api/health` 回 200(一個 Controller 一個方法)← **Step 1 唯一剩下的**

> 骨架 / 環境 / 版控全通了,只剩 health API(你的產品碼,自己寫)+ 驗證。

---

## AI 檢查結果(2026-07-08)

| 項目 | 狀態 | 說明 |
|---|---|---|
| Boot 版本 | ✅ | 3.5.16(最新 3.x,對齊 UcMarket 3.5.0 同線) |
| Java | ✅ | 21 |
| Java 套件 | ✅ | `com.eatrush`(資料夾 + 主程式 package 宣告皆對) |
| 主程式 | ✅ | `EatrushApplication` |
| 設定檔 | ✅ | `application.yaml`(YAML;`.yaml` 與 spec 的 `.yml` Spring 都讀) |
| 依賴 | ✅ | web / data-jpa / validation / flyway-core / postgresql / lombok 全齊 + 自動帶 `flyway-database-postgresql`(先解掉 PG16+Flyway10 的坑)+ starter-test |
| Security / Redis | ✅ | 未含,刻意排除正確 |
| groupId | ✅ | 已改為 `com.eatrush`(原預設 `com.example`) |
| springdoc | ✅ | `2.8.17`(2.x 對 Boot 3;非數字最大的 3.0.3=Boot 4 用) |

---

## 我做的事(Harry)

**上半場(產骨架)**
- 用 start.spring.io 填表產生骨架,下載解壓到 `Desktop\eatrush`。
- 選項:Maven / Spring Boot 3.5.16 / Java 21 / Packaging = Jar / Configuration = YAML。
- Package name 改成 `com.eatrush`(當時 Group 欄漏改,後補)。
- 依賴勾:Spring Web、Spring Data JPA、PostgreSQL Driver、Validation、Flyway Migration、Lombok。

**下半場(接環境 + 上雲)**
- 改 groupId `com.example` → `com.eatrush`(pom.xml)。
- pom 手動加 springdoc `2.8.17`(先誤填佔位符 `2.8.x` → 查 Maven Central `maven-metadata.xml` 取確切版號修正)。
- `application.yaml` 補資料源,升級成通用版:`url/username/password` 全用 `${VAR:預設}` 外部化。
- Eclipse 匯入(踩兩坑:要用 **Maven** 匯入不是 General;workspace 不能等於專案資料夾 → 另開 `eclipse-workspace`)。
- 跑 `EatrushApplication` → **Swagger UI 開得出來**(`/swagger-ui.html`,顯示 No operations = 還沒寫 controller,正常)。
- `git init` → 首個 commit →(CRLF 警告無害)→ 建 GitHub repo → `git push -u origin main` 推上雲端。

---

## 學到的觀念(AI 解說整理 — 面試素材,能講出來才算會)

### 1. Flyway 是什麼
資料庫 **schema 的版控**。把 schema 寫成一支支 `V1__init.sql`、`V2__seed.sql` 放進 repo,任何機器照順序重播就能從零長出一模一樣的庫(= 可重現性)。跟 git 的關鍵差異:**只能往前疊、已套用的檔不可改**(改了 checksum 會炸),不是「跳回舊 schema」而是「再寫新 migration 往前走」。

### 2. ddl-auto 的三種 + 為何本案只用 validate
它控制 Hibernate 在**啟動時對資料庫「結構(DDL)」**做什麼,拿 entity 對 DB 表:
- `create`:每次啟動砍表重建 → 舊資料全毀。
- `update`:entity 多的欄位/表就自動補上(不刪、不改既有)。
- `validate`:**只檢查、完全不碰 DB**,對不上就啟動失敗。

本案用 `validate`,因為 schema 已整包交給 Flyway 管——**一個庫不能有兩個主人**。Hibernate 退成純看門角色,幫忙抓「entity 與 Flyway 建的表對不齊」的漂移。

### 3. 為何已套用的 migration 不准改
跨機器可重現性靠「每台重播同一串不變的檔」。改舊檔會讓「已照舊檔建好庫的別台機器」與你不一致且沒人察覺;你自己這台也會 checksum mismatch 啟動失敗。所以已套用 = 不可變的歷史事實,要改只能往前加新檔。

### 4. 六個依賴各是什麼 + 為何刻意不勾 Security / Redis
- Web(HTTP 端點 + 內嵌 Tomcat)、Data JPA(ORM)、PostgreSQL Driver(連 PG 的驅動)、Validation(`@Valid` 擋爛請求)、Flyway(schema 版控)、Lombok(省樣板,可選)。
- **不勾 Security**:它在 classpath 上 → auto-config「進門即鎖」,所有路由變 401,會擋掉 Step 3 要用的 Swagger;「登入不是第一步」,Step 7 才裝門。
- **不勾 Redis**:Step 8 才用的讀加速,現在沒跑 Redis server 會卡啟動;它不參與防超賣。
- 原則:**依賴到場時點 = 被需要時點。**

### 5. 為何 Boot 用 3.x 不用 4
Boot 4 存在(2025 底 GA),但刻意留 3.x:①對齊 UcMarket 3.5.0,對照敘事才乾淨;②3.x 生態成熟、可查證資料多,配合「自己排錯」的方法論;③新版新坑,學習成本要花在賣點(併發/RBAC)不是追框架;④3.x 是業界現在主流。**新技術要有理由才上,不是因為它新。**

### 6. Spring Initializr 各欄意義
Group(反向網域組織識別)/ Artifact(專案名,決定主程式類名)/ Package name(程式碼實際套件路徑)/ Packaging = Jar(內嵌伺服器,可 `java -jar`,配 Docker)/ Configuration = YAML(階層式設定,對齊 spec 的 `.yml`)/ Java = 21。

### 7. Externalized config(通用版設定):`${VAR:預設}` + relaxed binding
把會跟著機器變的值(帳密)寫成 `${DB_PASSWORD:post}`——有環境變數就用它、沒有就用冒號後的預設。同一份 committed 檔到處能跑,機器差異從環境注入、不改檔、不進 git。Spring 另有內建 relaxed binding:設 `SPRING_DATASOURCE_PASSWORD` 會自動覆蓋 `spring.datasource.password`。這是「per-machine 設定會漂移、repo-level 設定跟著走」的落實。

### 8. 建「庫」vs 建「表」+ 業界怎麼通用化
`ddl-auto` 只建**表**、建不了**庫**(雞生蛋:要先連上庫才能跑 SQL,而連線需要庫已存在)。連 Flyway 也只建表不建庫。建庫是**環境佈建層**的事:dev/CI 用 Docker `POSTGRES_DB`、prod 用 IaC/DBA、本案 Step 1 先手動 `CREATE DATABASE`。分層的根 = 權限最小化(app 帳號不該能建/刪庫)。「食譜(init 檔)進 repo、產物(資料卷)不進」——跑一次的東西反而最該版控。

### 9. workspace ≠ project(Eclipse)
workspace 是書櫃、project 是書;書不能當書櫃。workspace 要指一個空容器資料夾(如 `eclipse-workspace`),專案各自放它處、用 **Maven 匯入**接進來(不是 General 匯入——那找 `.project` 找不到)。

### 10. springdoc 版本要追 Spring Boot 大版號
1.x→Boot2(javax)/ 2.x→Boot3(jakarta)/ 3.x→Boot4。你是 Boot 3.5 → 選 2.x 最新的 **2.8.17**,別選數字最大的 3.0.3(那是 Boot 4 的)。跟「不用 Boot 4」同一判準:**最新 ≠ 你該用的**。查版本看 Maven Central 的 `maven-metadata.xml`(權威清單)。

### 11. git 用命令列學(不是 GUI)
命令列通用(任何終端 / 伺服器 / CI 都一樣)、看得見自己在做什麼;Eclipse Team 選單是黑盒。核心動詞:`status / add / commit / log / diff / push / pull`,每個動作前後各 `git status` 一次,建立「工作區 → 暫存區 → 提交」三段模型。GUI 只留給看 diff、解衝突。

### 12. 遠端模型:origin 與 push
`git remote add origin <url>` = 給遠端取別名 `origin`;`git push -u origin main` 推分支,`-u` 記住預設,之後只要 `git push`。`git remote -v` 確認接了哪個遠端、`git branch -r` 看遠端分支。

### 13. CRLF vs LF(Windows 換行警告)
`LF will be replaced by CRLF` 是無害警告——Windows Git `core.autocrlf=true` 在做轉換,commit 存進 repo 的仍是 LF。想根治且跨機一致,用 repo-level `.gitattributes`(`* text=auto eol=lf`),不是靠每台各自的 `core.autocrlf`(那會漂移)。

---

## 下一步

1. 把 `AGENTS.md.md` 改回 `AGENTS.md`(重複副檔名會讓「AI 進 repo 找 AGENTS.md」的慣例失效)。
2. (可選)加 `.gitattributes` 正規化換行(`* text=auto eol=lf`),消掉 CRLF 警告。
3. **手寫 `GET /api/health`**(產品碼自己寫;契約:一個 Controller 一個方法,回 200,不引 actuator)。
4. 驗證:`/api/health` → 200;**反向測試**停掉 PG 再啟動 → 應啟動失敗(證明真的連著 DB)→ 開回。
5. 全綠 → commit `step1: 骨架 + health(本機 pg)` ← **這才是 Step 1 真正的出口 commit**。
6. **Step 1 出口思考題**(答得出才算過):schema 為何用 Flyway 管、JPA 只設 validate?`ddl-auto=update` 上正式環境會怎樣?→ 答案已在觀念 2、3。
