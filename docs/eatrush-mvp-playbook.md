# EatRush MVP 施工手冊(playbook)— 施工迴圈(loop)驅動檔 v2

> 本檔只管 **做什麼(HOW)+ 怎麼證明做對(VERIFY)+ 為什麼值得學(學習意義)**。所有設計的為什麼(WHY)在 `2026-07-07-eatrush-design.md`(下稱 spec)— 引用不複製,兩檔不打架。
>
> **本輪目標不是趕工,是閉環開發能力**:靠可查證的資料+自己的排錯完成整個專案;AI 只在自救梯最後一級出現。

## 迴圈規則

1. **一次一小步**:只做當前小步,做完立刻跑它的驗證,綠了才前進。忍住「順手多寫」。
2. **動工前先讀驗證清單**:知道「怎麼算做對」再寫(人肉紅綠燈(red-green))。
3. **反向驗證不可跳**:每步至少一次「故意弄壞 → 確認會炸 → 改回」。恆綠的驗證是心安,不是驗證。
4. **前夜預習用自測題過關**:答不出**去查**(每步表內附去哪查),不是去問。查兩小時=練習;問十秒=外包。
5. **卡關自救梯(四級,一級約 20–30 分鐘,總計約 90 分鐘再升級)**:
   - 第一級:把錯誤訊息**從頭讀到尾**,找最深那層「Caused by」,拿關鍵句去搜
   - 第二級:查官方文件對應節(預習表已給入口)
   - 第三級:最小重現(minimal reproduction)— 開一個空測試或空端點,把問題從專案裡剝出來單獨養
   - 第四級:才是 AI,且規定問法:「我卡在 X,錯誤全文 Y,試了 A/B,我的假設是 Z」— 帶著假設求助,連求助都在練
   - **收尾(不分哪一級解決的)**:花 10 分鐘寫排錯筆記(troubleshooting)進 `docs/troubleshooting/`,格式照你們 UcMarket 的慣例:問題現象 → 真正原因 → 解法 → 學到什麼。這是閉環的最後一步,也是 README 素材與面試證據
6. **出口儀式**:驗證全勾 → 自問思考題(答不出=回 spec 該節重讀,別硬過)→ commit(訊息講得出「這段在防什麼」;中英不拘,短就好)。
7. 時程爆炸砍法(spec §12):①砍商家頁 → ②砍客人頁美化 → ③全砍(Swagger 保底)。**永不砍 Step 4–6。**

---

## Step 1|上工日(半天–1 天)｜spec §3、§12-1

**學習意義**:環境自足力 — 「東西跑不起來」的問題(連線、埠、版本)自己收拾。工程師第一課不是寫碼,是讓專案在自己手上活起來。

> **Docker 不在今天。** 依賴到場時點=被需要時點:Docker Desktop 在 Step 6 前夜裝(Testcontainers 硬需求)、compose 在 Step 8 才整包化。今天用你 UcMarket 就裝好的**本機 PostgreSQL**,目標是明天就寫業務代碼。省下的 1–2 天進 Step 4 當緩衝。

### 前夜預習(自測題)

| 你要能回答 | 去哪查 |
|---|---|
| Flyway 是什麼?為什麼 schema 要當代碼管? | Flyway 官方「Getting Started」;關鍵字 `flyway spring boot` |
| `ddl-auto` 的 validate / update / create 差在哪?為什麼本案只用 validate? | 關鍵字 `hibernate ddl-auto` |

### 施工小步

1. GitHub 開 repo `eatrush`、clone、.gitignore(Java + IDE);spec 三份 md 複製進 `docs/`;把 `eatrush-agents.md` 改名 **`AGENTS.md`** 放 repo 根目錄(AI 接手指南 — 任何 AI 進來先知道紅線)。
2. 確認本機 PostgreSQL 活著:`SELECT version()`(UcMarket 那顆即可);建空庫 `eatrush`(pgAdmin 或 `createdb`)。
3. start.spring.io 產骨架:Maven、Java 21、Spring Boot 3.x。依賴**只勾**:Web、Data JPA、PostgreSQL Driver、Validation、Flyway、Lombok(可選)。**刻意不勾 Security 與 Redis** — Security 一進來預設全路由 401,會跟 Step 3 的 Swagger 打架;分別到 Step 7 / Step 8 才加(「登入不是第一步」的落實)。
4. 加 springdoc-openapi(Swagger UI)— Step 3 起手動驗證的主戰場。
5. `application.yml`:資料源指向本機 `eatrush` 庫、`ddl-auto=validate`、Flyway 開。
6. 手寫 `GET /api/health` 回 200(一個 Controller 一個方法,不引 actuator)。

### 完成形檔案樹(這步新增)

```
eatrush/
├─ docs/(spec 三份)
├─ pom.xml
├─ src/main/java/com/eatrush/
│  ├─ EatrushApplication.java
│  └─ controller/HealthController.java
└─ src/main/resources/application.yml
```

### 手動驗證

- [ ] `SELECT version()` → 回 PG 版本字串
- [ ] `./mvnw spring-boot:run` 啟動無 ERROR
- [ ] `/api/health` → 200;`/swagger-ui.html` 開得出來
- [ ] **反向**:停掉本機 PostgreSQL 服務再起 app → 啟動失敗(證明真的連著 DB)→ 開回;連不上先翻你們那篇 postgresql-test-troubleshooting

### 出口

- 思考題(spec §12-1):為什麼 schema 用 Flyway 管、JPA 只設 validate?`ddl-auto=update` 上正式環境會發生什麼?
- [ ] commit:`step1: 骨架 + health(本機 pg)`

---

## Step 2|建表與 seed(1 天)｜spec §4 全節、§12-2

**學習意義**:把 spec §4 的紙上表格翻譯成真 DDL — 「設計→schema」的翻譯能力;Flyway = 資料庫的 git,從此你的庫可以在任何機器上從零重生。

### 前夜預習(自測題)

| 你要能回答 | 去哪查 |
|---|---|
| Flyway 檔名 `V1__xxx.sql` 的規則?checksum 是什麼、改了已套用的檔會怎樣? | Flyway 官方「Migrations」節 |
| PostgreSQL 的 JSONB 怎麼宣告?JSON 與 JSONB 差在哪? | PostgreSQL 官方文件「JSON Types」;關鍵字 `postgresql jsonb` |
| 複合主鍵(composite key)的 DDL 寫法? | 關鍵字 `postgresql composite primary key` |

### 產物契約

| 產物 | 內容 |
|---|---|
| `V1__init_schema.sql` | 七張表,逐欄對照 spec §4 與 ER 圖。三個唯一鍵不可漏:member.email、meal_order.idempotency_key、permission.code;rejected_items 用 JSONB 可空;role_permission 複合主鍵(role, permission_id) |
| `V2__seed.sql` | 照 spec §4 seed:2 方案、5 菜(和牛 stock=5 / required_level=2)、3 權限+矩陣(OWNER 全有、STAFF 只 ORDER_STATUS_MANAGE)、4 帳號(password_hash 先塞佔位字串,Step 7 開 V3 補真值) |

這步**不寫任何 entity(實體)** — entity 跟著用到它的步驟走(Step 3 起);validate 模式下「有表沒 entity」不炸、「有 entity 但對不齊」才炸,它會替你抓 DDL 漂移。

### 完成形檔案樹(這步新增)

```
src/main/resources/db/migration/
├─ V1__init_schema.sql
└─ V2__seed.sql
```

### 手動驗證

- [ ] `DROP DATABASE eatrush; CREATE DATABASE eatrush;` 後啟動 app → 日誌見 Flyway 套 V1、V2(從零重建=可重現性證明)
- [ ] psql `\dt`(或 pgAdmin)→ 7 張表 + flyway_schema_history
- [ ] `SELECT name, stock, required_level FROM menu_item` → 5 道菜、和牛 5 份/等級 2
- [ ] role_permission JOIN permission → OWNER 3 筆、STAFF 1 筆
- [ ] **反向**:改 V1 檔任一字元重啟 → checksum 炸(migration 不可變的保護)→ 改回

### 出口

- 思考題(spec §12-2):七張表每張「為何存在」不看文件講一遍;rejected 用 JSON、accepted 用表的理由。
- [ ] commit:`step2: 七表 schema + seed`

---

## Step 3|商家資料線(2–3 天)｜spec §6.3、§9、§10、§12-3

**學習意義**:Spring 分層閉環的第一整圈 — entity→repository→service→controller→DTO 一條線自己拉通;外加例外收口(exception spine)。這步做完,你就擁有「蓋任何一條 CRUD 線」的模板能力,Step 4 起全是這個模式的變奏。

### 前夜預習(自測題)

| 你要能回答 | 去哪查 |
|---|---|
| @MappedSuperclass 和 @Entity 差在哪?為什麼 BaseEntity 自己不是一張表? | Hibernate 官方「Inheritance」;關鍵字 `mapped superclass vs entity` |
| @RestControllerAdvice + @ExceptionHandler 怎麼攔?兩個 handler 都匹配時誰贏(子類優先)? | Spring 官方「Exception Handling」;關鍵字 `controller advice handler order` |
| 一級快取(persistence context)是什麼?為什麼 @Modifying 要配 clearAutomatically? | Spring Data JPA 官方「Modifying Queries」節 |
| DTO 和 entity 為什麼分兩套?@Valid 在哪層生效、炸出什麼例外? | 關鍵字 `spring validation MethodArgumentNotValidException` |

### 類別契約(架構=定死;方法**體**=你的練習,一行不給)

| 產物 | 責任(一句話) | 公開方法(中文簽名) |
|---|---|---|
| BaseEntity(抽象) | id + created_at 的共同殼,只給 member/menu_item/meal_order 用 | 無業務方法 |
| MenuItem | 對照 V1 DDL 的映射 | 無(V1 刻意貧血) |
| BusinessException(抽象) | 一切業務錯的基底:帶錯誤碼(code)與 HTTP 狀態 | 建構子(code, httpStatus, message) |
| ItemNotFoundException / StockUnderflowException | 附錄 B 錯誤碼一碼一類;這步只建用到的兩個 | 建構子(id) |
| GlobalExceptionHandler | 三路收口:BusinessException→對應狀態+四欄位體;@Valid 炸的→422;兜底 Exception→500(不洩內部) | 三個 handler 方法 |
| MenuItemRepository | JPA 介面 | 進貨條件更新(菜 id, 變化量 delta)→ int 影響列數(JPQL **自己寫,寫完對附錄 A**) |
| MenuItemService | 四個用例的交易邊界(@Transactional 在這層) | 建菜(建菜請求)→菜回應;上下架(id, active)→菜回應;進貨(id, delta)→{id, 新 stock};後台清單()→清單;客人菜單()→清單(濾 inactive,allowed 先一律 true) |
| MenuItemController / AdminMenuItemController | 路由對附錄 B:/api/menu 一支、admin 四支(GET 清單/POST 建菜/PATCH 上下架/POST restock) | 對應方法,入參掛 @Valid |
| DTO 四件 | §14 契約的形狀 | CreateMenuItemRequest、RestockRequest、MenuItemResponse、MenuResponse |

### 施工小步(順序=依賴方向,由內往外)

1. **例外脊椎先立**:BusinessException + 兩個子類 + GlobalExceptionHandler。用一支丟例外的假端點驗過四欄位格式,砍掉假端點,才開始正事 — 地基先驗貨。
2. BaseEntity + MenuItem → 啟動一次,validate 幫你對 DDL。
3. Repository:進貨那支 JPQL 自己先寫,寫完才翻附錄 A 對答案。
4. Service:交易邊界在這層。思考點:UPDATE 不回新值,回應裡的新 stock 怎麼來?
5. Controller + DTO:@Valid 掛上;錯誤格式不用寫 — 脊椎自動收口。

### 完成形檔案樹(這步新增;依層分包(by-layer),照決策總表)

```
src/main/java/com/eatrush/
├─ controller/   MenuItemController、AdminMenuItemController
├─ service/      MenuItemService
├─ repository/   MenuItemRepository
├─ entity/       BaseEntity、MenuItem
├─ dto/          CreateMenuItemRequest、RestockRequest、MenuItemResponse、MenuResponse
└─ exception/    BusinessException、ItemNotFoundException、StockUnderflowException、GlobalExceptionHandler
```

### 手動驗證

- [ ] 假端點丟 ItemNotFoundException → 404,body 四欄(code/message/path/timestamp)齊
- [ ] Swagger 建菜 → 201,SQL 查得到新列
- [ ] 進貨 {delta:10} 連按兩次 → 共 +20(增量語意,不是設值)
- [ ] 進貨 {delta:-99999} → 409 STOCK_UNDERFLOW,SQL 確認庫存沒動
- [ ] 下架後 /api/menu 看不到、admin 清單看得到
- [ ] **反向**:把 entity 某欄位名改錯重啟 → validate 炸 → 改回

### 出口

- 思考題(spec §12-3):為什麼進貨是「+N」不是「設成 N」?更新遺失(lost update)的精確瞬間在哪?
- [ ] commit:`step3: 商家線 + 例外脊椎`

---

## Step 4|點餐心臟(4–5 天,含 Step 1 省下的緩衝)｜spec §6.1、§6.5、§10、§12-4、附錄 A

**學習意義**:全案精華 — 交易邊界思維+併發控制從紙上到親手(你將親眼讓兩個請求打架並用一句 SQL 分勝負);外加多零件協作的類別設計(五個零件一台機器)。面試講的代碼,九成出自這步。會員先用 seed 測試客人 id 帶參數(§12)。

### 前夜預習(自測題)

| 你要能回答 | 去哪查 |
|---|---|
| @Transactional 的邊界在哪(方法進出)?rollback-only 標記是什麼時候被立的? | Spring 官方「Transaction Management」;關鍵字 `unexpectedrollbackexception` |
| 為什麼同類別自呼叫(self-invocation)不會開新交易?代理(proxy)機制一句話? | 關鍵字 `spring transactional self-invocation proxy` |
| DataIntegrityViolationException 何時拋?怎麼確認是撞了哪個唯一鍵? | 關鍵字 `spring duplicate key unique constraint exception` |
| JSON 欄位在 JPA 怎麼存?(兩條路:String 欄位+ObjectMapper 手轉,或 AttributeConverter)你選哪條、為什麼? | 關鍵字 `jpa json column converter` |

### 類別契約

| 產物 | 責任(一句話) | 公開方法(中文簽名) |
|---|---|---|
| MealOrder / OrderItem(entity)+ OrderStatus(enum) | 映射 §4.6/4.7;狀態四值 PLACED/PREPARING/COMPLETED/CANCELLED | 無 |
| MealOrderRepository | 佔位用內建 save;狀態門票+冪等查詢 | 搶門票(訂單 id, 從狀態, 到狀態)→int;依冪等鍵找(鍵)→Optional |
| OrderItemRepository | 明細存取 | 依訂單找明細(訂單 id)→清單 |
| MenuItemRepository(擴充) | 心臟那句 | tryDeduct(菜 id, 數量)→int(**自己寫,對附錄 A**) |
| OrderItemValidator(介面)+ 三實作 | 逐道分類不擋單:NotFound / PlanLevel / Active;@Order 定順序 | 檢查(請求明細, 會員)→通過或原因碼 |
| StockDeductionStrategy(介面)+ V1 實作 | 扣減演算法可換(V2=BOM);V1=**升冪排序**逐道 tryDeduct | 扣減(候選清單)→每道 accepted/rejected 結果 |
| OrderService | 下單交易本體(@Transactional):佔位→驗→扣→成單;全拒拋例外回滾 | 下單(會員 id, 冪等鍵, 明細清單)→下單結果 |
| OrderReplayService(**獨立 bean**) | 輸家回放:在失敗交易**之外**查贏家結果組回應 | 回放(冪等鍵)→下單回應 |
| OrderApplicationService(或 Controller 層) | 編排:try 下單 catch 撞鍵→回放(§12-4 坑二的結構解) | 下單入口(會員 id, 請求)→下單回應 |
| DTO | §14 契約 | PlaceOrderRequest(冪等鍵, 明細[]);OrderResponse(orderId, status, accepted[], rejected[]) |

### 施工小步

1. entity + enum + 三個 repository(兩句條件更新自己寫,對附錄 A)。
2. **三層骨架先搭空殼**:ApplicationService(try/catch)→ OrderService(@Transactional,先只做佔位 INSERT)→ ReplayService(先回假資料)。先讓「撞鍵→回放」的水管通(同鍵打兩次,第二次走到回放),再填肉 — 結構錯了最貴,先驗結構。
3. Validator 鏈:介面+三實作+List 注入+@Order;入口 422 檢查(空明細、份數 1–10 外、重複菜 id)。
4. 扣減策略:介面+升冪實作。
5. 成單收尾(同一交易):accepted 寫 order_item、rejected 寫 JSON 快照;全拒→拋例外回滾→409。
6. 回應組裝照 §14(首次 201、重放 200,body 直接吐快照不重 join)。

### 完成形檔案樹(這步新增)

```
├─ controller/   OrderController
├─ service/      OrderApplicationService、OrderService、OrderReplayService
├─ service/validator/  OrderItemValidator、NotFoundValidator、PlanLevelValidator、ActiveValidator
├─ service/stock/      StockDeductionStrategy、ConditionalUpdateDeduction
├─ repository/   MealOrderRepository、OrderItemRepository
├─ entity/       MealOrder、OrderItem、OrderStatus
└─ dto/          PlaceOrderRequest、OrderResponse(含 accepted/rejected 內層形狀)
```

### 手動驗證(冪等鍵自己編 UUID)

- [ ] 正常單(牛肉麵×2)→ 201;SQL:stock 20→18、meal_order 一列、order_item 一列
- [ ] 部分成立(和牛×1 + 幽靈 id 999)→ 201,accepted 含和牛、rejected 含 {999, name:null, ITEM_NOT_FOUND}
- [ ] 連下 6 張和牛單(庫存 5)→ 第 6 張該道 rejected(SOLD_OUT);SQL:stock=0 **不是 -1**
- [ ] 全拒單(只點幽靈 id)→ 409 ORDER_ALL_REJECTED;SQL:**meal_order 沒有新列**(佔位列隨回滾消失)
- [ ] 冪等:同鍵打兩次 → SQL 只一張訂單;第二次 200 且 body 與首次完全一致
- [ ] **判準主戲(§12-4)**:兩個 Swagger 視窗同時搶最後 1 份和牛 → 一單 accepted、一單 rejected
- [ ] 422 三連:quantity=0 / 空 items / 重複菜 id → 全 422,SQL 零副作用
- [ ] **反向**:把回放邏輯暫時搬回同一個 @Transactional 內打重複鍵 → 親眼看 UnexpectedRollbackException(坑二現形)→ 搬回去

### 出口

- 思考題(spec §12-4):「先查再扣」錯在哪個瞬間?排序為什麼保證永不死鎖(畫成環等待圖)?佔位為什麼放第一步?全拒為什麼回滾不留空單?
- [ ] commit:`step4: 點餐心臟 — 佔位冪等 + 升冪扣減`

---

## Step 5|取消與估清(2 天)｜spec §5、§6.2、§6.4、§12-5

**學習意義**:狀態機落地+「用 DB 原子性做冪等」的第二式(門票)。也是驗收 Step 4 學沒學會的鏡子 — 第一次靠讀 spec,這次該靠手感;若這步還是步步查,回頭重走 Step 4 的思考題。

### 前夜預習(自測題)

| 你要能回答 | 去哪查 |
|---|---|
| 條件更新回 0 列的所有可能原因,取消場景怎麼窮舉分流? | spec §6.2(這題查 spec 就好) |
| enum 存 DB 是字串好還是序數(ordinal)好、為什麼? | 關鍵字 `jpa enumerated string vs ordinal` |

### 類別契約

| 產物 | 責任(一句話) | 公開方法(中文簽名) |
|---|---|---|
| OrderService(擴充) | 取消:搶門票→rows=0 窮舉分流→贏家**升冪**加回 | 取消(訂單 id, 操作者)→void(冪等重放時回現況) |
| AdminOrderService | 商家改狀態(照 §5 轉移表)+ 看板查詢 | 改狀態(訂單 id, 目標狀態)→回應;看板(狀態過濾)→清單 |
| AdminOrderController | GET /api/admin/orders(?status=)+ PATCH status | 兩支 |
| MenuItemService(擴充) | soldOut=stock==0(推導);allowed 用假會員 plan.level 真算 | 客人菜單()簽名不變,內容升級 |

### 施工小步

1. 取消:門票條件更新 → rows=0 分流**窮舉所有狀態**(已 CANCELLED→200 冪等 / COMPLETED→409 / PREPARING+客人→409),別留 else 黑洞 → 贏家照升冪加回。
2. 商家改狀態:轉移表硬編碼在一處(方法或 Map),不合法 → 409 INVALID_STATUS_TRANSITION。
3. 菜單標記升級:soldOut 推導 + allowed 假會員計算。

### 完成形檔案樹(這步新增)

```
├─ controller/   AdminOrderController
└─ service/      AdminOrderService(OrderService、MenuItemService 內加方法)
```

### 手動驗證

- [ ] 下單扣 2 → 取消 → SQL stock 完整回來、訂單 CANCELLED
- [ ] **再取消同一單 → 200,但 SQL stock 沒有再加**(門票只有一張 — 本步靈魂)
- [ ] 商家 PLACED→PREPARING→COMPLETED 順走;COMPLETED→PREPARING → 409
- [ ] 客人(假身分)取消 PREPARING 單 → 409 PREPARING_CANNOT_CANCEL
- [ ] demo 一圈:和牛搶完 → soldOut:true → 取消一單 → 再點成功
- [ ] 399 假會員 → 和牛 allowed:false;799 → true

### 出口

- 思考題(spec §12-5):連按兩次取消,第二次為什麼自然無效?加回為什麼也要照升冪?
- [ ] commit:`step5: 取消門票 + 估清推導`

---

## Step 6|併發自動測試(3 天)｜spec §11、§12-6、附錄 A

**學習意義**:閉環開發的後半圈 — 從「我覺得沒問題」升級到「測試說沒問題」;兩個做壞實驗是科學方法(可證偽):你將親手製造負庫存和死鎖,從此對這兩個災難有體感而不是聽說。

### 前夜預習(自測題)

| 你要能回答 | 去哪查 |
|---|---|
| Testcontainers 是什麼?@ServiceConnection(Boot 3.1+)怎麼讓測試自動連 postgres 容器? | Testcontainers 官方 + Spring Boot 官方「Testcontainers」節 |
| CountDownLatch 的 await/countDown 怎麼讓 20 執行緒「同一瞬間」出發? | JDK 文件;關鍵字 `countdownlatch 併發測試` |
| 為什麼**併發測試類別不能掛 @Transactional**?(子執行緒不在同交易+測試回滾假象) | 關鍵字 `spring test transactional multithread` |
| H2 和 PostgreSQL 的鎖行為差在哪一句話? | spec §11(查 spec 即可) |

### 產物契約(測試類清單)

| 測試類 | 斷言核心 |
|---|---|
| OrderConcurrencyTest | 20 執行緒放閘搶和牛 5 份 → 恰 5 單 accepted、stock=0、**不變式等式成立** |
| DeadlockAvoidanceTest | A 單(麵+和牛)×B 單(和牛+麵)交錯 100 輪 → 零 Deadlock 例外、帳實相符(fixture 自 seed 大庫存 10000) |
| IdempotencyTest | 同鍵×5 → 一張訂單、五次 body 全同 |
| CancelRaceTest | 取消 vs 改狀態同時 → 恰一方贏、庫存正確 |
| 單元三件 | 轉移表逐條、Validator 鏈逐個、等級比大小邊界 |

### 施工小步

0. **前一晚:裝 Docker Desktop + `docker pull postgres:16`** — Docker 在此進場(Testcontainers 硬需求),先拉好 image 首跑不乾等。
1. Testcontainers 接**真 PostgreSQL**;併發測試類不掛 @Transactional,資料清理用 @BeforeEach 手動重置。
2. 併發搶購測試(放閘寫法見附錄 A 偽碼)。
3. 死鎖迴避測試。
4. 冪等 / 取消競態 / 單元三件。
5. **兩個故意做壞實驗(正式交付物)**:①條件更新改「先 SELECT 再 UPDATE」→ 跑併發 → 截圖負庫存 → 改回;②拿掉升冪排序 → 跑死鎖測試 → 截圖 deadlock → 改回。截圖存 `docs/incidents/`。

### 完成形檔案樹(這步新增)

```
src/test/java/com/eatrush/
├─ TestcontainersConfig.java
├─ concurrency/  OrderConcurrencyTest、DeadlockAvoidanceTest、CancelRaceTest
├─ order/        IdempotencyTest
└─ unit/         StatusTransitionTest、ValidatorChainTest、PlanLevelTest
docs/incidents/  負庫存截圖、deadlock 截圖
```

### 手動驗證

- [ ] `./mvnw test` 全綠
- [ ] 兩張事故截圖入 repo(它們就是交付物)
- [ ] **反向(驗證你的驗證)**:把扣減 WHERE 的 `stock >= :q` 臨時拿掉 → 併發測試**必須轉紅** → 加回轉綠

### 出口

- 思考題(spec §12-6):為什麼斷言不變式等式而不是「功能正常」?等式少「未取消」三個字漏掉什麼?
- [ ] commit:`step6: 併發證明 + 事故截圖`

---

## Step 7|裝門:JWT 與三層授權(3–4 天)｜spec §7、§12-7

**學習意義**:拆開 Spring 最黑盒的一塊 — 從此「一個請求進來到底經過什麼」你有完整水管圖(filter chain → SecurityContext → method security)。這步預習最厚,是刻意的:它就是最高的懸崖,預習投資直接決定你卡多久。

### 前夜預習(自測題 — 本步最厚,前一晚不夠就兩晚)

| 你要能回答 | 去哪查 |
|---|---|
| Security 的 filter chain 是什麼?一個請求依序經過哪些站?(把官方那張圖畫一遍) | Spring Security 官方「Architecture」節(必讀) |
| OncePerRequestFilter 為什麼 once?自訂 JWT filter 為什麼排在 UsernamePasswordAuthenticationFilter 之前? | 同上+關鍵字 `jwt filter addFilterBefore` |
| SecurityContextHolder 誰寫誰讀?thread-local 存放意味著什麼? | 官方「Servlet Authentication Architecture」 |
| 401 和 403 各由誰發?(AuthenticationEntryPoint vs AccessDeniedHandler) | 關鍵字 `authenticationentrypoint accessdeniedhandler` |
| session 設 STATELESS 對 JWT 意味什麼?每個請求的 context 從哪來? | 關鍵字 `spring security stateless jwt` |
| hasAuthority 和 hasRole 差在哪?(ROLE_ 前綴雷) | 關鍵字 `hasrole hasauthority prefix` |
| BCrypt 為什麼慢?慢為什麼是特性不是缺點? | 關鍵字 `bcrypt work factor` |

**教學篩選鐵則**:看到 `WebSecurityConfigurerAdapter` 直接關掉那篇 — Boot 3 已移除,照抄必炸(§12-7 坑)。只看 SecurityFilterChain bean 寫法。

### 類別契約

| 產物 | 責任(一句話) | 公開方法(中文簽名) |
|---|---|---|
| SecurityConfig | SecurityFilterChain bean:白名單(/api/auth/**、swagger、static、health)、其餘須認證、csrf 關、session STATELESS、掛 JwtAuthFilter;BCrypt bean;@EnableMethodSecurity | bean 方法 |
| JwtService | 發與驗 | 發(會員 id, role, 權限清單)→token 字串(**V1 時效 8 小時**,取捨見 spec §7.4);驗(token)→會員 id+authorities(無效拋例外) |
| JwtAuthFilter(繼承 OncePerRequestFilter) | 讀 Authorization header → 驗 → 塞 SecurityContext;沒帶就放行(讓後面的規則去擋) | 覆寫 doFilterInternal |
| Member(entity)+ MemberRepository | §4.2 映射 | 依 email 找(email)→Optional |
| AuthService | 註冊(BCrypt、只能 CUSTOMER、planId 預設 399)/ 登入(驗密→JOIN 查矩陣裝 authorities→發 token) | 註冊(註冊請求)→void;登入(email, 密碼)→{token, role} |
| AuthController | /api/auth/register、/login | 兩支 |
| CurrentMemberResolver(擇一:@AuthenticationPrincipal 或工具類) | 業務層拿「現在是誰」 | 目前會員()→會員 |
| `V3__real_passwords.sql` | seed 佔位密碼換真 BCrypt 值(值用程式印一次貼進來) | — |
| @PreAuthorize 上鎖 | 對附錄 B 授權欄**逐支**上:寫入用權限、讀取用角色;cancel 的「本人 OR ORDER_STATUS_MANAGE」混合判斷**放 service 層**,別硬塞 SpEL | — |

### 施工小步

1. 加依賴(security + jjwt)→ 先什麼都不設起一次,體感「預設全鎖」— 然後開白名單救回 Swagger。
2. JwtService + 單獨小測(發一顆、驗回來)。
3. JwtAuthFilter + SecurityConfig 掛上 → 用 health 和一支需登入的端點驗水管。
4. Member entity + AuthService 註冊/登入 + V3 密碼。
5. @PreAuthorize 逐支上鎖;假會員參數全面換 SecurityContext 真會員(Validator 鏈不動,只換「會員從哪來」)。

### 完成形檔案樹(這步新增)

```
├─ security/     SecurityConfig、JwtService、JwtAuthFilter
├─ controller/   AuthController
├─ service/      AuthService
├─ repository/   MemberRepository
├─ entity/       Member
├─ dto/          RegisterRequest、LoginRequest、LoginResponse
└─ resources/db/migration/V3__real_passwords.sql
```

### 手動驗證

- [ ] 無 token 打 /api/menu → 401;登入帶 token → 200
- [ ] 399 客人下單和牛 → rejected PLAN_NOT_ALLOWED;799 → accepted(第三層)
- [ ] **店員 restock → 403;店長 → 200**(判準主戲,第二層)
- [ ] 店員改訂單狀態 → 200(權限比角色細的證明)
- [ ] 客人 A 取消客人 B 的單 → 404(不存在或非本人同一張臉)
- [ ] register 硬塞 role 欄位 → 無效,仍是 CUSTOMER
- [ ] **反向**:拔掉 header 的「Bearer 」前綴 → 看 401 長相;排錯順序親走一遍:filter 順序 → token 有沒有真的帶到 → 最後才懷疑配置

### 出口

- 思考題(spec §12-7):三層授權各擋在哪?方案等級為什麼不放 filter?改了權限矩陣,已登入店員何時生效、為什麼?
- [ ] commit:`step7: jwt + 三層授權`

---

## Step 8|快取與包裝(3–4 天)｜spec §8、§12-8

**學習意義**:兩種能力 — 快取一致性思維(「展示值可以騙人,交易路徑不能」的落地)+ 交付力(CI、README、一鍵起:讓陌生人用得了你的東西,也是工程能力的一部分)。

### 前夜預習(自測題)

| 你要能回答 | 去哪查 |
|---|---|
| cache-aside 三步是什麼?為什麼失效用 DEL 不用 SET 新值? | spec §8 + 關鍵字 `cache aside pattern` |
| TTL 為什麼要加抖動(jitter)? | 關鍵字 `cache stampede jitter` |
| @TransactionalEventListener 的 AFTER_COMMIT 和交易內執行差在哪? | Spring 官方「Transaction bound events」 |
| Dockerfile 多階段建置(multi-stage)為什麼能讓 image 變小? | 關鍵字 `dockerfile multi-stage maven spring boot` |

### 類別契約

| 產物 | 責任(一句話) | 公開方法(中文簽名) |
|---|---|---|
| MenuCacheService(**不抽介面 — 刻意,§10**) | 手寫 cache-aside:讀→miss 查 DB→回填(TTL 3 秒+抖動);個人化 allowed **絕不進來** | 讀菜單()→回應或 null;回填(回應);清() |
| MenuChangedEvent + CacheEvictListener | 四個寫路徑(下單/取消/進貨/上下架)發事件;監聽器 **AFTER_COMMIT** 才 DEL | 監聽(事件)→清快取 |
| Dockerfile | 多階段:maven 建 → jre 跑 | — |
| docker-compose.yml(**在此首次登場**) | postgres + redis + app 三件套(「環境即代碼」兌現,本機 PG 功成身退) | — |
| .github/workflows/ci.yml | build + test(Testcontainers 在 CI 直接跑) | — |
| README | 架構圖、決策的為什麼、刻意不用清單、兩張事故截圖、一鍵起指令 | — |

### 施工小步

1. 加 Redis 依賴;MenuCacheService(StringRedisTemplate 直用);GET /api/menu 接上讀路徑。
2. 四寫路徑發事件 + AFTER_COMMIT 監聽 DEL。
3. Dockerfile + compose 三件套;`application.yml` 分本機/容器兩組設定(profile)。
4. CI + README。

### 完成形檔案樹(這步新增)

```
├─ service/cache/  MenuCacheService、MenuChangedEvent、CacheEvictListener
├─ Dockerfile
├─ docker-compose.yml
├─ .github/workflows/ci.yml
└─ README.md
```

### 手動驗證

- [ ] `redis-cli MONITOR` 開著:第一次 GET /api/menu 見回填,3 秒內第二次命中、無 DB 查詢日誌
- [ ] 下單成功後立刻 GET → 新庫存已反映(AFTER_COMMIT 的 DEL 生效)
- [ ] **反向**:下一張全拒單(409 回滾)→ MONITOR **看不到 DEL**(沒提交就不對外說話 — 與 spec 的推播不變式同款)
- [ ] 砍掉本地重 clone → `docker compose up` 一鍵起(陌生人視角驗收)
- [ ] CI 綠勾

### 出口

- 思考題(spec §12-8):先更 DB 再刪快取,反過來會怎樣?哪些資料絕對不准進快取?
- [ ] commit:`step8: cache-aside + 整包化 + ci`

---

## Step 9|前端兩頁(2–3 天,原生 HTML/CSS/JS)｜spec §14、§12-9

**學習意義**:消費自己的 API — 換到呼叫端才看得見契約設計的好壞(§14 定死的價值在這裡兌現);全棧閉環的最後一塊。

### 前夜預習(自測題)

| 你要能回答 | 去哪查 |
|---|---|
| fetch 怎麼帶 header、怎麼統一處理 401? | MDN「Fetch API」 |
| localStorage 存 token 的取捨一句話? | 關鍵字 `localstorage token xss` |

### 產物契約

| 產物 | 責任 |
|---|---|
| api.js | fetch 薄包裝:localStorage 存 token、自動帶 Authorization: Bearer、401 一律導回 login |
| login.html | 登入/註冊;成功按回傳 role 跳頁 |
| customer.html | 菜單卡片牆(soldOut 標記、allowed 灰化)→ 購物籃(JS 物件)→ 送單(**crypto.randomUUID() 當冪等鍵**)→ 我的訂單(「沒點到」提示、取消鈕) |
| admin.html | 庫存列表(active 開關、進貨鈕)+ 訂單看板(**setInterval 5 秒輪詢**、改狀態鈕) |
| app.css | 能看就好,不美化 |

### 施工小步

1. `src/main/resources/static/` 建五檔;api.js 先行(所有頁共用)。
2. login → customer → admin 順序做;每頁做完立刻對 §14 契約驗欄位。
3. README 補一句:「前端為 demo 載具,無框架是刻意 — 契約先行,載具可拋棄」。

### 手動驗證

- [ ] **demo 主戲台(§12-9)**:兩個瀏覽器搶最後一份和牛 → 畫面一邊成功一邊售完
- [ ] 送單鍵狂點 → 我的訂單只有一張單(冪等在 UI 層看得見)
- [ ] 客人下單後 ≤5 秒,商家看板自己長出新卡(輪詢)
- [ ] 399 帳號登入 → 和牛卡片灰掉不可點

### 出口

- [ ] commit:`step9: 原生兩頁 demo`
- [ ] 對照 spec §13:此刻=M3.5 → 進 Step 10 發版。

---

## Step 10|發版 v1.0(半天)｜第 1 圈大閉環的收口

**學習意義**:交付的最後一哩 — 版本(release)是對外的承諾單位。學會收口,專案才是「有版本」,不是「一直在寫」。

### 施工小步

1. 全量測試綠;demo 主戲(兩視窗搶最後一份和牛 → 取消 → 復活)最後完整走一遍。
2. README 定稿:架構圖、決策的為什麼、刻意不用清單、兩張事故截圖、一鍵起指令、roadmap(§15)。
3. `git tag v1.0` 推上 GitHub + Release 頁一段「這版有什麼」。
4. (可選)錄 90 秒 demo 片放 README — 面試前發訊息就能丟連結。

### 手動驗證

- [ ] 換一台機器(或砍光重 clone):`docker compose up` → demo 走通
- [ ] GitHub Release 頁看得到 v1.0
- [ ] README 從頭讀一遍:一個沒參與的人能懂「這是什麼、怎麼跑、亮點在哪」

### 出口

- [ ] tag `v1.0` — **從這一刻起,進入大閉環模式(下章)**

---

## 大閉環:版本迭代流程(v1.0 之後,每 1–2 週一圈)

> 小閉環=一步(做→驗→commit);大閉環=一個版本(選題→發版)。**每圈的終點都是一次對外可見的更新**:一個 tag、README 一段新故事 — 也就是面試「然後呢」的下一章。

### 一圈八拍

| 拍 | 做什麼 | 產出 |
|---|---|---|
| 1 選題 | 從 spec §15 挑一項;準則:實測瓶頸/真缺口優先 → 面試敘事增量 → 動機 | 一句話目標 + 回答「這圈動不動既有不變式?」 |
| 2 迷你規格(mini-spec) | 照下方模板寫**一頁**,存 `docs/iterations/v1.x-主題.md` | mini-spec 檔 |
| 3 審閱 | 自審三問:破壞既有不變式嗎?最小改動嗎?驗收可證偽嗎?→ AI 審一輪(審設計=合規) | 定稿 |
| 4 拆小步 | 2–5 個小步,每步{做什麼/怎麼驗},寫進 mini-spec 第 6 節 | mini-playbook |
| 5 施工 | 走既有小閉環規則(預習/自救梯/反向驗證/commit) | code |
| 6 驗收 | 新測試綠 + **全量回歸**(舊測試全綠=舊不變式未破;回歸紅=先修再談發版)+ demo 判準過 | 綠燈 |
| 7 發版 | `git tag v1.x`;README:roadmap 打勾 + 「這版做了什麼、為什麼」一段 | 對外的一章 |
| 8 回顧(retro) | 10 分鐘三問寫在 mini-spec 檔尾:最大的坑?排錯筆記寫了嗎?下一圈想做什麼 | 回到第 1 拍 |

### mini-spec 一頁模板(每圈複製)

```markdown
# v1.x — <主題>(大閉環第 N 圈)

## 1 動機(為什麼是這項:瓶頸證據 / 敘事增量 / 動機)
## 2 差異(diff):表 / API / 前端
- 表:加欄?加表?migration VN__
- API:新支?改契約?(改既有欄位=破壞性,見版本號規則)
## 3 不變式增修(既有的受影響嗎?新增哪條?)
## 4 驗收判準(可 demo 的一幕 + 要新增的測試)
## 5 這圈不做什麼(圍欄)
## 6 小步拆解(2–5 步,每步{做什麼/怎麼驗})

---
## retro(收圈時補)
- 最大的坑:
- 排錯筆記:docs/troubleshooting/xxx.md
- 下一圈:
```

### 圈序:以功能來加 — 功能主線三圈 + 品質支線(2026-07-08 重切)

**原則:一圈=一次功能增量(客人或商家多一個看得見的能力);品質(壓測/預扣)走支線,不佔圈。**

功能主線(每圈附「完成後多了什麼」的 demo 一幕):

| 圈 | 版本 | 功能(demo 一幕) | 背後技術 | 大小 |
|---|---|---|---|---|
| 1 | v1.0 | MVP:客人 5 能力(註冊選方案/看菜單含售完與等級標記/點餐冪等部分成立/我的訂單/取消)+ 商家 4 能力(看板改狀態/建菜上下架/進貨盤損/估清)| Step 1-10 | 4 週 |
| 2 | v1.1 | **每人限購**:和牛每人限 2 份,同帳號第 3 份被拒(LIMIT_EXCEEDED)| Validator 鏈+1 類別(OCP 兌現);鷹架遞減第一圈(mini-spec 你寫 AI 審)| 2-3 天 |
| 3 | v1.2 | **食材庫存 BOM**:進貨改進食材(肉片/麵球),菜=食譜;肉片見底→用到它的菜**連動售完** | 食材+食譜表、StockDeductionStrategy 第二實作(介面兌現)、鎖排序升級到食材層 | 1-1.5 週 |
| 4 | v1.3 | **廚房工作站 KDS**:訂單自動拆小票到各台、即時跳票(SSE)、逐道打勾、全勾整單自動完成 | station 欄+明細狀態下沉+投影+推播;last-one-out 深水區 | 1 週 |

**v1.3 收工=完全體**(總程約 7-8 週,與投遞期重疊,每圈發版=一封 follow-up 素材)。完全體後首選第四圈=**v1.4 登入安全強化**(refresh rotation+登出撤銷 token_version+access 縮短;見 spec §7.4)— 補 JWT 面試火力,且不動倉儲主線。

品質支線(不佔圈):
- **壓測=體檢**:v1.0 發版後首檢(k6,RPS/p99 進 README),之後每圈發版後複檢 30 分鐘更新數字
- **Redis 預扣=處方**:某次體檢實測到 DB 行鎖瓶頸才插隊開一圈;沒紅燈永遠不開(YAGNI)
- 其餘 §15 項(候位/QR、權限畫面、圖片上傳、MQ、對照文章)=彈藥庫;**停損規則:拿到 offer 就停**,沒做的留 README roadmap,「永遠有下一章」的敘事不需要真的寫完

### 規則四條

0. **圈的完成定義=端到端(end-to-end)**:demo 一幕必須發生在**瀏覽器**,不是 Swagger — mini-spec 差異三欄(表/API/前端)都要走到,新資料要走完最後一哩(DB→DTO→JSON→fetch→DOM)。前端標準是「接得起來」不是「漂亮」;三圈前端量遞增:v1.1 小(原因文案)→ v1.2 中(進貨頁改食材)→ v1.3 大(工作站視圖+SSE,前端即主角)。
1. **版本號**:v1.0=MVP;之後每圈 +0.1;若動了 §14 契約的**既有欄位**(破壞性變更)→ 跳 v2.0 並在 README 說明。
2. **鷹架遞減**:第 2、3 圈(v1.1/v1.2)mini-spec 與小步拆解**你寫、AI 審**;第 4 圈起 AI 只抽查 — 「會自己拆步驟」是畢業考之外的第二張證書。
3. **一圈一檔完整封存**:選題理由、設計、拆步、retro 全在同一份 mini-spec — 面試前重讀 iterations/ 資料夾,每一圈都是一個講得完整的故事。

---

## 畢業考(M3 後擇一日;檢驗「懂了」還是「抄過」)

關掉筆記、不開 EatRush 舊碼,從**空資料夾**重蓋 Step 3 + Step 4 的核心:一條商家線(建菜+進貨)+ 下單(佔位冪等+條件扣減+部分成立),一天內閉環跑通(能起、手動驗證過)。

- 過了:「同類型專案能從零自蓋」有實據 — 面試敢講,之後讓 AI 敲碼就是加速,不是代替。
- 卡住的每個點=還沒真懂的那塊,記下來回去補 — 這份清單比過關本身更值錢。
