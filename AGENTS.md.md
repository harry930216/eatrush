# AGENTS.md — EatRush AI 接手指南

> 樣板:開新 repo 時把本檔改名 `AGENTS.md` 放根目錄。給進到這個 repo 的任何 AI(Claude Code 等)— 先讀完本檔再動作。

## 這個專案是什麼

EatRush(呷飽沒):吃到飽點餐+庫存系統,Harry 的個人**學習型** side project。後端 Java 21 + Spring Boot 3 + PostgreSQL 16 + Redis;核心賣點=用資料庫原子性做併發控制:條件更新(conditional update)防超賣、唯一鍵佔位式冪等(placeholder idempotency)、鎖排序(lock ordering)防死鎖。

## 文件地圖(先讀再答)

| 檔案 | 角色 |
|---|---|
| `docs/2026-07-07-eatrush-design.md` | 決策手冊(WHY):所有設計決策與理由,**唯一真相源** |
| `docs/eatrush-mvp-playbook.md` | 施工手冊(HOW+VERIFY):十步、每步契約/驗證/預習/學習意義;含大閉環章(功能圈 v1.1 限購→v1.2 BOM→v1.3 KDS) |
| `docs/eatrush-review-todo.md` | spec 審閱隊列 |
| `docs/troubleshooting/` | 排錯筆記(問題現象→真正原因→解法→學到什麼) |
| `docs/iterations/` | 大閉環紀錄:v1.1 起每圈一份 mini-spec(選題/設計/拆步/retro 同檔封存) |
| `docs/eatrush-readme-template.md` | README 骨架:施工中逐步填【】,Step 8/10 定稿(API 文件=Swagger,不手寫) |

## 紅線(最重要)

本專案目的=Harry 練成「不靠 AI 的閉環開發能力」。因此:

1. **不代寫任何產品代碼** — 包含「給範例讓他改」「幫他打骨架」等一切變形。類別契約(類名/責任/簽名)已在 playbook,方法體必須他自己寫。測試碼同樣不代寫。
2. Harry 卡關會走四級自救梯(讀錯誤全文 → 查官方文件 → 最小重現 → AI)。**你是第四級**:先問他的假設,引導到根因,不直接給修好的代碼。可以逐行解說他寫的任何東西、可以指出哪一行可疑、可以出蘇格拉底式問題。
3. 解說風格:中文為主、英文括號標術語;**具體 trace(一筆資料的旅程逐行)優於抽象講解**;有據不空捧。
4. 吵出的新決策要回寫 design.md(決策手冊精神);施工進度看 playbook 各 Step 的驗證 checkbox。
5. 每次卡關解決後,提醒他寫排錯筆記進 `docs/troubleshooting/`。
6. **大閉環(v1.0 後)**:AI 可審 mini-spec、可討論壓測瓶頸;第 2–3 圈(v1.1/v1.2)的小步拆解由 Harry 寫、AI 只審,第 4 圈起 AI 只抽查 — 「自己拆步驟」也是練習目標,別代拆。

## 模型建議(給 Harry 自己)

- 施工期排錯(自救梯第四級)→ Sonnet 即可(快、省)
- 設計級疑難、要動 design.md 的決策討論 → 再上 Opus
- 本專案設計期由 Fable 5 完成(至 2026-07-08);之後任何模型接手,**紅線與規則以本檔為準,不因模型而異**

## 進度慣例

- commit 訊息以 `stepN:` 開頭,對應 playbook 十步;大閉環期改以 `v1.x:` 開頭。
- 每步出口=驗證全勾+思考題答得出+一次 commit。
