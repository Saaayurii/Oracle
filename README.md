# Oracle Database Labs

Лабораторные работы по дисциплине «Базы данных Oracle».
Предметная область: **Система управления книжным магазином**.

---

## Структура проекта

```
Oracle/
├── docker-compose.yml          # Oracle XE 21c контейнер
├── init/                       # SQL-скрипты, выполняемые при старте контейнера
│   ├── 01_create_user.sql      # Создание пользователя bookstore
│   ├── 02_create_tables.sql    # Лаб. 2 — создание таблиц
│   ├── 03_insert_data.sql      # Лаб. 2 — наполнение данными
│   ├── 04_procedures.sql       # Лаб. 3 — хранимые процедуры
│   └── 05_functions.sql        # Лаб. 3 — функции
├── lab1/README.md              # Лаб. 1 — установка Oracle XE
├── lab2/                       # Лаб. 2 — объекты БД
│   ├── README.md
│   └── sql/
├── lab3/                       # Лаб. 3 — процедуры и функции
│   ├── README.md
│   └── sql/
├── lab4/                       # Лаб. 4 — Oracle APEX
│   ├── README.md
│   └── sql/
└── verify/                     # Node.js-скрипт проверки лаб
    ├── package.json
    ├── verify.js
    └── .env.example
```

---

## Быстрый старт

### 1. Требования

- [Docker](https://docs.docker.com/get-docker/) ≥ 24
- [Docker Compose](https://docs.docker.com/compose/) v2
- [Node.js](https://nodejs.org/) ≥ 18 (для скрипта проверки)

### 2. Запуск Oracle XE

```bash
# Скопируйте файл с переменными окружения
cp .env.example .env

# Запустите контейнер (первый запуск занимает 3–5 мин)
docker compose up -d

# Следите за инициализацией
docker compose logs -f oracle-xe
```

Контейнер готов, когда в логах появится:

```
DATABASE IS READY TO USE!
```

### 2a. Применить SQL-скрипты

Init-скрипты из `init/` запускаются автоматически **только при первом старте** с пустым volume.
При повторном запуске (или если volume уже существовал) выполните:

```bash
bash scripts/setup.sh
```

### 3. Подключение к базе данных

| Параметр         | Значение          |
|------------------|-------------------|
| Host             | `localhost`        |
| Port             | `1521`             |
| Service / SID    | `XEPDB1`           |
| User (app)       | `bookstore`        |
| Password (app)   | `Bookstore123`     |
| User (admin)     | `SYSTEM`           |
| Password (admin) | `Oracle123`        |

```bash
# Подключение через sqlplus внутри контейнера
docker exec -it oracle_xe sqlplus bookstore/Bookstore123@XEPDB1
```

### 4. Oracle APEX

APEX доступен по адресу: **http://localhost:8080/apex**

| Параметр   | Значение   |
|------------|------------|
| Workspace  | `INTERNAL` |
| User       | `ADMIN`    |
| Password   | `Oracle123`|

---

## Запуск проверки (Node.js)

```bash
cd verify
cp .env.example .env    # при необходимости отредактируйте
npm install
npm run verify          # все лабораторные
npm run verify:lab2     # только Лаб. 2
npm run verify:lab3     # только Лаб. 3
```

Скрипт использует `oracledb` в **thin-режиме** — Oracle Instant Client не требуется.

---

## Лабораторные работы

| # | Тема                              | Статус |
|---|-----------------------------------|--------|
| 1 | Установка Oracle XE и APEX        | ✅     |
| 2 | Создание объектов БД              | ✅     |
| 3 | Хранимые процедуры и функции      | ✅     |
| 4 | Приложение на Oracle APEX         | ✅     |

---

## Схема базы данных

```
AUTHORS ──< BOOKS >── GENRES
              │
         ORDER_ITEMS
              │
           ORDERS
              │
          CUSTOMERS
```

### Таблицы

| Таблица      | Описание                        | Строк |
|--------------|---------------------------------|-------|
| AUTHORS      | Авторы книг                     | 5     |
| GENRES       | Жанры                           | 5     |
| BOOKS        | Книги                           | 10    |
| CUSTOMERS    | Покупатели                      | 5     |
| ORDERS       | Заказы                          | 5     |
| ORDER_ITEMS  | Позиции заказов                 | 9     |

### Процедуры

| Процедура               | Назначение                               |
|-------------------------|------------------------------------------|
| `place_order`           | Создаёт заказ, уменьшает остаток         |
| `cancel_order`          | Отменяет заказ, восстанавливает остаток  |
| `update_stock`          | Корректирует количество товара           |
| `generate_sales_report` | Выводит отчёт о продажах (DBMS_OUTPUT)   |

### Функции

| Функция                  | Возвращает                                  |
|--------------------------|---------------------------------------------|
| `get_customer_total`     | Сумму заказов покупателя                    |
| `get_book_availability`  | Строку о наличии книги                      |
| `calculate_discount`     | Процент скидки по сумме                     |
| `get_author_full_name`   | Полное имя автора                           |
| `get_top_book`           | Название самой продаваемой книги            |

---

## Остановка контейнера

```bash
docker compose down          # остановить, сохранив данные
docker compose down -v       # остановить и удалить том с данными
```
