# 在新電腦上啟動 eatrush(Getting Started)

> 這份文件在幹嘛:**換一台電腦(或新同事)第一次要跑這個專案時,照這裡做。**
> 適用狀態:**Step 1**(骨架 + health API + 本機 PostgreSQL)。Docker 尚未進場(排在 Step 8),所以「建庫」目前仍是**手動步驟**——這份文件就是暫時補上那個缺口的「食譜」。等 Step 8 的 `docker-compose` 進來,建庫會自動化,屆時回來更新本檔。

---

## 1. 前置需求(先確認這台機器有裝)

| 需求 | 版本/說明 | 怎麼確認 |
|---|---|---|
| JDK | **21**(對齊 `pom.xml` 的 `java.version`) | `java -version` |
| PostgreSQL | **16**,服務有在跑、聽 `localhost:5432` | `psql -U postgres -c "SELECT version();"` |
| Git | 取程式碼用 | `git --version` |
| IDE | Eclipse / IntelliJ,**需有 Maven 整合(m2e)** | 見第 4 步 |

> Maven 本體**不用另裝**——專案內附 `mvnw` wrapper,會自己抓對的版本。

---

## 2. 取得程式碼

```bash
git clone <repo 網址> eatrush
cd eatrush
```

(還沒推上 GitHub 前,就是直接複製整個 `eatrush` 資料夾。)

---

## 3. 建空資料庫(手動,一次性)

```bash
psql -U postgres -c "CREATE DATABASE eatrush;"
```

- 這步 `application.yaml` 和 Flyway **都不會幫你做**——它們負責「連庫」和「建表」,但「建庫本身」要先手動。
- 帳密用**這台機器的本機 PostgreSQL**(開發機通常是 `postgres` / 你安裝時設的密碼)。
- 建好是**空的、沒有表**——正確。表由 Flyway 在啟動時建(見 Step 2 的 `V1__`,尚未寫則啟動時 Flyway 會說「沒有 migration 可套用」,正常)。

---

## 4. 確認連線設定

打開 `src/main/resources/application.yaml`,確認:

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/eatrush   # 庫名 = 上一步建的 eatrush
    username: postgres                               # ← 改成這台機器的 PG 帳號
    password: <你這台機器的 PG 密碼>                  # ← 改成這台機器的 PG 密碼
  jpa:
    hibernate:
      ddl-auto: validate
```

> **注意**:`username` / `password` 是**跟著機器變的**——不同電腦的 PostgreSQL 密碼可能不同,換機器要改這兩行。
> (把密碼寫死在檔案裡是 demo 期的權宜;正式環境會改用環境變數 / profile,這在 Step 8 處理。)

---

## 5. 匯入 IDE

**Eclipse**:`檔案(File) → 匯入(Import) → Maven → Existing Maven Projects(現有 Maven 專案)` → Root Directory 選 `eatrush` 資料夾 → 勾到 `/pom.xml` → Finish。

- ⚠️ **不要**用「General → Existing Projects into Workspace」——那個找 `.project` 檔,本專案沒有,會匯入不到。
- 第一次匯入 Eclipse 會**下載依賴**(那六個 + Spring 一大包),**會慢**,右下角進度條跑完再動。

**IntelliJ**:直接 `Open` 選 `eatrush` 資料夾,認到 `pom.xml` 會自動當 Maven 專案匯入。

---

## 6. 啟動

專案根目錄:

```bash
./mvnw spring-boot:run
```

(或在 IDE 裡跑主程式 `EatrushApplication`。)

---

## 7. 驗證跑起來了

- 啟動日誌**無 ERROR**,看到 `Tomcat started on port 8080`。
- `GET http://localhost:8080/api/health` → **200**。
- `http://localhost:8080/swagger-ui.html` → Swagger UI 開得出來。

---

## 常見卡點

| 現象 | 多半是 |
|---|---|
| IDE 匯入後專案沒出現 | 用錯匯入方式——要用 **Maven 匯入**,不是 General(它找 `.project` 找不到) |
| 啟動連不上 DB | PG 沒跑 / 沒建 `eatrush` 庫 / `application.yaml` 帳密跟這台機器的 PG 對不上 |
| Flyway 說「沒有 migration」 | 正常——`V1__` 是 Step 2 才寫 |
| 依賴下載很久 | 第一次匯入的正常現象,讓它跑完 |

---

## 為什麼要有這份(給未來的你)

現在「建庫」是**手動指令、不是版控檔**(Docker 延到 Step 8)。這份文件先當那個「食譜」的替身,讓任何一台新機器照著就能起來。等 Step 8 的 `docker-compose.yml`(設 `POSTGRES_DB: eatrush`)進來,第 3 步的手動建庫會被 `docker compose up` 一鍵取代——**到時回來把本檔改成 Docker 版**。這就是「環境即代碼、手動的必漂移」在這個專案的落地。
