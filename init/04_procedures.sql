-- ============================================================
-- Lab 3: Stored procedures
-- ============================================================
ALTER SESSION SET CONTAINER = XEPDB1;
ALTER SESSION SET CURRENT_SCHEMA = bookstore;

-- -------------------------------------------------------
-- Procedure 1: place_order
-- Creates a new order for a customer with a single book.
-- Decrements stock automatically.
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE place_order (
    p_customer_id IN  customers.customer_id%TYPE,
    p_book_id     IN  books.book_id%TYPE,
    p_quantity    IN  NUMBER,
    p_order_id    OUT orders.order_id%TYPE
) AS
    v_price        books.price%TYPE;
    v_stock        books.stock_quantity%TYPE;
    v_total        NUMBER;
BEGIN
    -- Check book exists and has enough stock
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

    -- Create order
    INSERT INTO orders (customer_id, order_date, status, total_amount)
    VALUES (p_customer_id, SYSDATE, 'NEW', v_total)
    RETURNING order_id INTO p_order_id;

    -- Add order item
    INSERT INTO order_items (order_id, book_id, quantity, unit_price)
    VALUES (p_order_id, p_book_id, p_quantity, v_price);

    -- Decrement stock
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

-- -------------------------------------------------------
-- Procedure 2: cancel_order
-- Cancels an order and restores book stock.
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE cancel_order (
    p_order_id IN orders.order_id%TYPE
) AS
    v_status orders.status%TYPE;
BEGIN
    SELECT status
    INTO   v_status
    FROM   orders
    WHERE  order_id = p_order_id
    FOR UPDATE;

    IF v_status IN ('DELIVERED', 'CANCELLED') THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Заказ со статусом ' || v_status || ' нельзя отменить.');
    END IF;

    -- Restore stock for each item
    UPDATE books b
    SET    b.stock_quantity = b.stock_quantity + (
               SELECT oi.quantity
               FROM   order_items oi
               WHERE  oi.order_id = p_order_id
               AND    oi.book_id  = b.book_id
           )
    WHERE  b.book_id IN (
               SELECT book_id FROM order_items WHERE order_id = p_order_id
           );

    -- Update order status
    UPDATE orders
    SET    status = 'CANCELLED'
    WHERE  order_id = p_order_id;

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

-- -------------------------------------------------------
-- Procedure 3: update_stock
-- Updates stock quantity for a book (add or subtract).
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE update_stock (
    p_book_id  IN books.book_id%TYPE,
    p_delta    IN NUMBER               -- positive = add, negative = subtract
) AS
    v_current books.stock_quantity%TYPE;
BEGIN
    SELECT stock_quantity
    INTO   v_current
    FROM   books
    WHERE  book_id = p_book_id
    FOR UPDATE;

    IF v_current + p_delta < 0 THEN
        RAISE_APPLICATION_ERROR(-20004,
            'Остаток не может быть отрицательным. Текущий остаток: ' || v_current);
    END IF;

    UPDATE books
    SET    stock_quantity = stock_quantity + p_delta,
           price          = price          -- touch row to update row SCN
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

-- -------------------------------------------------------
-- Procedure 4: generate_sales_report
-- Outputs a sales report for a given date range using DBMS_OUTPUT.
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE generate_sales_report (
    p_start_date IN DATE,
    p_end_date   IN DATE
) AS
    CURSOR c_sales IS
        SELECT o.order_id,
               c.first_name || ' ' || c.last_name AS customer_name,
               o.order_date,
               o.status,
               o.total_amount
        FROM   orders    o
        JOIN   customers c ON c.customer_id = o.customer_id
        WHERE  o.order_date BETWEEN p_start_date AND p_end_date
        ORDER  BY o.order_date;

    v_total_revenue NUMBER := 0;
    v_order_count   NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== ОТЧЁТ О ПРОДАЖАХ ===');
    DBMS_OUTPUT.PUT_LINE('Период: ' ||
        TO_CHAR(p_start_date, 'DD.MM.YYYY') || ' — ' ||
        TO_CHAR(p_end_date,   'DD.MM.YYYY'));
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));

    FOR rec IN c_sales LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Заказ #' || rec.order_id ||
            ' | ' || RPAD(rec.customer_name, 25) ||
            ' | ' || TO_CHAR(rec.order_date, 'DD.MM.YYYY') ||
            ' | ' || RPAD(rec.status, 10) ||
            ' | ' || TO_CHAR(rec.total_amount, 'FM999G999D99') || ' руб.'
        );
        v_total_revenue := v_total_revenue + rec.total_amount;
        v_order_count   := v_order_count + 1;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 60, '='));
    DBMS_OUTPUT.PUT_LINE('Итого заказов : ' || v_order_count);
    DBMS_OUTPUT.PUT_LINE('Итого выручка : ' || TO_CHAR(v_total_revenue, 'FM999G999D99') || ' руб.');
END generate_sales_report;
/

COMMIT;
