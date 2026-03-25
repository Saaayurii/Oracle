-- ============================================================
-- Lab 3: Stored procedures and functions — Bookstore Management System
-- ============================================================

-- ======================== PROCEDURES ========================

-- 1. place_order — create a new order; decrement stock
CREATE OR REPLACE PROCEDURE place_order (
    p_customer_id IN  customers.customer_id%TYPE,
    p_book_id     IN  books.book_id%TYPE,
    p_quantity    IN  NUMBER,
    p_order_id    OUT orders.order_id%TYPE
) AS
    v_price  books.price%TYPE;
    v_stock  books.stock_quantity%TYPE;
    v_total  NUMBER;
BEGIN
    SELECT price, stock_quantity
    INTO   v_price, v_stock
    FROM   books
    WHERE  book_id = p_book_id
    FOR UPDATE;

    IF v_stock < p_quantity THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Недостаточно товара на складе. Доступно: ' || v_stock);
    END IF;

    v_total := v_price * p_quantity;

    INSERT INTO orders (customer_id, order_date, status, total_amount)
    VALUES (p_customer_id, SYSDATE, 'NEW', v_total)
    RETURNING order_id INTO p_order_id;

    INSERT INTO order_items (order_id, book_id, quantity, unit_price)
    VALUES (p_order_id, p_book_id, p_quantity, v_price);

    UPDATE books
    SET    stock_quantity = stock_quantity - p_quantity
    WHERE  book_id = p_book_id;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END place_order;
/

-- 2. cancel_order — cancel an order; restore stock
CREATE OR REPLACE PROCEDURE cancel_order (
    p_order_id IN orders.order_id%TYPE
) AS
    v_status orders.status%TYPE;
BEGIN
    SELECT status INTO v_status
    FROM   orders
    WHERE  order_id = p_order_id
    FOR UPDATE;

    IF v_status IN ('DELIVERED', 'CANCELLED') THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Заказ со статусом ' || v_status || ' нельзя отменить.');
    END IF;

    UPDATE books b
    SET    b.stock_quantity = b.stock_quantity + (
               SELECT oi.quantity FROM order_items oi
               WHERE  oi.order_id = p_order_id AND oi.book_id = b.book_id
           )
    WHERE  b.book_id IN (
               SELECT book_id FROM order_items WHERE order_id = p_order_id
           );

    UPDATE orders SET status = 'CANCELLED' WHERE order_id = p_order_id;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Заказ с ID ' || p_order_id || ' не найден.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END cancel_order;
/

-- 3. update_stock — adjust stock quantity
CREATE OR REPLACE PROCEDURE update_stock (
    p_book_id IN books.book_id%TYPE,
    p_delta   IN NUMBER
) AS
    v_current books.stock_quantity%TYPE;
BEGIN
    SELECT stock_quantity INTO v_current
    FROM   books WHERE book_id = p_book_id FOR UPDATE;

    IF v_current + p_delta < 0 THEN
        RAISE_APPLICATION_ERROR(-20004,
            'Остаток не может быть отрицательным. Текущий: ' || v_current);
    END IF;

    UPDATE books SET stock_quantity = stock_quantity + p_delta
    WHERE  book_id = p_book_id;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20005, 'Книга с ID ' || p_book_id || ' не найдена.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END update_stock;
/

-- 4. generate_sales_report — print sales report via DBMS_OUTPUT
CREATE OR REPLACE PROCEDURE generate_sales_report (
    p_start_date IN DATE,
    p_end_date   IN DATE
) AS
    CURSOR c_sales IS
        SELECT o.order_id,
               c.first_name || ' ' || c.last_name AS customer_name,
               o.order_date, o.status, o.total_amount
        FROM   orders o JOIN customers c ON c.customer_id = o.customer_id
        WHERE  o.order_date BETWEEN p_start_date AND p_end_date
        ORDER  BY o.order_date;

    v_revenue NUMBER := 0;
    v_count   NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== ОТЧЁТ О ПРОДАЖАХ ===');
    DBMS_OUTPUT.PUT_LINE('Период: ' ||
        TO_CHAR(p_start_date,'DD.MM.YYYY') || ' — ' ||
        TO_CHAR(p_end_date,  'DD.MM.YYYY'));
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));

    FOR rec IN c_sales LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Заказ #' || rec.order_id || ' | ' ||
            RPAD(rec.customer_name, 25) || ' | ' ||
            TO_CHAR(rec.order_date,'DD.MM.YYYY') || ' | ' ||
            RPAD(rec.status, 10) || ' | ' ||
            TO_CHAR(rec.total_amount,'FM999G999D99') || ' руб.'
        );
        v_revenue := v_revenue + rec.total_amount;
        v_count   := v_count + 1;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 60, '='));
    DBMS_OUTPUT.PUT_LINE('Итого заказов : ' || v_count);
    DBMS_OUTPUT.PUT_LINE('Итого выручка : ' ||
        TO_CHAR(v_revenue,'FM999G999D99') || ' руб.');
END generate_sales_report;
/

-- ========================= FUNCTIONS ========================

-- 1. get_customer_total — total spent by customer (non-cancelled orders)
CREATE OR REPLACE FUNCTION get_customer_total (
    p_customer_id IN customers.customer_id%TYPE
) RETURN NUMBER AS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(total_amount), 0) INTO v_total
    FROM   orders
    WHERE  customer_id = p_customer_id AND status <> 'CANCELLED';
    RETURN v_total;
EXCEPTION
    WHEN OTHERS THEN RETURN 0;
END get_customer_total;
/

-- 2. get_book_availability — human-readable stock status
CREATE OR REPLACE FUNCTION get_book_availability (
    p_book_id IN books.book_id%TYPE
) RETURN VARCHAR2 AS
    v_qty books.stock_quantity%TYPE;
BEGIN
    SELECT stock_quantity INTO v_qty FROM books WHERE book_id = p_book_id;
    RETURN CASE
        WHEN v_qty = 0             THEN 'Нет в наличии'
        WHEN v_qty BETWEEN 1 AND 5 THEN 'Заканчивается (' || v_qty || ' шт.)'
        ELSE                           'В наличии (' || v_qty || ' шт.)'
    END;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 'Книга не найдена';
END get_book_availability;
/

-- 3. calculate_discount — discount percentage based on amount
CREATE OR REPLACE FUNCTION calculate_discount (
    p_amount IN NUMBER
) RETURN NUMBER AS
BEGIN
    RETURN CASE
        WHEN p_amount >= 5000 THEN 15
        WHEN p_amount >= 2000 THEN 10
        WHEN p_amount >= 1000 THEN 5
        ELSE                       0
    END;
END calculate_discount;
/

-- 4. get_author_full_name — formatted author name
CREATE OR REPLACE FUNCTION get_author_full_name (
    p_author_id IN authors.author_id%TYPE
) RETURN VARCHAR2 AS
    v_name VARCHAR2(210);
BEGIN
    SELECT last_name || ' ' || first_name INTO v_name
    FROM   authors WHERE author_id = p_author_id;
    RETURN v_name;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 'Автор не найден';
END get_author_full_name;
/

-- 5. get_top_book — most ordered book
CREATE OR REPLACE FUNCTION get_top_book RETURN VARCHAR2 AS
    v_title books.title%TYPE;
BEGIN
    SELECT b.title INTO v_title
    FROM   books b JOIN order_items oi ON oi.book_id = b.book_id
    GROUP  BY b.title
    ORDER  BY SUM(oi.quantity) DESC
    FETCH  FIRST 1 ROW ONLY;
    RETURN v_title;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 'Нет данных';
END get_top_book;
/

COMMIT;

-- ===================== USAGE EXAMPLES =======================
-- SET SERVEROUTPUT ON;
--
-- -- Call procedure:
-- DECLARE v_id NUMBER; BEGIN place_order(1, 3, 2, v_id);
--   DBMS_OUTPUT.PUT_LINE('Order ID: ' || v_id); END;
-- /
--
-- -- Call function:
-- SELECT get_customer_total(1)         AS total_spent    FROM dual;
-- SELECT get_book_availability(7)      AS availability   FROM dual;
-- SELECT calculate_discount(2500)      AS discount_pct   FROM dual;
-- SELECT get_author_full_name(2)       AS author_name    FROM dual;
-- SELECT get_top_book()                AS top_book       FROM dual;
--
-- -- Sales report:
-- BEGIN generate_sales_report(DATE '2024-01-01', DATE '2024-12-31'); END;
-- /
