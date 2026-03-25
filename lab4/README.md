# Лабораторная работа №4 — Создание простого приложения в Oracle APEX

## Цель работы

1. Создание простого веб-приложения в среде Oracle Application Express (APEX)
   с использованием App Builder.

---

## Предметная область

**Система управления книжным магазином** — веб-интерфейс для работы с каталогом книг,
покупателями и заказами. Процедуры и функции из Лаб. 3 используются в страницах APEX.

---

## Доступ к APEX

| Параметр   | Значение                       |
|------------|--------------------------------|
| URL        | http://localhost:8080/apex     |
| Workspace  | `INTERNAL` → затем создать своё|
| Admin      | `ADMIN` / `Oracle123`          |

---

## Структура приложения

### Страница 1 — Главная (Dashboard)

Показывает сводные карточки (Count / Sum cards):

- Всего книг в каталоге
- Активных заказов
- Зарегистрированных покупателей
- Общая выручка (доставленные заказы)
- Самая продаваемая книга: `SELECT get_top_book() FROM dual`

### Страница 2 — Каталог книг (Interactive Report)

```sql
SELECT b.book_id,
       b.title,
       a.last_name || ' ' || a.first_name  AS author,
       g.name                              AS genre,
       b.price,
       b.publish_year,
       get_book_availability(b.book_id)   AS availability
FROM   books b
JOIN   authors a ON a.author_id = b.author_id
JOIN   genres  g ON g.genre_id  = b.genre_id
ORDER  BY b.title
```

### Страница 3 — Форма книги (Form on BOOKS)

Создаётся мастером App Builder: `Create Page > Form > Table: BOOKS`.
Позволяет добавлять и редактировать книги.

### Страница 4 — Покупатели (Interactive Report + Form)

```sql
SELECT customer_id,
       first_name || ' ' || last_name      AS full_name,
       email, phone,
       TO_CHAR(registration_date,'DD.MM.YYYY') AS reg_date,
       get_customer_total(customer_id)    AS total_spent,
       calculate_discount(
           get_customer_total(customer_id)) || '%' AS discount
FROM customers
ORDER BY total_spent DESC
```

### Страница 5 — Заказы (Interactive Report)

```sql
SELECT o.order_id,
       c.first_name || ' ' || c.last_name  AS customer,
       TO_CHAR(o.order_date,'DD.MM.YYYY')  AS order_date,
       o.status,
       o.total_amount,
       calculate_discount(o.total_amount) || '%' AS discount_pct
FROM   orders o
JOIN   customers c ON c.customer_id = o.customer_id
ORDER  BY o.order_date DESC
```

### Страница 6 — Новый заказ (Form + PL/SQL Process)

**Элементы страницы:** `P6_CUSTOMER_ID`, `P6_BOOK_ID`, `P6_QUANTITY`

**Процесс (After Submit):**

```sql
DECLARE
    v_order_id NUMBER;
BEGIN
    place_order(:P6_CUSTOMER_ID, :P6_BOOK_ID, :P6_QUANTITY, v_order_id);
    :P6_ORDER_ID := v_order_id;
END;
```

### Страница 7 — Отчёт о продажах (Classic Report)

**Элементы:** `P7_START_DATE`, `P7_END_DATE` (тип Date Picker)

```sql
SELECT o.order_id,
       c.first_name || ' ' || c.last_name AS customer,
       o.order_date, o.status,
       o.total_amount,
       calculate_discount(o.total_amount) AS discount_pct
FROM   orders o
JOIN   customers c ON c.customer_id = o.customer_id
WHERE  o.order_date BETWEEN :P7_START_DATE AND :P7_END_DATE
ORDER  BY o.order_date
```

---

## Quick SQL

Quick SQL — инструмент APEX (SQL Workshop > Quick SQL) для быстрой генерации
DDL по короткой нотации. Файл `sql/apex_app.sql` содержит Quick SQL-шаблон
для создания таблиц приложения.

Открыть: **SQL Workshop → Quick SQL → вставить шаблон → Generate SQL**.

---

## Скриншоты

> Разместите скриншоты приложения в папку `lab4/screenshots/`
> после создания приложения в APEX.

---

## Контрольные вопросы

### 1. Что такое Oracle APEX?

**Oracle Application Express (APEX)** — встроенная в СУБД Oracle
низкокодовая платформа разработки веб-приложений. Все компоненты
(метаданные, код, данные) хранятся в самой БД. Приложения доступны
через браузер без установки дополнительного ПО на клиенте.

### 2. Преимущества Oracle APEX

- **Встроенность в Oracle DB** — нет дополнительных лицензий при использовании с XE.
- **Декларативная разработка** — большинство компонентов настраивается через GUI.
- **Высокая производительность** — данные и код рядом с БД.
- **Встроенная безопасность** — аутентификация, авторизация, защита от XSS/CSRF.
- **SQL Workshop** — инструменты работы с объектами БД прямо в браузере.
- **Responsive UI** — поддержка мобильных устройств из коробки.

### 3. Что такое App Builder?

**App Builder** — основной инструмент APEX для создания и управления приложениями.
Включает:
- Мастера создания страниц и компонентов.
- Дизайнер страниц (Page Designer) с панелями свойств.
- Навигатор приложения (Application Navigator).
- Средства отладки и профилирования.

### 4. Разделы App Builder, использованные в работе

| Раздел              | Использование                                        |
|---------------------|------------------------------------------------------|
| **Create App**      | Создание нового приложения с помощью мастера         |
| **Page Designer**   | Настройка регионов, элементов, процессов             |
| **Create Page**     | Добавление Interactive Report, Form, Classic Report  |
| **Shared Components**| Навигация, шаблоны страниц, списки значений (LOV)  |
| **Run Application** | Тестирование готового приложения                     |

### 5. В каких случаях применяется SQL Workshop?

**SQL Workshop** используется когда необходимо:
- Выполнять SQL-запросы и PL/SQL-блоки напрямую (SQL Commands).
- Просматривать и изменять объекты схемы (Object Browser).
- Загружать данные из CSV/Excel (Data Workshop).
- Генерировать DDL по Quick SQL-нотации (Quick SQL).
- Управлять RESTful-сервисами (RESTful Services).

### 6. Что такое Quick SQL?

**Quick SQL** — инструмент APEX, позволяющий описать структуру таблиц
в упрощённой нотации (похожей на YAML) и автоматически получить готовые
SQL-скрипты `CREATE TABLE` с первичными ключами, внешними ключами, индексами
и даже базовым APEX-приложением. Значительно ускоряет прототипирование схемы БД.
