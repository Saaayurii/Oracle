-- ============================================================
-- Lab 2: Create database objects — Bookstore Management System
-- Run as SYS or SYSDBA connected to XEPDB1
-- ============================================================

-- Authors
CREATE TABLE authors (
    author_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name   VARCHAR2(100)  NOT NULL,
    last_name    VARCHAR2(100)  NOT NULL,
    birth_year   NUMBER(4),
    country      VARCHAR2(100)
);

-- Genres
CREATE TABLE genres (
    genre_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR2(100)  NOT NULL UNIQUE,
    description VARCHAR2(500)
);

-- Books
CREATE TABLE books (
    book_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title          VARCHAR2(300)  NOT NULL,
    author_id      NUMBER         NOT NULL,
    genre_id       NUMBER         NOT NULL,
    price          NUMBER(10, 2)  NOT NULL CHECK (price > 0),
    stock_quantity NUMBER(6)      DEFAULT 0 NOT NULL CHECK (stock_quantity >= 0),
    publish_year   NUMBER(4),
    isbn           VARCHAR2(20)   UNIQUE,
    CONSTRAINT fk_book_author FOREIGN KEY (author_id) REFERENCES authors(author_id),
    CONSTRAINT fk_book_genre  FOREIGN KEY (genre_id)  REFERENCES genres(genre_id)
);

-- Customers
CREATE TABLE customers (
    customer_id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name        VARCHAR2(100)  NOT NULL,
    last_name         VARCHAR2(100)  NOT NULL,
    email             VARCHAR2(200)  NOT NULL UNIQUE,
    phone             VARCHAR2(20),
    registration_date DATE           DEFAULT SYSDATE NOT NULL
);

-- Orders
CREATE TABLE orders (
    order_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  NUMBER         NOT NULL,
    order_date   DATE           DEFAULT SYSDATE NOT NULL,
    status       VARCHAR2(20)   DEFAULT 'NEW' NOT NULL
                     CHECK (status IN ('NEW','CONFIRMED','SHIPPED','DELIVERED','CANCELLED')),
    total_amount NUMBER(12, 2)  DEFAULT 0 NOT NULL,
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Order items
CREATE TABLE order_items (
    item_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id   NUMBER        NOT NULL,
    book_id    NUMBER        NOT NULL,
    quantity   NUMBER(4)     NOT NULL CHECK (quantity > 0),
    unit_price NUMBER(10, 2) NOT NULL CHECK (unit_price > 0),
    CONSTRAINT fk_item_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_item_book  FOREIGN KEY (book_id)  REFERENCES books(book_id)
);

-- Indexes
CREATE INDEX idx_books_author    ON books(author_id);
CREATE INDEX idx_books_genre     ON books(genre_id);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_items_order     ON order_items(order_id);
CREATE INDEX idx_items_book      ON order_items(book_id);

COMMIT;
