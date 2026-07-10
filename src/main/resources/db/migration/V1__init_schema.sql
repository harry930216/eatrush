
/*
    1.預設是not null 有null需思考原因
    2.表要有順序 被依賴的要先建
    3.PG VARCHAR不給長度合法 MYSQL則不行
    4.有空就回來再看看 訂單的設計
*/

CREATE TABLE PLAN(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR NOT NULL,
    level INT NOT NULL
);

CREATE TABLE MEMBER(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR NOT NULL UNIQUE,
    password_hash VARCHAR NOT NULL,
    role VARCHAR NOT NULL,
    plan_id BIGINT REFERENCES PLAN(id), /* 這可以null 因為有員工存在 他不會有方案 */
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

/* 單頭 */
CREATE TABLE MEAL_ORDER(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    member_id BIGINT NOT NULL REFERENCES MEMBER(id),
    status VARCHAR NOT NULL,
    /*
    合法值由 Java enum(OrderStatus)管 — 同 role 的判準:封閉小集合、行為在 code
    → 真相源在 enum,DB 不設 CHECK 免第二份清單
    */
    idempotency_key VARCHAR NOT NULL UNIQUE,
    /*
    冪等真防線:應用層「先查再插」有時間窗,兩個併發請求會雙雙通過檢查(check-then-act 競態);
    唯一索引把檢查與寫入合併成原子動作,第二發 INSERT 必炸、零副作用,由新交易回放原結果
    */
    rejected_items JSONB,
    /*
    只被原樣回放、永不 JOIN/統計 → 按存取模式塞 JSON(accepted 要加回庫存+聚合才開表);
    NULL = 這單沒有被拒的菜
    */
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now()
    /*
    created_at + updated_at 並存 — 兩個事實:出生時刻(永不變)/ 最後動靜(隨狀態轉移一直變)。
    看板排「最近有動靜的單」靠後者;客訴「等了多久」= 兩者相減。擇一必失血
    */
);

/* 貨架 */
CREATE TABLE MENU_ITEM(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR NOT NULL,
    description VARCHAR,
    image_url VARCHAR,
    required_level INT NOT NULL DEFAULT 1,
    /*
    預設 1 = 所有方案可點;新菜不設限是常態、特殊菜才標高 — 預設值本身是語意
    */
    stock INT NOT NULL,
    /*
    防超賣主戰場,NULL 進場即靜默壞:WHERE stock >= :q 遇 NULL 永遠 false(三值邏輯)
    = 這道菜永遠扣不到;進貨 stock + delta 遇 NULL = NULL,會傳染。估清是 stock=0,不是 NULL
    */
    active BOOLEAN NOT NULL,
    /*
    商家意志(不賣了),與 stock=0(系統事實:賣完了)兩維度分離 — 可點 = active AND stock > 0;
    stock 只有交易路徑動、active 只有商家動,永不打架
    */
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

/* 單身 */
CREATE TABLE ORDER_ITEM(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES MEAL_ORDER(id),
    menu_item_id BIGINT NOT NULL REFERENCES MENU_ITEM(id),
    quantity INT NOT NULL,
    UNIQUE(order_id, menu_item_id)
    /*
    訂單 501:Harry 點和牛   → order_item (501, 1)  ✓ 插入成功
    訂單 502:Roy 也點和牛   → order_item (502, 1)  ✗ 炸!menu_item_id=1 重複
    原本只給 menu_item_id 做 UNIQUE 意思是「這個菜 id 在全表只能出現一次」
    
    全餐廳史上只有第一個客人點得到和牛,之後永久售罄 — 這比超賣還慘,是「超防」。
    你要的語意是「同一張單內同道菜只一列」= 組合唯一 → 表級複合UNIQUE:
    UNIQUE(order_id, menu_item_id) —(501,1)和(502,1)組合不同,共存;(501,1)出現兩次才擋。
    單欄 UK=全表唯一、複合 UK=組合唯一,這是 UNIQUE 的作用域之辨 
    */
);

/*
訂單 = 單頭+單身
*/


--改掉 改成放在java組態檔(老師建議)

-- CREATE TABLE PERMISSION(
--     id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--     code VARCHAR NOT NULL UNIQUE,
--     name VARCHAR NOT NULL
-- );

-- CREATE TABLE ROLE_PERMISSION(
--     role VARCHAR,
--     permission_id BIGINT NOT NULL REFERENCES PERMISSION(id),
--     PRIMARY KEY (role, permission_id)
--     /*
--     複合 PK 免費附贈「同角色同權限不重複授權」;
--     PK 成員 PG 自動隱含 NOT NULL,故 role 不必明寫
--     */
-- );

