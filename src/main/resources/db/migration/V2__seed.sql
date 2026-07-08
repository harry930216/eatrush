INSERT INTO PLAN 
    (name, level)
VALUES 
    ('399 基本', 1),
    ('799 豪華', 2);

INSERT INTO PERMISSION
    (code, name)
VALUES 
    ('MENU_MANAGE', '菜單管理'),
    ('STOCK_MANAGE', '庫存管理'),
    ('ORDER_STATUS_MANAGE', '訂單狀態管理');

INSERT INTO MENU_ITEM 
    (name, stock, active, required_level)
VALUES
    ('蔬菜盤', 20, true, 1),
    ('豬肉', 30, true, 1),
    ('雞肉', 15, true, 1),
    ('羊肉', 40, true, 1),
    ('牛肉', 5, true, 2);

INSERT INTO MEMBER 
    (email, password_hash, role, plan_id)
VALUES
    ('owner@eatrush.test',   'placeholder_hash', 'OWNER',    NULL),
    ('staff@eatrush.test',   'placeholder_hash', 'STAFF',    NULL),
    ('cust399@eatrush.test', 'placeholder_hash', 'CUSTOMER', 
        (SELECT id FROM PLAN WHERE level = 1)),
    ('cust799@eatrush.test', 'placeholder_hash', 'CUSTOMER', 
        (SELECT id FROM PLAN WHERE level = 2));

INSERT INTO ROLE_PERMISSION (role, permission_id)
VALUES
    -- 店長:三個全給
    ('OWNER', (SELECT id FROM PERMISSION WHERE code = 'MENU_MANAGE')),
    ('OWNER', (SELECT id FROM PERMISSION WHERE code = 'STOCK_MANAGE')),
    ('OWNER', (SELECT id FROM PERMISSION WHERE code = 'ORDER_STATUS_MANAGE')),
    -- 店員:補貨 
    ('STAFF', (SELECT id FROM PERMISSION WHERE code = 'ORDER_STATUS_MANAGE'));
