-- ============================================================
-- Шаг 4. Проверка, что данные не потерялись и не исказились
-- ============================================================

USE orders_norm_lab5;

-- ------------------------------------------------------------
-- Проверка 1. Сравнение общей суммы SUM(price * quantity)
-- до нормализации (плохая таблица) и после (соединение таблиц)
-- ------------------------------------------------------------
SELECT 'до нормализации (плохая таблица)' AS source,
       SUM(price * quantity) AS total_sum,
       COUNT(*)              AS rows_cnt
FROM orders_bad
UNION ALL
SELECT 'после нормализации (3NF)',
       SUM(p.price * i.quantity),
       COUNT(*)
FROM order_items i
JOIN products p ON p.product_id = i.product_id;

-- ------------------------------------------------------------
-- Проверка 2. Число уникальных заказов / клиентов / товаров /
-- классификаций
-- ------------------------------------------------------------
SELECT 'orders'         AS what, COUNT(DISTINCT order_id) AS cnt FROM orders_bad WHERE order_id IS NOT NULL
UNION ALL SELECT 'orders (3NF)',         COUNT(*) FROM orders
UNION ALL SELECT 'customers',            COUNT(DISTINCT customer_id) FROM orders_bad WHERE customer_id IS NOT NULL
UNION ALL SELECT 'customers (3NF)',      COUNT(*) FROM customers
UNION ALL SELECT 'products',             COUNT(DISTINCT product_id) FROM orders_bad WHERE product_id IS NOT NULL
UNION ALL SELECT 'products (3NF)',       COUNT(*) FROM products
UNION ALL SELECT 'classes',              COUNT(DISTINCT class_id) FROM orders_bad WHERE class_id IS NOT NULL
UNION ALL SELECT 'classes (3NF)',        COUNT(*) FROM product_classes
UNION ALL SELECT 'items rows',           COUNT(*) FROM orders_bad WHERE order_id IS NOT NULL AND product_id IS NOT NULL
UNION ALL SELECT 'items rows (3NF)',     COUNT(*) FROM order_items;

-- ------------------------------------------------------------
-- Проверка 3. Потери и лишние записи (сравнение ключей)
-- ------------------------------------------------------------
SELECT
  (SELECT COUNT(*) FROM
     (SELECT order_id, product_id FROM orders_bad
      WHERE order_id IS NOT NULL AND product_id IS NOT NULL) b
     LEFT JOIN order_items i
       ON i.order_id = b.order_id AND i.product_id = b.product_id
     WHERE i.order_id IS NULL) AS missing_from_3nf,
  (SELECT COUNT(*) FROM order_items i
     LEFT JOIN
     (SELECT order_id, product_id FROM orders_bad
      WHERE order_id IS NOT NULL AND product_id IS NOT NULL) b
       ON i.order_id = b.order_id AND i.product_id = b.product_id
     WHERE b.order_id IS NULL) AS extra_in_3nf;

-- ------------------------------------------------------------
-- Проверка 4. Полное «собранное» представление (JOIN пяти таблиц)
-- ------------------------------------------------------------
SELECT o.order_id,
       o.order_date,
       c.customer_id,
       c.customer_name,
       p.product_id,
       p.product_name,
       p.price,
       pc.class_id,
       pc.class_name,
       i.quantity
FROM orders o
JOIN customers c       ON c.customer_id = o.customer_id
JOIN order_items i     ON i.order_id    = o.order_id
JOIN products p        ON p.product_id  = i.product_id
JOIN product_classes pc ON pc.class_id  = p.class_id
ORDER BY o.order_id, p.product_id;

-- ------------------------------------------------------------
-- Тестовые запросы на новой схеме
-- ------------------------------------------------------------

-- 1. Один код заказа = один клиент (дублей в шапках нет)
SELECT o.order_id, c.customer_name
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY o.order_id;

-- 2. Сколько потратил каждый клиент
SELECT c.customer_name,
       SUM(p.price * i.quantity) AS total_spent
FROM customers c
JOIN orders o        ON o.customer_id = c.customer_id
JOIN order_items i   ON i.order_id    = o.order_id
JOIN products p      ON p.product_id  = i.product_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;

-- 3. Продажи по товарным классификациям
SELECT pc.class_name,
       SUM(p.price * i.quantity) AS total_sales
FROM product_classes pc
JOIN products p      ON p.class_id  = pc.class_id
JOIN order_items i   ON i.product_id = p.product_id
GROUP BY pc.class_id, pc.class_name
ORDER BY total_sales DESC;

-- 4. Товары каждой классификации
SELECT pc.class_name,
       GROUP_CONCAT(p.product_name ORDER BY p.product_id SEPARATOR ', ') AS products
FROM product_classes pc
JOIN products p ON p.class_id = pc.class_id
GROUP BY pc.class_id, pc.class_name;

-- ------------------------------------------------------------
-- Шаг 5 (после успешной проверки). Переименуем исходную таблицу
-- (не удаляем — на случай повторной проверки преподавателем)
-- ------------------------------------------------------------
RENAME TABLE orders_bad TO orders_bad_archive;

SHOW TABLES;
