-- ============================================================
-- Lab 3: Stored functions
-- ============================================================
ALTER SESSION SET CONTAINER = XEPDB1;
ALTER SESSION SET CURRENT_SCHEMA = bookstore;

-- -------------------------------------------------------
-- Function 1: get_customer_total
-- Returns the total amount spent by a customer across all
-- non-cancelled orders.
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION get_customer_total (
    p_customer_id IN customers.customer_id%TYPE
) RETURN NUMBER AS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(total_amount), 0)
    INTO   v_total
    FROM   orders
    WHERE  customer_id = p_customer_id
    AND    status <> 'CANCELLED';

    RETURN v_total;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END get_customer_total;
/

-- -------------------------------------------------------
-- Function 2: get_book_availability
-- Returns a human-readable availability string.
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION get_book_availability (
    p_book_id IN books.book_id%TYPE
) RETURN VARCHAR2 AS
    v_qty books.stock_quantity%TYPE;
BEGIN
    SELECT stock_quantity
    INTO   v_qty
    FROM   books
    WHERE  book_id = p_book_id;

    RETURN CASE
        WHEN v_qty = 0            THEN 'Нет в наличии'
        WHEN v_qty BETWEEN 1 AND 5 THEN 'Заканчивается (' || v_qty || ' шт.)'
        ELSE                          'В наличии (' || v_qty || ' шт.)'
    END;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Книга не найдена';
END get_book_availability;
/

-- -------------------------------------------------------
-- Function 3: calculate_discount
-- Returns a discount percentage based on order amount.
-- -------------------------------------------------------
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

-- -------------------------------------------------------
-- Function 4: get_author_full_name
-- Returns formatted full name of an author.
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION get_author_full_name (
    p_author_id IN authors.author_id%TYPE
) RETURN VARCHAR2 AS
    v_name VARCHAR2(210);
BEGIN
    SELECT last_name || ' ' || first_name
    INTO   v_name
    FROM   authors
    WHERE  author_id = p_author_id;

    RETURN v_name;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Автор не найден';
END get_author_full_name;
/

-- -------------------------------------------------------
-- Function 5: get_top_book
-- Returns the title of the most-ordered book.
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION get_top_book RETURN VARCHAR2 AS
    v_title books.title%TYPE;
BEGIN
    SELECT b.title
    INTO   v_title
    FROM   books b
    JOIN   order_items oi ON oi.book_id = b.book_id
    GROUP  BY b.title
    ORDER  BY SUM(oi.quantity) DESC
    FETCH  FIRST 1 ROW ONLY;

    RETURN v_title;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Нет данных';
END get_top_book;
/

COMMIT;
