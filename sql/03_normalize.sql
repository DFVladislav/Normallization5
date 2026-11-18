-- ============================================================
-- Шаг 3. Нормализация до 3NF: создание 5 таблиц
--   customers        — справочник клиентов    (customer_id → customer_name)
--   product_classes  — справочник классификаций (class_id → class_name)
--   products         — товары                 (product_id → product_name, price,
--                                              class_id; товары классифицируются
--                                              по коду товара)
--   orders           — шапки заказов          (order_id → order_date, customer_id;
--                                              каждый клиент проводится по коду заказа)
--   order_items      — позиции заказов        ((order_id, product_id) → quantity)
-- ============================================================

USE orders_norm_lab5;

-- Справочник клиентов (PK: customer_id)
CREATE TABLE customers (
    customer_id   INT          NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (customer_id)
);

-- Справочник товарных классификаций (PK: class_id)
CREATE TABLE product_classes (
    class_id   INT          NOT NULL,
    class_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (class_id)
);

-- Справочник товаров (PK: product_id, FK: class_id -> product_classes)
CREATE TABLE products (
    product_id   INT           NOT NULL,
    product_name VARCHAR(100)  NOT NULL,
    price        DECIMAL(10,2) NOT NULL,
    class_id     INT           NOT NULL,
    PRIMARY KEY (product_id),
    FOREIGN KEY (class_id) REFERENCES product_classes (class_id)
);

-- Шапки заказов (PK: order_id, FK: customer_id -> customers)
-- Клиент задаётся кодом в шапке заказа: один код заказа =
-- один клиент (проводим клиента по коду заказа).
CREATE TABLE orders (
    order_id    INT  NOT NULL,
    order_date  DATE NOT NULL,
    customer_id INT  NOT NULL,
    PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
);

-- Позиции заказов (PK составной: (order_id, product_id))
CREATE TABLE order_items (
    order_id   INT NOT NULL,
    product_id INT NOT NULL,
    quantity   INT NOT NULL,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id)   REFERENCES orders    (order_id),
    FOREIGN KEY (product_id) REFERENCES products (product_id)
);

-- ------------------------------------------------------------
-- Перенос данных из «плохой» таблицы (INSERT ... SELECT)
-- ------------------------------------------------------------

-- 1. Уникальные клиенты -> customers
INSERT INTO customers (customer_id, customer_name)
SELECT DISTINCT customer_id, customer_name
FROM orders_bad
WHERE customer_id IS NOT NULL;

-- 2. Уникальные классификации -> product_classes
INSERT INTO product_classes (class_id, class_name)
SELECT DISTINCT class_id, class_name
FROM orders_bad
WHERE class_id IS NOT NULL;

-- 3. Уникальные товары -> products (товар несёт свою классификацию)
INSERT INTO products (product_id, product_name, price, class_id)
SELECT DISTINCT product_id, product_name, price, class_id
FROM orders_bad
WHERE product_id IS NOT NULL;

-- 4. Уникальные шапки заказов -> orders
INSERT INTO orders (order_id, order_date, customer_id)
SELECT DISTINCT order_id, order_date, customer_id
FROM orders_bad
WHERE order_id IS NOT NULL;

-- 5. Позиции заказов -> order_items
INSERT INTO order_items (order_id, product_id, quantity)
SELECT order_id, product_id, quantity
FROM orders_bad
WHERE order_id IS NOT NULL AND product_id IS NOT NULL;

-- Что получилось
SELECT 'customers'        AS table_name, COUNT(*) AS rows_cnt FROM customers
UNION ALL SELECT 'product_classes', COUNT(*) FROM product_classes
UNION ALL SELECT 'products',        COUNT(*) FROM products
UNION ALL SELECT 'orders',          COUNT(*) FROM orders
UNION ALL SELECT 'order_items',     COUNT(*) FROM order_items;
