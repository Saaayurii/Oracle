-- ============================================================
-- Lab 4: Oracle APEX — Quick SQL & Application Setup
-- Предметная область: Система управления книжным магазином
-- ============================================================

-- ---------------------------------------------------------------
-- Quick SQL definition (paste into APEX > SQL Workshop > Quick SQL)
-- ---------------------------------------------------------------
/*
authors
  first_name  vc100 /nn
  last_name   vc100 /nn
  birth_year  num
  country     vc100

genres
  name        vc100 /nn /unique
  description vc500

books
  title          vc300 /nn
  author_id      num /nn /fk authors
  genre_id       num /nn /fk genres
  price          num /nn
  stock_quantity num /default 0
  publish_year   num
  isbn           vc20 /unique

customers
  first_name        vc100 /nn
  last_name         vc100 /nn
  email             vc200 /nn /unique
  phone             vc20
  registration_date date /default sysdate

orders
  customer_id  num /nn /fk customers
  order_date   date /default sysdate
  status       vc20 /default NEW
  total_amount num /default 0

order_items
  order_id   num /nn /fk orders
  book_id    num /nn /fk books
  quantity   num /nn
  unit_price num /nn
*/

-- ---------------------------------------------------------------
-- APEX Workspace setup (run as SYSDBA)
-- ---------------------------------------------------------------

-- Grant APEX user access
-- (Oracle XE 21c has APEX pre-installed; workspace created via browser)
--
-- Access APEX at: http://localhost:8080/apex
-- Internal workspace: INTERNAL
-- Admin user: ADMIN
-- Default password: set during Oracle XE installation

-- ---------------------------------------------------------------
-- APEX Application pages (created via App Builder GUI):
--
-- Page 1  — Home dashboard
--   • Count cards: Books, Customers, Orders, Revenue
--
-- Page 2  — Books report (Interactive Report)
--   SELECT b.book_id, b.title,
--          a.last_name || ' ' || a.first_name AS author,
--          g.name AS genre, b.price,
--          bookstore.get_book_availability(b.book_id) AS availability
--   FROM   books b
--   JOIN   authors a ON a.author_id = b.author_id
--   JOIN   genres  g ON g.genre_id  = b.genre_id
--   ORDER  BY b.title;
--
-- Page 3  — Book form (add / edit book)
--   Source table: BOOKS
--
-- Page 4  — Customers (Interactive Report + Form)
--
-- Page 5  — Orders (Interactive Report)
--   SELECT o.order_id, c.first_name || ' ' || c.last_name AS customer,
--          o.order_date, o.status,
--          o.total_amount,
--          bookstore.calculate_discount(o.total_amount) || '%' AS discount
--   FROM   orders o JOIN customers c ON c.customer_id = o.customer_id
--   ORDER  BY o.order_date DESC;
--
-- Page 6  — New Order wizard (calls place_order procedure)
--   Process: PL/SQL
--     DECLARE v_id NUMBER;
--     BEGIN
--       bookstore.place_order(:P6_CUSTOMER_ID, :P6_BOOK_ID,
--                             :P6_QUANTITY, v_id);
--       :P6_ORDER_ID := v_id;
--     END;
--
-- Page 7  — Sales Report (Classic Report)
--   Calls generate_sales_report via DBMS_OUTPUT or inline SELECT.
--   SELECT o.order_id,
--          c.first_name || ' ' || c.last_name AS customer,
--          o.order_date, o.status, o.total_amount
--   FROM   orders o JOIN customers c ON c.customer_id = o.customer_id
--   WHERE  o.order_date BETWEEN :P7_START_DATE AND :P7_END_DATE;
-- ---------------------------------------------------------------

-- ---------------------------------------------------------------
-- Dashboard query (Home page — Count cards)
-- ---------------------------------------------------------------
-- Total books:
SELECT COUNT(*) FROM books;

-- Total customers:
SELECT COUNT(*) FROM customers;

-- Active orders:
SELECT COUNT(*) FROM orders WHERE status NOT IN ('DELIVERED','CANCELLED');

-- Total revenue:
SELECT NVL(SUM(total_amount), 0) FROM orders WHERE status = 'DELIVERED';

-- Top selling book:
SELECT bookstore.get_top_book() AS top_book FROM dual;

-- ---------------------------------------------------------------
-- Customer loyalty report (uses stored function)
-- ---------------------------------------------------------------
SELECT c.customer_id,
       c.first_name || ' ' || c.last_name                    AS full_name,
       c.email,
       bookstore.get_customer_total(c.customer_id)           AS total_spent,
       bookstore.calculate_discount(
           bookstore.get_customer_total(c.customer_id))      AS discount_pct
FROM   customers c
ORDER  BY total_spent DESC;
