# Step 2 開發日誌 — 建表與 seed(Flyway V1/V2)

> 日期:2026-07-08｜對應 playbook Step 2(spec §4)
> 學習意義:把 spec §4 的紙上表格翻成真 DDL —「設計→schema」的翻譯能力;Flyway = 資料庫的 git,從此庫可在任何機器從零重生。

---

## 進度 checklist(施工小步)

- [x] 建 `src/main/resources/db/migration/`、`V1__init_schema.sql`(雙底線)
- [x] 讀 §4 + ER 圖 → 排出七表 CREATE 順序(plan/permission/menu_item 母表先,再 member/role_permission/meal_order/order_item)
- [x] 逐表寫 `V1__init_schema.sql`(七表)—— 額外加值:order_item 用**複合 UNIQUE(order_id, menu_item_id)** 防「和牛全店只賣得出一次」;stock `NOT NULL`(NULL 會讓 `WHERE stock >= :q` 三值邏輯永遠 false)
- [x] 起 app → Flyway 套 V1 成功 → `\dt` 見**七表 + flyway_schema_history**、history 版本 1 success=t ✅
- [x] 寫 `V2__seed.sql`(5 表 18 列)→ 起 app → Flyway 套 V2 success=t → psql 驗:plan 2 / permission 3 / menu_item 5(牛肉 stock 5 / level 2)/ member 4 / role_permission 4(**OWNER 3、STAFF 1**)✅
- [ ] (可選)最終可重現性:`DROP DATABASE eatrush; CREATE DATABASE eatrush;` → Flyway 從零重播 V1+V2 全綠
- [x] 反向驗證:改 V1 → 重啟 → `FlywayValidateException: checksum mismatch`(DB 記錄 `106317791` vs 本地 `-2022777712`)→ 改回 → 綠。親眼看「已套用不可變」保護 ✅(過程坑見下方坑 7)
- [ ] **第三戰改判拆表(2026-07-08 深夜,見附錄)**:V1 刪 permission / role_permission 兩個 CREATE、V2 刪權限+矩陣 seed → 上一項 DROP/CREATE 重播**升級為必做**(改已套用檔不重建=必踩 checksum mismatch — 正好是反向驗證親眼看過的那顆雷,真實場景用上)
- [ ] 出口思考題 + commit `step2: 五表 schema + seed`

> 這步**不寫任何 entity**(entity 跟 Step 3 走;validate 模式「有表沒 entity」不炸)。

---

## 三個「不可漏」(playbook 契約)

- 三個唯一鍵:`member.email`、`meal_order.idempotency_key`、~~`permission.code`~~(第三戰撤表後剩前兩個)
- `meal_order.rejected_items` 用 **JSONB 可空**
- ~~`role_permission` 用複合主鍵~~(表已撤;複合 PK 的知識仍在 — 觀念 3 與 Q4)

~~七張表~~ → **五張表(2026-07-08 深夜第三戰改判,見附錄)**:plan / member / menu_item / meal_order / order_item(關係看 §4 的 ER 圖)。

---

## 前夜預習(三個機制,寫 DDL 前要懂)

**1. Flyway 檔名 + checksum**:`V1__init_schema.sql` — `V`=versioned、版號定順序、**雙底線** 分隔、描述給人看。checksum=檔內容指紋,記進 `flyway_schema_history`;啟動時重算比對,改「已套用」的檔 → mismatch 啟動失敗 → 要改只能往前加新檔(如 git 不改已 push 歷史)。

**2. JSONB**:一欄存一整坨 JSON。判準「這串資料之後會查/關聯它嗎」→ 會=開表、只顯示=塞 JSON 一欄。EatRush:accepted 開表(order_item,要查/JOIN)、rejected 塞 jsonb(只顯示回放)。

**3. 複合主鍵**:多欄組合才唯一,用在多對多中間表;寫法 `PRIMARY KEY (role, permission_id)`(表級約束,獨立一行),天然防重複授權。

---

## 學到的觀念(權限矩陣一路推導出來的設計思維)

> 觀念 2–6 是靠 4 題複合主鍵應用題推導的(Q1 學生選課 / Q2 按讚防重複 / Q3 訂單同商品兩行 / Q4 EatRush order_item vs role_permission),可當面試複習題。

### 1. 多對多 → 中間表(junction table)
一個 A 對多個 B、一個 B 對多個 A(role↔permission、學生↔課、user↔post)= 多對多。存法:**2 張實體表 + 1 張關係表**;中間表每一列 = 「A 的某個 ↔ B 的某個」一對配對。

### 2. 複合主鍵(composite PK)+ 它免費附贈的規則
中間表主鍵 = `(欄A, 欄B)` 的組合。除了當身分,它**天然保證「那一對不能重複」**——免費擋掉重複授權 / 重複選課 / 重複按讚。role_permission 防「同角色授同權限兩次」就靠這個。

### 3. A vs B:複合主鍵 vs 代理 id(surrogate id)
中間表上主鍵有兩種:
- **A. 複合主鍵 `(欄A, 欄B)`**:身分 + 防重複一次搞定,最省。缺點:ORM 摩擦(JPA 要 `@IdClass`/`@EmbeddedId`)、天然鍵脆弱(改值就動到 PK)、無單一 id 給外部參照。
- **B. 代理 id + `UNIQUE(欄A, 欄B)`**:框架友善(`@Id Long id`)、id 穩定、可被外部 FK 指。缺點:多一欄 + 多一約束。
- **判準:沒有絕對最好,情境決定**——要映射 entity / 被外部 FK 指 / 值常改 / 表很大 → B;小、穩定、只 JOIN 查、不被外指 → A。

### 4. EatRush 兩張中間表的**相反選擇**(A vs B 的活教材)
| 表 | 映射成 entity? | 在幹嘛 | key |
|---|---|---|---|
| role_permission | ❌ 不映射 | 登入時 JOIN 查矩陣 | 複合主鍵(A) |
| order_item | ✅ 是 entity | 建立/查/取消加回庫存 | 代理 id(B) |

決定因素 = **會不會被當物件操作(映射 entity)**。同一專案、兩張中間表、**相反答案,都對**——因為情境不同。設計不是「背哪個對」,是「看情境、套判準、接受不同答案」。

### 5. RBAC:member 靠 role 的「值」連 role_permission,不是 FK
`member.role` 與 `role_permission.role` 靠**相等的字串值**連(value join),**沒有外鍵**。判定 member 權限 = 用他的 role 值 → JOIN role_permission + permission → 權限清單 → 進 JWT。RBAC 精髓:**role 夾在 user 與 permission 中間,按角色管(少)不按人管(多)**。tradeoff:role 是裸字串、沒有 role 表當 FK,DB 不保證值一致(打錯字靜默失權)——固定小 enum 才承擔得起(這是「方案 E:role 拆表」的取捨反面)。(深夜第三戰後註:V1 矩陣住 enum,登入**不再 JOIN** — 本觀念的 value join 機制留給 V2 矩陣搬回 DB 時用,見附錄)

### 6. PK 唯一性原則
主鍵**必須唯一**。一旦「那一對」可以**合法地重複**出現(同訂單同商品兩行),它就**喪失當 PK 的資格** → 改代理 id。(Q3 核心;也解釋了 order_item 為何不用複合主鍵的一半)

### 7. 從矩陣到表(unpivot)
Excel 權限矩陣(列=角色、欄=權限、格子打勾)存進 DB,**不是照原樣「權限當欄位」**(新增權限要 `ALTER TABLE` + 改 code)——而是**把欄(權限)變成列(資料)**:permission 表一列一個權限、role_permission 每個「✅」變一列、空白格不存。新增權限 = `INSERT`,不動 schema。~~這就是 §4.4「用表不用 enum 寫死」的落地~~(深夜第三戰改判:矩陣不落表了 — unpivot 手法仍真,V2 矩陣搬回 DB 時就這樣落,見附錄)。

> 以下觀念 8–13 為 DDL 三版攻防期(同日下午~晚)追加。

### 8. 建表三層思考:身分 → 事實 → 防線
①**身分**:「這表的一列是什麼?」→ PK 自然浮現(獨立東西=代理 id;配對事實=複合 PK)。②**事實**:每欄過「型別+能不能空+DEFAULT」— **NOT NULL 是預設,可空才要理由**(plan_id 可空=員工不點餐,講得出語意才准空);DEFAULT 本身是語意(required_level DEFAULT 1=新菜不設限)。③**防線**:UK(業務上不准重複的事實 — 應用層查重擋不住併發)、FK(擋孤兒列)。寫完自測三題:塞得進兩列語意相同的資料嗎/每個可空欄講得出空的語意嗎/編個不存在的 id 塞 FK 欄插得進嗎。

### 9. UNIQUE = 登記簿;欄級 vs 表級約束的「視野」
每個 UNIQUE 背後是一個唯一索引=登記簿,INSERT 先翻簿、條目已在就拒。**一個 UNIQUE 管什麼,由簿子的「條目」決定**:單欄 UNIQUE(x) 條目=一個值 →「這個 x 全表登記過嗎」(email、idempotency_key);複合 UNIQUE(a,b) 條目=一對 →「這對組合登記過嗎」(選課、按讚、同單同菜)。**語法位置=語意作用域**:欄級約束(寫在欄定義裡)視野只有本欄,天生只能全表唯一;表級約束(獨立一行)看得見全表欄位,才寫得出複合 UNIQUE / 複合 PK。複合 PK 本質=複合 UNIQUE+NOT NULL — role_permission 早就在用,同一題。判別口訣:「不准重複的是**這個值**,還是**這個組合**?」

### 10. VARCHAR 長度:查規格,不猜;PG 無長度合法
長度不是全局常數(全場 20 的災難:email 22 字塞不進自己、BCrypt hash 固定 60 註冊即炸、URL 隨便超 20;但中文菜名 20 夠 — PG varchar 數字元不數 byte)。**判準:鍵/hash 的長度由生成器規格決定** — crypto.randomUUID()=36、BCrypt=60、email RFC=254。PG 特性:VARCHAR 不給長度=合法不限長(MySQL 不行);超長是**報錯不截斷**。本案定案:全無長度,驗證交 Step 3 @Size(已記 design.md §4 風格決策)。

### 11. 單頭 / 單身 / 貨架(header-detail)
訂單=單頭(meal_order:誰的單/走到哪/防重複身分證/被拒紀念冊)+單身(order_item:這單要了哪道菜幾份);menu_item=貨架(現在狀態)。取消 trace 三表各司其職:門票條件更新在單頭、加回量沿單身逐列、庫存回貨架(id 升冪);rejected 從沒扣過所以不加回。台灣 ERP 圈就叫單頭單身。

### 12. 兩個時間戳=兩個事實
created_at=出生時刻(永不變)、updated_at=最後動靜(隨轉移一直變)— 擇一必失血:只留 created 排不出「最近有動靜的單」;只留 updated 則下單時間被覆蓋毀掉(update anomaly 的時間版)。反例:menu_item 只有 created_at — **時間戳不是儀式性全加,是「有沒有業務問題要用它回答」**。

### 13. REFERENCES ≠ NOT NULL
FK 只管「指了就必須存在」,不管「必須指」— 可空 FK=「可以不指」(plan_id 唯一合法案例);member_id/order_id/menu_item_id 這種「必須有主」的 FK 要**自己**宣告 NOT NULL。每個 FK 欄照樣要過三層法的第②層。

## 踩過的坑(寫 DDL 期,format:現象 → 原因 → 解法 → 學到)

1. **`AUTO_INCREMENT` 在 PG 不存在** — 寫 `id BIGINT AUTO_INCREMENT`,PG 不認。原因:帶著 EEIT22 的 **MySQL** 習慣。解法:PG 用 `GENERATED ALWAYS AS IDENTITY`(SQL 標準)或 `BIGSERIAL`。學到:方言不同,PG ≠ MySQL。
2. **欄級 FK 用 `REFERENCES` 不是 `FOREIGN KEY`** — 寫 `plan_id BIGINT FOREIGN KEY`(沒說指向誰)炸。解法:欄級寫 `plan_id BIGINT REFERENCES plan(id)`;`FOREIGN KEY (欄) REFERENCES ...` 是**表級**寫法。學到:兩種寫法別混。
3. **分號放錯位置** — 把 `;` 放在最後一欄後(`level INT;` 再 `)`),語句被提前結束、括號沒收 → 語法錯。解法規則:**欄位用逗號、最後一欄無逗號無分號、`;` 只在收尾的 `)` 之後**。
4. **欄位定義語序反了** — `create_at NOT NULL TIMESTAMP`。原因:約束寫在型別前。解法:**欄名 → 型別 → 約束**,即 `created_at TIMESTAMP NOT NULL`。
5. **`create_at` 拼錯** — 少一個 d，§4 是 `created_at`。學到:欄名 typo 到 Step 3 JPA `validate` 會炸,趁現在抓。
6. **VS Code 連到 MSSQL → 假警報** — 正確的 PG 語法 `GENERATED ... AS IDENTITY` 被標紅波浪線。原因:編輯器連的是 **MSSQL**,拿 MSSQL 方言驗 PG 檔。解法:停用 mssql 擴充、或改連 PostgreSQL(SQLTools + PG driver)。學到:**Flyway 跑的是 PG,別為了消編輯器紅線去改對的碼**;編輯器連錯方言會誤導。
7. **改了 migration「沒炸」** — 改 V1 想測 checksum 保護,重啟卻沒報錯。原因:①**舊 app 還在 8080 跑著**(PID 沒關)②`target/classes` 是**舊複本**(源碼改了、沒 rebuild 複製過去)。**checksum 只在「啟動」時驗**,舊實例沒真重啟就不會重驗,而 Flyway 讀的是 classpath(`target/classes`)的舊檔。解法:**確實停掉舊 app + 重啟**(`./mvnw spring-boot:run` 會重跑 process-resources 把新源碼複製到 target),就炸出 checksum mismatch 了。學到:「改了沒生效」先查「app 真的重啟了嗎 / classpath 讀的是不是新檔」。
7. **欄位語序同坑三踩** — `status NOT NULL VARCHAR`(v1 六處)→ 改對 → `menu_item_id UNIQUE BIGINT`(v2 又反)。原因:坑 4 筆記寫了但肌肉沒記住,寫到後面憑感覺。解法:便利貼「**名→型→束**」貼螢幕,每寫完一表逐行唸。學到:排錯筆記要**回頭重讀**,寫過≠免疫。
8. **FK 欄統一漏 NOT NULL** — member_id/order_id/menu_item_id 全可空(連續兩版)。原因:把 REFERENCES 當成自帶必填(觀念 13)。解法:每個 FK 欄過「能不能空」;只有 plan_id 講得出空的語意。學到:對的結果(plan_id 可空)若是「全都沒寫」的巧合,要把它變成有意識的決定。
9. **長度均碼病:全場 VARCHAR(20)** — 自己的 email(22 字)塞不進自己的系統、BCrypt hash(固定 60)註冊第一發就炸。原因:把「要給長度」聽成「給個全局數字」。解法/學到:**長度=逐欄查規格**(UUID 36/BCrypt 60/RFC 254),不是猜;最終定案改走 PG 無長度風格(觀念 10)。
10. **單欄 UNIQUE 的全表災難** — `menu_item_id UNIQUE` = 和牛全店史上只能被點一次(第一個客人之後永久「超防」)。原因:UNIQUE 作用域=登記簿條目(觀念 9),想防「同單同菜」卻立了「全表此菜唯一」。解法:表級 `UNIQUE(order_id, menu_item_id)`。學到:**建得起來的語意錯比建不起來的語法錯危險** — 建表全綠,第二個客人才炸。
11. **表級約束前又漏逗號** — `quantity INT NOT NULL` 後直接接 `UNIQUE(...)`。原因:坑同 role_permission 那次(PRIMARY KEY 前漏逗號)— 表級約束是「清單裡的一項」,前一項要逗號。學到:同構位置同構坑,新增表級約束時回頭看上一行。
12. **複製來的註解沒改=錯註解** — 複合 UNIQUE 旁貼著單欄版的行為描述「(502,1) ✗ 炸」(實際上複合版會成功)。原因:從審查對話複製「錯誤示範」當「現在行為」。學到:**錯註解比沒註解毒** — 註解也要跟著代碼一起 review;好註解寫 why 不寫 what。

## 本輪我問的問題(思考軌跡 — 面試素材)

> 這些是施工中我主動問、逼出設計理解的問題。面試講「我當時卡在/問了什麼、怎麼想通」比背結論值錢。

**Schema 設計**
- **JSONB「要不要用」我完全不懂** → 拆成「這串資料之後會不會**查/關聯**它」:會→開表、只顯示→塞 JSON 一欄。accepted 開表(要 JOIN/加回庫存)、rejected 塞 jsonb。
- **複合主鍵應用題**(自己討 4 題練):Q1 選課→中間表複合 PK;Q2 按讚→複合 PK 免費防重複;Q3 訂單同商品兩行→複合 PK 失格改代理 id(**PK 必須唯一**);Q4 order_item(代理 id)vs role_permission(複合 PK)**反向選擇** → 決定因素 = 會不會**映射成 entity**。
- **「為什麼不像選課般 3 張表?」** → role 不是完整實體(固定小 enum、無屬性),不配一張表;permission 有 code/name 才配。
- **「維護性 vs 未來擴展?」(varchar role vs role 表)** → 擴展性 role 表贏、維護性看 roles 會不會變;算「**賭錯的代價**」(varchar 賭錯=一支 migration;role 表賭錯=永久多餘複雜度)。
- **「矩陣也可以 3 表+複合 PK,只是表達形式吧?」** → 對:**邏輯模型(矩陣)vs 實體模型(2表/3表)**;軸一(矩陣 vs level)決定表達力、軸二(表數/鍵形式)決定怎麼存,**兩軸正交**。
- **「role_permission 跟 member 沒連結,怎麼判定權限?」** → 靠 role 的**值**連(value join,非 FK);member.role → JOIN role_permission+permission → 權限清單 → JWT。RBAC 精髓:按角色管(少)不按人管(多)。
- **「多會計多老闆、權限非線性才需矩陣;店長店員用等級數字就好?」** → 鏈(全序)用 level、偏序(交叉)用矩陣;§4 現用矩陣是為**學 RBAC + 賭非線性近未來**(詳見下方 RBAC 附錄)。

**Flyway / git 操作**
- **「不小心改錯又執行了怎麼救?」** → dev:`DROP`/`CREATE` 重播;prod:**roll forward** 加新 migration;`repair` 修帳本不修資料;已套用不可變。
- **「Flyway 產出的檔案該不該上 git?」** → migration 檔(**食譜**)上;`flyway_schema_history`(DB 表)、DB 資料(**產物**)不上。
- **「建分支錯了 rollback,會不會失去 Flyway 作用?」** → 不會。git 管**檔案文字**、Flyway 管 **DB 套用狀態**,兩層獨立;git rollback **不撤已套用的 DB 狀態**(本機需 `DROP`/`CREATE` 對齊)。

---

## 下一步(Step 2 收尾)

V1+V2 已套用並驗證(見 checklist)。**深夜第三戰改判(附錄):permission / role_permission 撤表,七表→五表** — 收尾順序更新:
1. **拆表**:改 `V1__init_schema.sql`(刪兩個 CREATE)、改 `V2__seed.sql`(刪權限 3 列+矩陣 4 列,seed 剩 2 方案 5 菜 4 帳號 = 全是「活資料」)。
2. **`DROP DATABASE` / `CREATE DATABASE` 重播**(升級為必做):改的是已套用的 migration,dev 期正解=從零重播;prod 才走 roll forward(前夜預習 1 + 坑 7 的知識,真實場景兌現)。`\dt` 驗五表、psql 驗 seed。
3. **出口思考題**(不看文件講一遍):五張表每張「為何存在」;rejected 用 JSON、accepted 用表的理由;**新增:permission/role_permission 為什麼撤?(seed-only 氣味測試,講給 Roy 聽得懂)**
4. commit `step2: 五表 schema + seed`(照 AGENTS.md 慣例用 `stepN:` 前綴)。

---

## 附錄:RBAC 深挖 — 2 表 vs 3 表 vs 0 表(三戰設計攻防)

> 併自 `rbac-2-vs-3-tables.md`。起點:看 ER 圖問「這邊為何不 3 張表、中間複合 PK?」— 三輪吵透。
> ~~最終定案(二戰後):純 2 表、連 CHECK 都不加~~ → **終局改判(同日深夜第三戰,老師參戰):0 表 — permission / role_permission 撤銷,矩陣進 Role enum;member.role 仍存裸 VARCHAR**。完整論述已回寫 design.md §4.4(撤表+Q3 判準)/ §4.5(三戰全紀錄);此處保留攻防過程(面試素材)。

### 我卡在哪(三輪演進)
1. 第一輪:三表+複合 PK 我熟(教科書標準),**兩表反而看不懂** — 到底少了什麼、怎麼運作?
2. 第二輪:我反打「V1 店長⊃店員是線性的,一個數字比大小就解了,要矩陣幹嘛」— 拿 §4.1 的刀砍 §4.5
3. 第三輪:我自己發現「**矩陣也可以用 3 表做,幾張表只是表達形式**」— 原來前兩輪是兩個不同的問題被混著講

### 解開的兩層(兩個獨立決策,混講必卡)
**Q1 能力題:矩陣 vs level 比大小 — 看權限關係的形狀**
- **鏈(chain,全序)**=「越往上越開放」→ 能壓成一個數字,level 比大小。§4.1 方案權益就是:貴方案吃到所有便宜的,永不破。
- **偏序(partial order)**=職能互不包含 → 一維數線裝不下,只有矩陣(逐格打勾)裝得下。
- 殺手反例(會計):會計看報表、不碰訂單 — level 推演無解,因為會計 vs 店員本來就**不可比(incomparable)**。
- 誠實面:V1 的 STAFF⊂OWNER 恰好是鏈,level 當下真解得了 — 矩陣是對已知變化點(§15 儀表板 REPORT_VIEW)的**低成本預付**;反向遷移(level→矩陣)= 所有 @PreAuthorize 重寫,代價不對稱。

**Q2 形式題:2 表 vs 3 表 — role 這個鍵用什麼形式(與 Q1 完全獨立)**
- 兩版都是矩陣、能力完全等價;差別只是 role 鍵用**自然鍵('OWNER' 字串)還是代理鍵(id 數字)** — 3 表版就是把字串換成指向 role 表的數字。
- 代理鍵三個存在理由,role 逐條不中:①自然鍵會變?(enum 改名=重構級事件)②太笨重?(五個字元)③有屬性要掛?(零屬性;對照 permission 有 name 才配表)。
- **正規化錯覺**:「'OWNER' 重複三列該抽表」是錯的 — 正規化消除的是**屬性值**重複(防 update anomaly),**鍵值**重複不歸它管(member_id 重複萬次沒人喊消除)。
- 真相源視角:role 集合**封閉** → 真相源在 code(Java enum),DB 字串是引用;permission **開放** → 真相源在 DB(表)。

### 業界對照
- 光譜四檔:enum 硬編碼 → 表化 RBAC 3~5 表 → IAM 外包(Keycloak/Auth0)→ 政策引擎(ABAC/ReBAC,Zanzibar)。
- **Spring Security 只認 GrantedAuthority 字串集合 = 2 表世界觀**,框架從不要求 role 是實體。
- 3 表殺手場景:**多租戶 SaaS**(每家店自訂角色,不可能改 enum 重部署);前提=**代碼零 hasRole 寫死**,角色退化為 permission bundle 的名字。
- 「一人多角」逼出的是 **user_role 中間表**(五表模型),不是 role 表;user_role 的 role 欄照樣可存字串。

### 第二戰(寫 DDL 時宣布改 3 表,六輪後投降 → 退到更純的 2 表)
- **型別安全位置**:「判斷角色」的 Java 句躲不掉。2 表用 enum:`getRole()==Role.CUSTOMER` 打錯**編譯不過(IDE 紅線)**;3 表存數字 `roleId==1`(1 是誰?)或查字串 `.equals("CUSTOMR")`(**runtime 才錯、靜默壞**)。
- **FK 防不了我怕的錯**:FK 只擋「不存在的 id」;seed 把 2 填成 3 完全合法、靜默 — 數字錯比字串錯更難肉眼抓('ONWER' 一眼假,2 和 3 都長得對)。
- **打掉 CHECK**:CHECK = 集合定義在 DB 的第二份複本(會漂移),加角色得寫 ALTER 不是 INSERT。同步點數:純 2 表=2、CHECK 版=3、**3 表也=3** — 我殺 CHECK 的理由,殺不出 3 表的優勢。
- **擴充性總帳**:加角色瓶頸在①行為進 Java、④重部署(任何方案逃不掉);3 表只把②的 ALTER 換 INSERT = 優化非瓶頸。真擴充性(不改 code 調權限)**矩陣本身已給,2 表就有**。
- **終局 trace「加會計」**:enum 加一字 + INSERT-only migration + 部署;role 是 varchar,**新字串直接放進來(從沒關上)**。角色新增成本由「矩陣裝不下的專屬行為量」決定,與表數無關。

### 第三戰(同日深夜,老師參戰):矩陣要不要住 DB?— 終局改判:0 表,矩陣進 Role enum

老師看了設計:「矩陣可以在 Java 存組態檔,不用進資料庫 — DB 寸土寸金。」前兩戰都在吵「幾張表」,沒人問過「**要不要表**」— 這是 Q3(存放題),第三個獨立決策層。

- **判準磨準**:老師原話「要儲存、讀取才夠格」照字面不成立(每張表都會被讀)— 牙齒在「**runtime 有沒有寫入**」:只在 seed 期寫一次的表 = 穿表皮的常數。氣味測試一句:「**資料只出現在 seed 檔的表**」。掃七表:meal_order / order_item / menu_item / member = runtime 寫爆,正牌資料;**permission / role_permission = seed 完就死,被抓**;plan = V1 也 seed-only,但天然主人是營運(改價/推新方案遲早 runtime 寫入),邊界保留。
- **與 AI 判準等價**:老師問「資料活不活(runtime 有無寫入)」≡ AI 問「改它的人是誰、能不能接受部署」— 兩問必同答,互相印證。
- **記分(用自家兵器打自家定案)**:同步點 enum 版=1 < 2 表=2;加角色忘給權限集合=**編譯不過**(2 表版忘 seed=登入後權限空的,靜默)。搬家費 enum→DB 近乎零(`@PreAuthorize` 零改動 — Spring Security 只認 authorities 字串集合,不管字串從 enum 展開還是 JOIN 出來)→ **預付邏輯失效**。對照:當初買矩陣不買 level,正因 level→矩陣搬家貴 — **同一把尺,量出兩個答案**。
- **「寸土寸金」理由要換**:兩表共 8 列=塵埃(meal_order 一天流量就超過),DB 稀缺在熱路徑查詢/連線,不在空間;真正的帳=少兩張表、少一段 seed、少一個同步點。
- **AI 的最後陣地被打薄**:守 2 表只剩「UPDATE 一列重登生效的面試 demo + DDL 已寫完」— 老師本人即面試官直覺的樣本(看到 seed-only 表第一反應「不夠格」),守表變成替常數住 DB 辯護;沉沒成本不是理由(改的雖是已套用 migration,dev 期 DROP/CREATE 重播即可)。

**三戰的弧線(面試素材完整版)**:一戰 3 表 →(Q1/Q2 分層)→ 2 表;二戰我提回 3 表 →(打掉 CHECK)→ 更純的 2 表;三戰老師一句話 →(Q3 分層)→ **0 表**。每一戰都往「更少」走,每一層都留下一個判準:**Q1 形狀**(鏈→level / 偏序→矩陣)、**Q2 鍵形式**(角色由誰定義)、**Q3 存放**(runtime 有沒有寫入)。

### 一句話帶走
**角色由誰定義 — 工程師定義(行為在 code)= enum + 字串(2 表);營運者定義(角色是可配置資料)= 表 + 代理鍵(3 表)。** EatRush 單店、角色我定 → 2 表;翻成多租戶 SaaS,答案就翻。
第二戰追加:**typo 防護要放在錯誤最常發生的地方(Java 業務代碼 → enum 編譯期紅線),不是放在圖上最好看的地方(DB 約束)。**
第三戰追加:**seed-only 的表 = 用資料庫存常數 — runtime 沒有寫入的資料住 code,不住 DB;等寫入需求真出現再搬(搬家費近乎零時,不預付)。**

### 我自己的話(內化檢驗:不翻 §4.5,講給 Roy 聽得懂)
【你寫 — 能用自己的話把 Q1(形狀)/ Q2(鍵形式)/ Q3(存放)三層講清楚,這題才真的是你的】

---

## 延伸討論(2026-07-09,拆表施工前的餘波)

> 第三戰改判後的四場快問快答,各留一個判準;完整論述已回寫 design.md(§3 / §4.4 / §7 / §10)。

### 觀念 14. 「熱生效嗎?」要拆兩層答
**伺服器層**(改動要不要部署):矩陣在 DB=UPDATE 即可,熱;在 enum=改 code 重部署,冷。**token 層**(authorities=發 token 時的快照):兩案都要重登或 token 過期才刷新,冷。所以 2 表版=**半熱**(伺服器熱、token 冷);真.全熱要另外買 — 每請求查庫或 token_version(§7.4,v1.4 圈)。混著答必錯。

### 觀念 15. 前端按鈕能做什麼 — 由「定義住哪」決定,不由表數
改**分配**(既有角色×既有權限勾格子):矩陣住 DB 就給得了前端(§15-6 本體)。加**角色**:連 2 表版都炸 — member.role 映射 `@Enumerated(EnumType.STRING)`,DB 冒出 enum 沒有的字串,JPA 讀取當場拋例外;要能加=代碼零角色感知(真.表化 RBAC,多租戶 IAM 檔位)。加**權限**:任何方案都 ❌(新權限必伴隨新的受保護行為=code)。**我要的「一顆按鈕加角色加權限」=IAM 平台(Keycloak)的本體需求** — 分析作業見文末。

### 觀念 16. 通用化的生死線:水管 ✅、語意 ❌
通用化「每個東西都一樣的部分」(CRUD/id/created_at/錯誤格式)=正確,系統已有三層:`JpaRepository` 泛型、`BaseEntity`、`@RestControllerAdvice`(老師教的泛型 DAO=JpaRepository 的課堂版)。通用化「每個東西不一樣的部分」(stock 條件更新/狀態機/權限判斷)=反模式;極限形態=**EAV 萬能表**(entity/attribute/value 三表裝萬物)→ Step 2 全套防線繳械:UNIQUE 建不出(冪等地基塌)、NOT NULL/型別歸零、`stock>=:q` 要 cast — 學名**內部平台效應(inner-platform effect)**:做出一個更爛的資料庫複製品。正確姿勢:**資料庫的通用化單位=列(row)** — 會一直增加的東西建模成一列(加菜=INSERT,零 code);每加一個就要加一欄/一表/一 class 的,才需要回頭想設計。

### 觀念 17. 換技術前先定位病灶(MongoDB 誤診記)
「用 schemaless(MongoDB)就能加東西不改 entity?」— 誤診:「加權限」在 PG 也只是 INSERT 一列(**根本不用改 schema**),卡住的是 `@PreAuthorize` 那行 **code**;Mongo 動的是「schema 住哪」,不是「行為住哪」— 位置不同,無效藥。且 schemaless ≠ 沒有 schema:是 schema-on-write(寫入時驗)變 schema-on-read(每個讀取端各自猜)— 想防呆就開 schema validation=繞回原點。而 `rejected_items JSONB` 早就是在 PG 裡按存取模式**局部**採用 document 模型 — 該硬的欄位硬、該軟的欄位軟,同一張表拿完兩個世界。判準:**新技術動的位置 ≠ 你卡住的位置 = 無效藥。**

### 觀念 18. Flyway vs Atlas:風險的「形狀」不同,不是高低
Flyway=命令式(人寫「路怎麼走」,所見即所得 — review 的 SQL 就是執行的 SQL,錯=人錯、review 可攔)。Atlas=宣告式(人寫「終點」,路由 diff 引擎算 — Terraform for databases)— 風險藏在**生成環節**:欄位改名被 diff 判成 DROP+ADD=資料蒸發;plan 預覽可緩解,但 plan 終究要人審=審核能力一分省不掉。原來 `ddl-auto=update` 就是爛版宣告式 — Step 1 思考題和這題是同一題。判準:**審不動的自動化不是省力,是盲飛 — Atlas 之於 DDL,恰似 AI 之於 code:能力先於工具**(跟自己 AGENTS.md 的學習紅線同構)。

### 觀念 19. 拆表用「改原檔」還是「加 V3」— 數受害者
「已套用不可變」保護的對象=**你控制之外、已套用過該檔的資料庫**。判準:數受害者 — ≥1 個(prod/staging/隊友本機)→ roll forward 加新檔;0 個 → 改原檔+DROP 重播,歷史可重寫。本次:prod 無、隊友無、CI 未建(且 CI 用 Testcontainers 每次起全新 DB,天生不怕改檔)、V1/V2 雖已 commit 但消費者只有自己本機那顆 DB — **受害者 0,改原檔**。注意兩本帳(觀念呼應 Flyway/git 那條):改 V1 內容在 **git 層面只是普通新 commit**(檔案變更,git 史不用重寫);被重寫的是 **Flyway 的邏輯版本**(V1 版本號的內容變了)。順帶:設計期反悔不值得進 migration 史書 — 開 V3 的話,V1 讀起來是七表、讀到 V3 才知道五表=史書變雜訊。**v1.0 上線那天起受害者永遠 ≥1,一切只能 roll forward — 現在是還能重寫歷史的最後窗口。**

### 觀念 19-補. 團隊版:同一把尺,受害者數不完,答案分三級
① **出過 prod/staging → 永遠 roll forward**,無討論(那些 DB 控制不了也不能重建)。② **只在 dev 圈流通 → 預設仍 roll forward**(隊友 pull 後自動套上,零協調零人炸 — 它把修 schema 變成普通 merge);例外=協調式重寫:小團隊喊得到人才可行,紀律=**誰重寫歷史,誰負責確認每一台機器重建完**(漏一人=他啟動就 checksum mismatch);`flyway repair` 只救**內容等價**的改動(註解/排版 — 帳本對齊即可不重建),實質變更用 repair=逼帳本說謊(帳上五表、DB 七表,之後炸得莫名其妙)。③ **團隊特有新坑=版本號競態**:兩人各開分支都寫 V3 — 撞號炸;更陰:對方 V3 先合併先套用,我的 V3 後進、版本號 ≤ 已套用最高版 → `outOfOrder=false`(預設)**靜默跳過**,migration 人間蒸發。解法:時間戳版本號(V20260709153000__xxx)/ CI 撞號檢查 / merge 前改號慣例。**反面教材=UcMarket test 分支審計的「DDL 對不齊」**:各自手動改 DB、檔與實際漂移 — Flyway 這套規矩就是那個病的疫苗(面試有正反兩個親歷案例)。

### 五關分析作業(前端動態 RBAC — 我先做,AI 當面試官審)

需求陳述:**營運者在前端介面上,不經工程師、不改 code、不部署 — 按一顆按鈕就能新增角色、新增權限並配好矩陣,且立即產生實際的擋人效果。**(這是 Keycloak/Auth0 這類 IAM 產品的核心需求,不是空想 — 分析的是「完整代價是什麼、值不值得在 EatRush 付」)

1. 「加權限」按下去的完整旅程 trace:`'REPORT_VIEW'` 進 DB 之後呢?它要擋誰?`@PreAuthorize("hasAuthority('REPORT_VIEW')")` 那行是誰、**什麼時候**寫的?
2. 空殼檢驗:系統裡沒有任何一行 code 掛著新字串時,這顆按鈕加出來的「權限」能造成任何行為差異嗎?那它是什麼?
3. 用「列/欄/code」分界掃四樣:角色、權限、矩陣、權限保護的**行為** — 各自天生住哪?哪三樣搬得進 DB、哪一樣搬不動?
4. 搬不動的那樣,能不能預先通用化?(提示:所有受保護行為若能寫成同一句型「對某**資源**做某**動作**」,行為就參數化了 — 業界光譜第三、四檔存在的理由)
5. 代價總帳:走到第 4 關,要交出什麼?(enum?編譯期紅線?@PreAuthorize 寫死?)最後一題:**做完這些,它還是 EatRush,還是另一個產品?**

【分析待交 — 你寫,寫完丟回來審】
