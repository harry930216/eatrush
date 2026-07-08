# README 骨架範本(開 repo 後改名 README.md,施工過程逐步填【】)

> 設計原則:面試官平均停留 3 分鐘 — 第一屏要讓他決定「值得往下」。順序=鉤子→跑起來→為什麼→證據。手寫的只有「為什麼」;能自動生成的(API 文件)一律連結 Swagger。

---

# EatRush 呷飽沒 — 吃到飽點餐與庫存系統

【一句話:用資料庫原子性解決超賣 — 兩個瀏覽器同時搶最後一份和牛,恰好一人成功】

【demo GIF / 90 秒影片連結 — Step 10 產出,放最頂】

## 這個專案在回答什麼問題(30 秒版)

【三句:①吃到飽點餐有真實的併發問題(估清/搶單/商家進貨與客人扣減交錯)②我用三種併發控制解它:條件更新、唯一鍵佔位冪等、鎖排序 ③與前作 UcMarket(悲觀鎖)同跑 PostgreSQL — 兩種鎖策略的同引擎對照】

## 快速開始(60 秒)

```bash
git clone 【repo】&& cd eatrush
docker compose up
# 前端 http://localhost:8080 | Swagger http://localhost:8080/swagger-ui.html
```

| 測試帳號 | 角色 | 拿來試什麼 |
|---|---|---|
| 【399 客人】 | CUSTOMER | 點和牛會被等級擋(PLAN_NOT_ALLOWED) |
| 【799 客人】 | CUSTOMER | 搶最後一份和牛 |
| 【店員】 | STAFF | 按進貨 → 403(權限比角色細) |
| 【店長】 | OWNER | 全功能 |

## 架構

【mermaid 架構圖 — spec §3 現成】

技術棧:Java 21 · Spring Boot 3 · PostgreSQL 16 · Redis 7 · Flyway · Testcontainers · 原生 HTML/CSS/JS(刻意無框架 — 契約先行,載具可拋棄)

兩條鐵律:①PostgreSQL 是唯一真相,Redis 只做讀加速不參與防超賣 ②展示值可以慢 3 秒,交易路徑絕對即時且原子。

## 核心設計(每項:一句是什麼 + 為什麼 + 在哪驗證)

- **條件更新防超賣**:`UPDATE ... SET stock=stock-:q WHERE stock>=:q` — 不查再扣、不加鎖等待,rows=0 即售完。驗證:【併發測試連結】
- **佔位式冪等**:交易第一步 INSERT 佔位列,重送請求撞唯一鍵死在門口、零副作用回放。驗證:【冪等測試連結】
- **鎖排序防死鎖**:凡動多列庫存一律照 id 升冪 — 等待只單向發生,永不成環。驗證:【死鎖測試連結】
- **部分成立**:一單多菜逐道 accept/reject,客人清楚看到「哪道沒點到、為什麼」
- **三層授權**:JWT 認證 → RBAC 權限矩陣(@PreAuthorize)→ 方案等級比大小
- **手寫 cache-aside**:菜單快取 TTL 3s+jitter,交易提交後 DEL(刻意不抽介面 — 抽象只花在已知變化點)

## 兩個故意做壞的實驗(本專案最驕傲的部分)

| 實驗 | 做法 | 結果 |
|---|---|---|
| 把條件更新改成「先查再扣」 | 跑 20 執行緒搶購 | 【負庫存截圖】 |
| 拿掉鎖排序 | 跑交錯下單 ×100 輪 | 【deadlock 截圖】 |

「知道會壞」和「親手弄壞給你看」是兩種可信度。

## 測試

`./mvnw test` — Testcontainers 起真 PostgreSQL(H2 鎖行為不同,測併發等於測心安)。
核心斷言是不變式等式:`stock(期初) = stock(期末) + Σ(成立且未取消的明細份數)`,不是「功能正常」。

## 刻意不做的清單(節選,完整版見 docs)

【挑 3 條:狀態機不用 State pattern / 快取不抽介面 / image_url 不分表 — 各一句理由】

## 版本與 roadmap

- v1.0 MVP【日期】· v1.1 每人限購【 】· v1.2 食材 BOM【 】· v1.3 廚房工作站【 】
- 未做項與理由:docs/spec §15

## 文件地圖

`docs/` — 設計決策書(每表每欄的為什麼)· 施工手冊 · iterations/(每版一份 mini-spec 含 retro)· troubleshooting/(排錯筆記)
