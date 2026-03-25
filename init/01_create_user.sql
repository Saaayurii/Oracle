-- ============================================================
-- Lab 1: Create application user in XEPDB1
-- ============================================================
ALTER SESSION SET CONTAINER = XEPDB1;

CREATE USER bookstore IDENTIFIED BY Bookstore123
    DEFAULT TABLESPACE users
    TEMPORARY TABLESPACE temp
    QUOTA UNLIMITED ON users;

GRANT CONNECT, RESOURCE, CREATE VIEW TO bookstore;
GRANT CREATE PROCEDURE TO bookstore;
GRANT CREATE SEQUENCE TO bookstore;
GRANT CREATE TRIGGER TO bookstore;
GRANT EXECUTE ON DBMS_CRYPTO TO bookstore;

COMMIT;
