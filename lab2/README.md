# Лабораторная работа №2 — Создание объектов базы данных в Oracle

## Цель работы

1. Первоначальная настройка Oracle Database Express Edition.
2. Создание БД (схемы) и связанных таблиц.
3. Заполнение БД тестовыми данными.

---

## Предметная область

**Система управления книжным магазином** — учёт авторов, книг, жанров,
покупателей и заказов.

---

## Схема базы данных

```
┌──────────┐       ┌──────────┐       ┌──────────┐
│  AUTHORS │──────<│  BOOKS   │>──────│  GENRES  │
│──────────│       │──────────│       │──────────│
│ author_id│       │ book_id  │       │ genre_id │
│first_name│       │ title    │       │ name     │
│ last_name│       │author_id │       │description│
│birth_year│       │ genre_id │       └──────────┘
│ country  │       │ price    │
└──────────┘       │stock_qty │
                   │pub_year  │
                   │ isbn     │
                   └────┬─────┘
                        │
                   ┌────┴──────┐
                   │ORDER_ITEMS│
                   │───────────│
                   │  item_id  │
                   │ order_id  │
                   │  book_id  │
                   │ quantity  │
                   │unit_price │
                   └────┬──────┘
                        │
                   ┌────┴─────┐       ┌───────────┐
                   │  ORDERS  │>──────│ CUSTOMERS │
                   │──────────│       │───────────│
                   │ order_id │       │customer_id│
                   │customer_id       │first_name │
                   │order_date│       │ last_name │
                   │  status  │       │   email   │
                   │total_amt │       │   phone   │
                   └──────────┘       │reg_date   │
                                      └───────────┘
```

### Описание таблиц

| Таблица     | PK          | FK                         | Уникальные поля |
|-------------|-------------|----------------------------|-----------------|
| AUTHORS     | author_id   | —                          | —               |
| GENRES      | genre_id    | —                          | name            |
| BOOKS       | book_id     | author_id, genre_id        | isbn            |
| CUSTOMERS   | customer_id | —                          | email           |
| ORDERS      | order_id    | customer_id                | —               |
| ORDER_ITEMS | item_id     | order_id, book_id          | —               |

---

## Запуск

SQL-скрипты выполняются автоматически при старте контейнера (`docker compose up -d`).

Ручное выполнение:

```bash
docker exec -it oracle_xe sqlplus bookstore/Bookstore123@XEPDB1 @/sql/create_tables.sql
docker exec -it oracle_xe sqlplus bookstore/Bookstore123@XEPDB1 @/sql/insert_data.sql
```

Или через SQL*Plus:

```sql
-- Проверка созданных таблиц
SELECT table_name FROM user_tables ORDER BY table_name;

-- Проверка данных
SELECT COUNT(*) FROM books;      -- 10
SELECT COUNT(*) FROM customers;  -- 5
SELECT COUNT(*) FROM orders;     -- 5
```

---

## Ключевые SQL-конструкции

### Создание таблицы с ограничениями

```sql
CREATE TABLE books (
    book_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title          VARCHAR2(300)  NOT NULL,
    author_id      NUMBER         NOT NULL,
    price          NUMBER(10, 2)  NOT NULL CHECK (price > 0),
    stock_quantity NUMBER(6)      DEFAULT 0 NOT NULL CHECK (stock_quantity >= 0),
    CONSTRAINT fk_book_author FOREIGN KEY (author_id) REFERENCES authors(author_id)
);
```

### Связанный запрос (JOIN)

```sql
SELECT b.title,
       a.last_name || ' ' || a.first_name AS author,
       g.name                             AS genre,
       b.price,
       b.stock_quantity
FROM   books b
JOIN   authors a ON a.author_id = b.author_id
JOIN   genres  g ON g.genre_id  = b.genre_id
ORDER  BY b.title;
```

### Агрегация

```sql
SELECT c.first_name || ' ' || c.last_name AS customer,
       COUNT(o.order_id)                  AS order_count,
       SUM(o.total_amount)                AS total_spent
FROM   customers c
JOIN   orders o ON o.customer_id = c.customer_id
WHERE  o.status = 'DELIVERED'
GROUP  BY c.first_name, c.last_name
ORDER  BY total_spent DESC;
```

---

## Контрольные вопросы

### 1. Экземпляр базы данных

Экземпляр Oracle — это совокупность фоновых процессов (PMON, SMON, DBWn, LGWR и др.)
и области памяти SGA, которые обеспечивают работу с файлами БД. Экземпляр существует
в оперативной памяти; без него файлы БД недоступны.

### 2. Основные виды файлов БД Oracle

| Файл                        | Назначение                                    |
|-----------------------------|-----------------------------------------------|
| Data files (`.dbf`)         | Хранение данных таблиц, индексов, сегментов   |
| Redo log files              | Журнал транзакций для восстановления           |
| Control file                | Метаданные о структуре БД                     |
| Parameter file (SPFILE/PFILE)| Параметры конфигурации экземпляра            |
| Archive log files           | Архивные журналы (при ARCHIVELOG mode)         |
| Temp files                  | Временные операции (сортировка, хеш-соединения)|

### 3. Что такое SGA?

**System Global Area (SGA)** — разделяемая область памяти, выделяемая Oracle при
старте экземпляра. Содержит:

- **Buffer Cache** — кеш блоков данных из data files.
- **Shared Pool** — кеш разобранных SQL-запросов и PL/SQL-кода.
- **Redo Log Buffer** — буфер записей журнала.
- **Large Pool** — для параллельных операций и резервного копирования.
- **Java Pool** — для JVM в Oracle.

### 4. Табличные пространства и файлы данных

Каждое **табличное пространство** (tablespace) логически объединяет один или несколько
физических **data files**. Объекты схемы (таблицы, индексы) хранятся в конкретном
табличном пространстве, а физически — в его data files. Расширение tablesapce
осуществляется добавлением новых файлов или авторасширением существующих.

### 5. Выделенные и разделяемые серверы

| Режим              | Описание                                                     |
|--------------------|--------------------------------------------------------------|
| Dedicated Server   | Отдельный процесс на каждое соединение клиента; прост, но дорог при многих сессиях |
| Shared Server (MTS)| Пул серверных процессов обслуживает много клиентов; требует Dispatcher-процессов; экономит память |
