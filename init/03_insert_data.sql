-- ============================================================
-- Lab 2: Populate tables with sample data
-- ============================================================
ALTER SESSION SET CONTAINER = XEPDB1;
ALTER SESSION SET CURRENT_SCHEMA = bookstore;

-- Authors
INSERT INTO authors (first_name, last_name, birth_year, country)
VALUES ('Лев',       'Толстой',    1828, 'Россия');
INSERT INTO authors (first_name, last_name, birth_year, country)
VALUES ('Фёдор',     'Достоевский',1821, 'Россия');
INSERT INTO authors (first_name, last_name, birth_year, country)
VALUES ('Антон',     'Чехов',      1860, 'Россия');
INSERT INTO authors (first_name, last_name, birth_year, country)
VALUES ('Джордж',    'Оруэлл',     1903, 'Великобритания');
INSERT INTO authors (first_name, last_name, birth_year, country)
VALUES ('Габриэль',  'Маркес',     1927, 'Колумбия');

-- Genres
INSERT INTO genres (name, description)
VALUES ('Роман',    'Крупное прозаическое произведение');
INSERT INTO genres (name, description)
VALUES ('Повесть',  'Среднее по объёму прозаическое произведение');
INSERT INTO genres (name, description)
VALUES ('Рассказ',  'Малая форма художественной прозы');
INSERT INTO genres (name, description)
VALUES ('Антиутопия','Жанр, описывающий нежелательное будущее общество');
INSERT INTO genres (name, description)
VALUES ('Магический реализм', 'Реальные события переплетаются с мистическими элементами');

-- Books
INSERT INTO books (title, author_id, genre_id, price, stock_quantity, publish_year, isbn)
VALUES ('Война и мир',            1, 1, 890.00, 15, 1869, '978-5-04-096512-3');
INSERT INTO books (title, author_id, genre_id, price, stock_quantity, publish_year, isbn)
VALUES ('Анна Каренина',          1, 1, 750.00, 12, 1878, '978-5-04-096513-0');
INSERT INTO books (title, author_id, genre_id, price, stock_quantity, publish_year, isbn)
VALUES ('Преступление и наказание',2, 1, 680.00, 20, 1866, '978-5-04-096514-7');
INSERT INTO books (title, author_id, genre_id, price, stock_quantity, publish_year, isbn)
VALUES ('Идиот',                  2, 1, 720.00,  8, 1869, '978-5-04-096515-4');
INSERT INTO books (title, author_id, genre_id, price, stock_quantity, publish_year, isbn)
VALUES ('Вишнёвый сад',           3, 2, 450.00, 25, 1904, '978-5-04-096516-1');
INSERT INTO books (title, author_id, genre_id, price, stock_quantity, publish_year, isbn)
VALUES ('Дама с собачкой',        3, 3, 320.00, 30, 1899, '978-5-04-096517-8');
INSERT INTO books (title, author_id, genre_id, price, stock_quantity, publish_year, isbn)
VALUES ('1984',                   4, 4, 550.00, 18, 1949, '978-5-04-096518-5');
INSERT INTO books (title, author_id, genre_id, price, stock_quantity, publish_year, isbn)
VALUES ('Скотный двор',           4, 4, 390.00, 22, 1945, '978-5-04-096519-2');
INSERT INTO books (title, author_id, genre_id, price, stock_quantity, publish_year, isbn)
VALUES ('Сто лет одиночества',    5, 5, 820.00, 10, 1967, '978-5-04-096520-8');
INSERT INTO books (title, author_id, genre_id, price, stock_quantity, publish_year, isbn)
VALUES ('Любовь во время чумы',   5, 5, 760.00,  6, 1985, '978-5-04-096521-5');

-- Customers
INSERT INTO customers (first_name, last_name, email, phone, registration_date)
VALUES ('Иван',    'Петров',   'ivan.petrov@mail.ru',    '+79001234567', DATE '2024-01-15');
INSERT INTO customers (first_name, last_name, email, phone, registration_date)
VALUES ('Мария',   'Иванова',  'maria.ivanova@gmail.com','+79007654321', DATE '2024-02-20');
INSERT INTO customers (first_name, last_name, email, phone, registration_date)
VALUES ('Алексей', 'Сидоров',  'alexey.s@yandex.ru',    '+79003456789', DATE '2024-03-10');
INSERT INTO customers (first_name, last_name, email, phone, registration_date)
VALUES ('Елена',   'Козлова',  'elena.k@mail.ru',        '+79009876543', DATE '2024-04-05');
INSERT INTO customers (first_name, last_name, email, phone, registration_date)
VALUES ('Дмитрий', 'Новиков',  'dmitry.n@gmail.com',    '+79005555555', DATE '2024-05-18');

-- Orders
INSERT INTO orders (customer_id, order_date, status, total_amount)
VALUES (1, DATE '2024-06-01', 'DELIVERED', 1640.00);
INSERT INTO orders (customer_id, order_date, status, total_amount)
VALUES (2, DATE '2024-06-05', 'SHIPPED',    820.00);
INSERT INTO orders (customer_id, order_date, status, total_amount)
VALUES (3, DATE '2024-06-10', 'CONFIRMED', 1230.00);
INSERT INTO orders (customer_id, order_date, status, total_amount)
VALUES (1, DATE '2024-06-15', 'NEW',        550.00);
INSERT INTO orders (customer_id, order_date, status, total_amount)
VALUES (4, DATE '2024-06-20', 'DELIVERED',  770.00);

-- Order items
INSERT INTO order_items (order_id, book_id, quantity, unit_price)
VALUES (1, 1, 1, 890.00);
INSERT INTO order_items (order_id, book_id, quantity, unit_price)
VALUES (1, 2, 1, 750.00);
INSERT INTO order_items (order_id, book_id, quantity, unit_price)
VALUES (2, 9, 1, 820.00);
INSERT INTO order_items (order_id, book_id, quantity, unit_price)
VALUES (3, 3, 1, 680.00);
INSERT INTO order_items (order_id, book_id, quantity, unit_price)
VALUES (3, 8, 1, 390.00);
INSERT INTO order_items (order_id, book_id, quantity, unit_price)
VALUES (3, 6, 1, 320.00);
INSERT INTO order_items (order_id, book_id, quantity, unit_price)
VALUES (4, 7, 1, 550.00);
INSERT INTO order_items (order_id, book_id, quantity, unit_price)
VALUES (5, 5, 1, 450.00);
INSERT INTO order_items (order_id, book_id, quantity, unit_price)
VALUES (5, 6, 1, 320.00);

COMMIT;
