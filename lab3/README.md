# Лабораторная работа №3 — Создание хранимых процедур и функций в Oracle

## Цель работы

1. Создание хранимых процедур и функций на языке PL/SQL.

---

## Реализованные объекты

### Процедуры

| Процедура               | Параметры IN              | Параметры OUT  | Описание                                    |
|-------------------------|---------------------------|----------------|---------------------------------------------|
| `place_order`           | customer_id, book_id, qty | order_id       | Создаёт заказ, уменьшает остаток на складе  |
| `cancel_order`          | order_id                  | —              | Отменяет заказ, восстанавливает остаток     |
| `update_stock`          | book_id, delta            | —              | Корректирует количество книг (+ или -)       |
| `generate_sales_report` | start_date, end_date      | —              | Выводит отчёт о продажах через DBMS_OUTPUT  |

### Функции

| Функция                 | Параметры            | Возвращает    | Описание                                      |
|-------------------------|----------------------|---------------|-----------------------------------------------|
| `get_customer_total`    | customer_id          | NUMBER        | Сумма заказов покупателя (без отменённых)      |
| `get_book_availability` | book_id              | VARCHAR2      | Строка о наличии: «В наличии», «Заканчивается», «Нет» |
| `calculate_discount`    | amount               | NUMBER        | Процент скидки: 0 / 5 / 10 / 15              |
| `get_author_full_name`  | author_id            | VARCHAR2      | «Фамилия Имя» автора                          |
| `get_top_book`          | —                    | VARCHAR2      | Название самой продаваемой книги              |

---

## Примеры вызова

```sql
SET SERVEROUTPUT ON;

-- Создать заказ
DECLARE
    v_order_id NUMBER;
BEGIN
    place_order(1, 3, 2, v_order_id);
    DBMS_OUTPUT.PUT_LINE('Создан заказ ID: ' || v_order_id);
END;
/

-- Отменить заказ
BEGIN cancel_order(4); END;
/

-- Скорректировать склад (добавить 10 экземпляров книге ID=1)
BEGIN update_stock(1, 10); END;
/

-- Отчёт о продажах
BEGIN
    generate_sales_report(DATE '2024-01-01', DATE '2024-12-31');
END;
/

-- Функции в SELECT
SELECT
    get_customer_total(1)       AS total_spent,
    calculate_discount(1640)    AS discount_pct,
    get_author_full_name(1)     AS author_name,
    get_book_availability(7)    AS availability,
    get_top_book()              AS top_book
FROM dual;
```

---

## Структура процедуры `place_order`

```
place_order(customer_id, book_id, quantity, OUT order_id)
    │
    ├── SELECT price, stock_quantity FROM books FOR UPDATE
    │       ↓ проверка наличия; RAISE_APPLICATION_ERROR если нехватка
    ├── INSERT INTO orders → RETURNING order_id
    ├── INSERT INTO order_items
    ├── UPDATE books SET stock_quantity = stock_quantity - quantity
    └── COMMIT / ROLLBACK on exception
```

---

## Обработка ошибок

Все процедуры используют блок `EXCEPTION`:

```sql
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Запись не найдена');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
```

Пользовательские коды ошибок: `-20001` … `-20005`.

---

## Контрольные вопросы

### 1. Системные пользователи Oracle; роль DBA

| Пользователь | Назначение                                                      |
|--------------|-----------------------------------------------------------------|
| `SYS`        | Суперпользователь; владеет словарем данных; роль `SYSDBA`       |
| `SYSTEM`     | Администратор БД; не владеет словарем, но имеет широкие права   |
| `DBSNMP`     | Используется Oracle Enterprise Manager для мониторинга          |
| `OUTLN`      | Хранит стабильные планы выполнения запросов (Stored Outlines)   |
| `XS$NULL`    | Внутренний пользователь для Oracle Security                     |

**Роль DBA** — набор системных привилегий (`CREATE USER`, `DROP ANY TABLE` и др.),
позволяющий администрировать БД: управлять пользователями, таблицами,
проводить резервное копирование.

### 2. Табличные пространства; основные типы

**Табличное пространство (Tablespace)** — логический контейнер для объектов БД,
физически реализованный через один или несколько data files.

| Тип                 | Назначение                                                |
|---------------------|-----------------------------------------------------------|
| `SYSTEM`            | Словарь данных Oracle; создаётся автоматически             |
| `SYSAUX`            | Вспомогательные компоненты (APEX, AWR, EM Repository)     |
| `USERS`             | Пользовательские объекты по умолчанию                     |
| `TEMP`              | Временные операции (сортировка, hash join)                |
| `UNDO`              | Данные отката транзакций (read consistency)               |

### 3. Основные объекты БД Oracle

- **Таблицы (Tables)** — хранят данные в строках и столбцах.
- **Представления (Views)** — виртуальные таблицы на основе SELECT.
- **Индексы (Indexes)** — ускоряют поиск по таблицам.
- **Последовательности (Sequences)** — генераторы числовых значений.
- **Синонимы (Synonyms)** — псевдонимы объектов.
- **Процедуры / Функции / Пакеты** — хранимый PL/SQL-код.
- **Триггеры (Triggers)** — автоматически выполняемый код по событию.
- **Типы (Types)** — пользовательские типы данных.

### 4. Типы данных параметров процедур; передача параметров

| Режим  | Синтаксис | Описание                                     |
|--------|-----------|----------------------------------------------|
| `IN`   | `p IN t`  | Только чтение (по умолчанию); передаётся значение |
| `OUT`  | `p OUT t` | Только запись; возвращает значение вызывающему    |
| `IN OUT` | `p IN OUT t` | Чтение и запись; передаётся и возвращается  |

```sql
CREATE OR REPLACE PROCEDURE my_proc (
    p_in     IN     VARCHAR2,   -- входной параметр
    p_out    OUT    NUMBER,     -- выходной параметр
    p_inout  IN OUT DATE        -- двунаправленный
) AS ...
```

### 5. Синтаксис и вызов процедур

```sql
-- Создание
CREATE OR REPLACE PROCEDURE proc_name (
    param1 IN  type1,
    param2 OUT type2
) AS
    v_local type1;    -- локальные переменные
BEGIN
    -- тело процедуры
    v_local := param1;
    param2  := some_value;
EXCEPTION
    WHEN OTHERS THEN RAISE;
END proc_name;
/

-- Вызов из анонимного блока
DECLARE
    v_result NUMBER;
BEGIN
    proc_name('value', v_result);
    DBMS_OUTPUT.PUT_LINE(v_result);
END;
/

-- Вызов через EXECUTE
EXECUTE proc_name('value', :out_var);

-- Именованные параметры
BEGIN proc_name(param1 => 'value', param2 => :v); END;
```
