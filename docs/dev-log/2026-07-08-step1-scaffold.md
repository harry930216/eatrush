# Step 1 開發日誌 — 專案骨架與環境

> 日期:2026-07-08｜對應 playbook Step 1(上工日)
> 這一步的學習意義:**環境自足力** —「東西跑不起來」的問題(連線、埠、版本)自己收拾。第一課不是寫碼,是讓專案在自己手上活起來。

---

## Step 1 進度 checklist(playbook 施工小步)

- [x] start.spring.io 產骨架(Boot 3.5.16 / Java 21 / 六依賴 / YAML)→ `C:\Users\User\Desktop\eatrush`
- [x] pom.xml groupId `com.example` → `com.eatrush`
- [x] GitHub repo `eatrush` 建好 + 本機首個 commit 推上(`git remote add origin` + `git push -u origin main`)
- [x] 三份 spec md 複製進 `docs/`
- [x] `eatrush-agents.md` → `AGENTS.md` 放根目錄(檔名 `AGENTS.md.md` 已改回 `AGENTS.md`,commit b9844c3 / 8c04893)
- [x] 本機 PostgreSQL 活著 + 建空庫 `eatrush`(app 起得來、Swagger 開得出 = 確認連上)
- [x] 加 `springdoc-openapi-starter-webmvc-ui`(**2.8.17**,手動加進 pom)
- [x] `application.yaml`:資料源指向 `eatrush`、`ddl-auto=validate`(升級成**通用版**:`${VAR:預設}` 外部化,見觀念 7)
- [x] 手寫 `GET /api/health` 回 200(一個 Controller 一個方法)— **code 完成 + reviewed**,回 `{"status":"Good"}`
- [x] 正向驗證:Swagger `GET /api/health` → 200 + `{"status":"Good"}`(application/json;Swagger UI 長出該端點)
- [x] 反向驗證(不可跳):停本機 PG → 重啟 app → 啟動失敗 `SQLState 08001 Connection to localhost:5432 refused`(postmaster 沒在聽)→ 證明真連 DB → 開回 PG 恢復
- [x] commit + push 上 GitHub(`eb81aab` + `3ff03bd`;⚠️ 訊息未用 `stepN:` 前綴,下次起改用 `step2:` …)
- [ ] 出口思考題口頭複述(schema 為何 Flyway / `ddl-auto=update` 上正式會怎樣)— 待補

> 骨架 / 環境 / 版控 / health API 全通,**正向 + 反向驗證通過、已 push 上 GitHub**。Step 1 功能面收工;僅剩出口思考題口頭複述待補。

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
- 二次 `git push`(推日誌更新):輸出多行但實際只 5.41 KiB——git 只送 delta,正常。
- 上 GitHub 檢查 repo:抓到 `.metadata`(Eclipse workspace 殘留)誤入 repo + `AGENTS.md.md` 檔名錯 → 給修正(`git rm -r --cached .metadata` + `.gitignore` 加 `.metadata/` + `git mv AGENTS.md.md AGENTS.md`)。

**Health 端點(自己手寫的第一支產品碼)**
- 用 comment-driven 起手:先在檔頂寫中文步驟(請求進 DispatcherServlet → component scan → 查 handler mapping → 呼叫方法 → message converter 寫 body,狀態碼預設 200),再一格格填。
- 設計決定(回傳型別):在 `String "OK"` 與結構化 JSON 之間,選了 `Map<String,String>` 回 `{"status":"Good"}` — 理由:一次拿到「正規形狀(JSON + status 欄位)」又不必另外定義型別;actuator 那套刻意不引(playbook 契約),留當面試彈藥。
- 方法名 `isMainAlive` → `checkHealth`(`is` 前綴慣例是給回傳 boolean 用;這支回 Map,改名才名實相符)。
- 成品:`@RestController` + `@GetMapping("/api/health")` + `public Map<String,String> checkHealth()` → `return Map.of("status","Good");`。

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

### 14. health check 端點是什麼
`GET /api/health` → 200,回答「服務還活著嗎」。真實用途:負載平衡器 / K8s probe / 監控系統定期打它,判斷 app 死活、決定導不導流或重啟。Step 1 拿它當第一支端點,因為它**不依賴任何業務**(不碰 DB / 登入 / entity),是驗證「骨架 + web 層」最乾淨的探針;playbook「不引 actuator」是要你**手寫**、學會最小的「Controller → 方法 → 回應」閉環。

### 15. @Controller vs @RestController
`@RestController` = `@Controller` + `@ResponseBody`。差別在**回傳值的身分**:`@Controller` 回的 String 被當「view 名稱」(交模板引擎找 HTML);`@RestController` 回的東西**直接寫進 response body**(String→text、物件→Jackson 轉 JSON)。REST API 全用後者。`@ResponseBody` 也可單掛在方法上;`@RestController` 只是把它一次套到整個 class。

### 16. 路由 = 「路徑 + 動詞」兩維
啟動時 `RequestMappingHandlerMapping` 掃 controller,把每支方法登記成「RequestMappingInfo(路徑 + 動詞…)→ 方法」。請求進 `DispatcherServlet`(總機)拿「路徑 + 動詞」查表命中。**只用路徑不夠**——同一條 `/api/menu/5`,GET(看)與 DELETE(刪)意圖不同,得靠動詞分。分流:路徑不存在→404、路徑在但動詞不對→405。`@GetMapping` = `@RequestMapping(method=GET)` 的縮寫(composed annotation);class 級 `@RequestMapping("/api")` 會與方法級路徑**相加**。動詞語意:GET = 安全(safe)+ 冪等(idempotent),探針天生該用 GET。

### 17. 誰設 200 + 兩個「status」別混
HTTP 200 **不是被判斷出來的**,是 `HttpServletResponse` 的**出廠預設**;方法正常回傳、沒人改狀態碼 → 維持 200。要變才需主動出手(丟例外→exception resolver 給 4xx/5xx;`@ResponseStatus` / `ResponseEntity` 自訂)。**關鍵區分**:HTTP 狀態碼 `200`(傳輸層,在狀態行)≠ body 裡的 `"status":"Good"`(應用層,你自取的欄位名),兩者無關——回 `"UP"` 不會「造成」200。(Step 3 起會親手玩狀態碼:建菜 201、庫存不足 409、找不到 404、`@Valid` 擋下 422。)

### 18. 泛型(generics)為何存在 + Map 概念
- **泛型** = 給容器貼「裝什麼型別」的標籤。好處:①**型別安全**——放錯型別在**編譯期**就擋,不必等執行期爆 `ClassCastException`;②取值**免強制轉型**。Java 5 前集合裝 `Object`,錯誤要 runtime 才炸;泛型把它提前到 compile time(貼標籤 = 早發現 = 便宜)。
- **Map** = 鍵值對(key-value)集合,用 **key** 查 value(對比 List 用 **index** 查)。兩個型別參數 `Map<K,V>` 是因為有 key、value 兩種角色(List 只一種故一個參數)。`Map<String,String>` = 字串查字串;Jackson 把每組 key-value 轉成 JSON 的每個欄位,故 `Map.of("status","UP")` → `{"status":"Good"}`。
- **import 消歧**:`Map` 選 `java.util.Map`(標準庫集合),不是 `org.hibernate.mapping.Map`(Hibernate 內部映射類)。同名型別看**套件**分辨。

---

## 踩過的坑(troubleshooting — README 素材 / 面試證據)

> 格式:現象 → 原因 → 解法 → 學到。前六條是骨架/匯入期,後三條是版控期。

1. **Initializr groupId 漏改** — pom `groupId` 還是 `com.example`,但 Java 套件已是 `com.eatrush`。原因:只改了 Package name 欄,Group 欄沒動。解法:pom `<groupId>` 改 `com.eatrush`。學到:Group(Maven 座標)與 Package name(程式碼套件)是兩個獨立欄位。
2. **springdoc 版本填成佔位符 `2.8.x`** — `...:jar:2.8.x was not found`。原因:把「某個小版」的佔位符 `x` 照字面打成版本。解法:查 Maven Central `maven-metadata.xml` → 填確切 `2.8.17`。學到:版本要填實際數字,查權威清單不猜。
3. **差點選 springdoc 3.0.3** — 清單最新是 3.0.3。原因:springdoc 大版號追 Boot 大版號(3.x=Boot4)。解法:Boot 3.5 → 選 2.x 最新的 2.8.17。學到:最新 ≠ 你該用的。
4. **Eclipse 匯入用錯類型** — 匯入後專案不出現。原因:用了 General「Existing Projects」(找 `.project`),但 start.spring.io 專案沒那檔。解法:改用 Maven「Existing Maven Projects」(讀 pom)。學到:Maven 專案用 Maven 匯入。
5. **workspace = 專案資料夾** — 匯入時警告「Can't import project from an existing workspace folder」。原因:開 Eclipse 時 workspace 選到專案資料夾本身。解法:切 workspace 到別處(`eclipse-workspace`),專案留原地再匯入。學到:workspace ≠ project(觀念 9)。
6. **application.yaml 註解用 Tab** — 註解行用了 Tab 縮排。原因:貼上帶入 Tab。解法:註解移到最左或刪掉;YAML 結構縮排一律空格。學到:YAML 不吃 Tab。
7. **`.metadata` 被 commit 進 repo** — GitHub 上冒出 `.metadata` 資料夾。原因:第 5 條那次 workspace=專案,Eclipse 在專案內建了 `.metadata`,`git add .` 掃進去;`.gitignore` 沒涵蓋。解法:`git rm -r --cached .metadata` + `.gitignore` 加 `.metadata/`。學到:早期的錯會留後遺症;`git add .` 前先 `git status` 看清掃了什麼。
8. **AGENTS.md.md 雙副檔名** — 根目錄檔名多一截 `.md`。原因:打了 `.md` 又被自動加 `.md`。解法:`git mv AGENTS.md.md AGENTS.md`。學到:重複副檔名會讓「AI 找 AGENTS.md」慣例失效。
9. **CRLF/LF 推送警告** — `LF will be replaced by CRLF` 一整片。原因:Windows Git `core.autocrlf=true` 轉換換行。解法(可選):`.gitattributes` 加 `* text=auto eol=lf`。學到:無害;repo-level 設定才可攜,per-machine 會漂移。
10. **`@GetMapping` 底下沒方法** — 標記後面直接 `}`,編譯報「預期宣告卻遇到 `}`」(`<identifier> expected`)。原因:annotation 是修飾語,一定要修飾對象;`@GetMapping` 修飾的是「它下面那支方法」,但方法還沒寫,標籤貼在空氣上。解法:補上方法。學到:annotation 不能懸空,它一定綁著下面某個宣告(class / 方法 / 欄位)。
11. **`Map` import 兩個同名候選** — Eclipse 快速修正列出 `java.util.Map` 與 `org.hibernate.mapping.Map`。原因:不同套件有同名型別。解法:選 `java.util.Map`(標準庫集合);`org.hibernate.mapping.Map` 是 Hibernate 內部映射類,不相干。學到:同名型別看**套件**分辨,`java.util.*` 幾乎總是你要的(`java.util.Date` vs `java.sql.Date` 同理)。

---

## 下一步(接續:Step 1 出口)

> 前置全完成(骨架/環境/版控/AGENTS.md/health code)。剩下就是**驗證 → 思考題 → commit**。

1. **跑驗證(你自己跑,人肉紅綠燈)**:
   - 起動 `./mvnw spring-boot:run`(或 Eclipse Run As)→ log 無 ERROR、見 `Started EatrushApplication`。
   - 正向:`GET /api/health` → 200 + `{"status":"Good"}`(用 `python -X utf8` 打);Swagger UI 現在該長出 `/api/health`(先前 No operations)。
   - **反向(不可跳)**:停本機 PostgreSQL → 重啟 app → 應**啟動失敗**(datasource + `validate` 連不上)→ 讀最深 `Caused by`(自救梯第一級)→ 開回 PG 再確認正常。
2. 答**出口思考題**(答得出才算過):schema 為何用 Flyway 管、JPA 只設 `validate`?`ddl-auto=update` 上正式環境會怎樣?→ 答案在觀念 2、3。
3. 全綠 + 答得出 → `git commit`:`step1: 骨架 + health(本機 pg)`。
4. AI 回寫本 dev-log「驗證通過」段(含反向那個 `Caused by` 長相)給你 review → Step 1 收工,進 **Step 2(建表 + seed)**。
