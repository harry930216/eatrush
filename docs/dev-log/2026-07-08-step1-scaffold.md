# Step 1 開發日誌 — 專案骨架與環境

> 日期:2026-07-08｜對應 playbook Step 1(上工日)
> 這一步的學習意義:**環境自足力** —「東西跑不起來」的問題(連線、埠、版本)自己收拾。第一課不是寫碼,是讓專案在自己手上活起來。

---

## Step 1 進度 checklist(playbook 施工小步)

- [x] start.spring.io 產骨架(Boot 3.5.16 / Java 21 / 六依賴 / YAML)→ `C:\Users\User\Desktop\eatrush`
- [ ] **pom.xml groupId `com.example` → `com.eatrush`**(檢查發現漏改,待補)
- [ ] GitHub 開 repo `eatrush` + clone + `.gitignore`(Java + IDE)
- [ ] 三份 spec md 複製進 `docs/`
- [ ] `eatrush-agents.md` 改名 **`AGENTS.md`** 放 repo 根目錄
- [ ] 確認本機 PostgreSQL 活著(`SELECT version()`)+ 建空庫 `eatrush`
- [ ] 加 `springdoc-openapi`(Swagger UI)——Initializr 沒有,手動加進 pom
- [ ] `application.yaml`:資料源指向本機 `eatrush` 庫、`ddl-auto=validate`、Flyway 開
- [ ] 手寫 `GET /api/health` 回 200(一個 Controller 一個方法)

> 未打勾的多數是**家機**才做(要開發環境/資料庫);groupId 一行現在就能改。

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
| groupId | ⚠️ | 仍是預設 `com.example`,建議改 `com.eatrush`(pom.xml:11) |

---

## 我做的事(Harry)

- 用 start.spring.io 填表產生骨架,下載解壓到 `Desktop\eatrush`。
- 選項:Maven / Spring Boot 3.5.16 / Java 21 / Packaging = Jar / Configuration = YAML。
- Package name 改成 `com.eatrush`(但 **Group 欄漏改**,仍 `com.example` → 待補)。
- 依賴勾:Spring Web、Spring Data JPA、PostgreSQL Driver、Validation、Flyway Migration、Lombok。

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

---

## 下一步

1. **現在**:改 pom.xml:11 的 groupId 為 `com.eatrush`。
2. **家機**:接續 Step 1 未打勾項(GitHub repo、搬 docs、改 AGENTS.md、建 PG 空庫、springdoc、application.yaml 資料源、health API)。
3. **Step 1 出口思考題**(答得出才算過):schema 為何用 Flyway 管、JPA 只設 validate?`ddl-auto=update` 上正式環境會怎樣?→ 答案已在上方觀念 2、3。
