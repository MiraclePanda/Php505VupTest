-- 初期データ（特性テストの前提になるため、変更したらゴールデンを取り直すこと）
-- SQLite 2 は複数行 VALUES に対応しないため 1 行ずつ INSERT する

INSERT INTO categories (id, name) VALUES (1, '文房具');
INSERT INTO categories (id, name) VALUES (2, '食品');
INSERT INTO categories (id, name) VALUES (3, '日用品');
INSERT INTO categories (id, name) VALUES (4, '書籍');

INSERT INTO products (id, code, name, category_id, price, stock, updated_at) VALUES (1,  'ST-0001', 'ボールペン 黒 0.5mm',       1,  120, 250, '2005-04-01 10:00:00');
INSERT INTO products (id, code, name, category_id, price, stock, updated_at) VALUES (2,  'ST-0002', 'ボールペン 赤 0.5mm',       1,  120, 180, '2005-04-01 10:00:00');
INSERT INTO products (id, code, name, category_id, price, stock, updated_at) VALUES (3,  'ST-0003', 'キャンパスノート A4 5冊組', 1,  580,  40, '2005-04-01 10:00:00');
INSERT INTO products (id, code, name, category_id, price, stock, updated_at) VALUES (4,  'ST-0004', 'B&B ノート B5',             1,  150,  75, '2005-05-10 15:30:00');
INSERT INTO products (id, code, name, category_id, price, stock, updated_at) VALUES (5,  'FD-0001', '天然水 2L',                 2,  198, 600, '2005-06-01 09:00:00');
INSERT INTO products (id, code, name, category_id, price, stock, updated_at) VALUES (6,  'FD-0002', '緑茶 500ml',                2,  147, 480, '2005-06-01 09:00:00');
INSERT INTO products (id, code, name, category_id, price, stock, updated_at) VALUES (7,  'FD-0003', '<特選> 煎餅 詰め合わせ',    2, 1050,  12, '2005-07-15 11:20:00');
INSERT INTO products (id, code, name, category_id, price, stock, updated_at) VALUES (8,  'DL-0001', 'ティッシュペーパー 5箱',    3,  298, 300, '2005-03-20 13:00:00');
INSERT INTO products (id, code, name, category_id, price, stock, updated_at) VALUES (9,  'DL-0002', '食器用洗剤 詰め替え',       3,  258,  90, '2005-03-20 13:00:00');
INSERT INTO products (id, code, name, category_id, price, stock, updated_at) VALUES (10, 'BK-0001', 'Let''s 英会話 入門',        4, 1680,   8, '2005-08-01 17:45:00');
INSERT INTO products (id, code, name, category_id, price, stock, updated_at) VALUES (11, 'BK-0002', 'PHP5 徹底攻略',             4, 3360,   5, '2005-08-01 17:45:00');
INSERT INTO products (id, code, name, category_id, price, stock, updated_at) VALUES (12, 'BK-0003', '表計算 ソフト 活用術',      4, 4200,   0, '2005-08-01 17:45:00');

-- パスワードは MD5('admin123')
INSERT INTO users (id, login_id, password, name) VALUES (1, 'admin', '0192023a7bbd73250516f069df18b500', '管理者');
