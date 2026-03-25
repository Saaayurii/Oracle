'use strict';

require('dotenv').config({ path: '.env' });
const oracledb = require('oracledb');

// Use thin mode — no Oracle Instant Client required
oracledb.initOracleClient = undefined; // ensure thin mode

const DB_CONFIG = {
  user:        process.env.DB_USER     || 'bookstore',
  password:    process.env.DB_PASSWORD || 'Bookstore123',
  connectString: `${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 1521}/${process.env.DB_SERVICE || 'XEPDB1'}`,
};

// Which lab to run (CLI: --lab 2 or --lab 3)
const args       = process.argv.slice(2);
const labIdx     = args.indexOf('--lab');
const targetLab  = labIdx !== -1 ? Number(args[labIdx + 1]) : 0; // 0 = all

// ─── helpers ────────────────────────────────────────────────────────────────

const GREEN  = '\x1b[32m';
const RED    = '\x1b[31m';
const YELLOW = '\x1b[33m';
const RESET  = '\x1b[0m';
const BOLD   = '\x1b[1m';

let passed = 0;
let failed = 0;

function ok(label)  { console.log(`  ${GREEN}✓${RESET} ${label}`); passed++; }
function fail(label, err) {
  console.log(`  ${RED}✗${RESET} ${label}`);
  if (err) console.log(`    ${RED}→ ${err.message || err}${RESET}`);
  failed++;
}
function section(title) {
  console.log(`\n${BOLD}${YELLOW}▶ ${title}${RESET}`);
}

async function query(conn, sql, binds = []) {
  return conn.execute(sql, binds, { outFormat: oracledb.OUT_FORMAT_OBJECT });
}

// ─── Lab 2: tables & data ───────────────────────────────────────────────────

async function verifyLab2(conn) {
  section('Лабораторная работа 2 — Таблицы и данные');

  const tables = ['AUTHORS', 'GENRES', 'BOOKS', 'CUSTOMERS', 'ORDERS', 'ORDER_ITEMS'];
  for (const tbl of tables) {
    try {
      const res = await query(conn,
        `SELECT COUNT(*) AS CNT FROM user_tables WHERE table_name = :1`, [tbl]);
      res.rows[0].CNT > 0 ? ok(`Таблица ${tbl} существует`) : fail(`Таблица ${tbl} не найдена`);
    } catch (e) { fail(`Таблица ${tbl}`, e); }
  }

  const expectedRows = { AUTHORS: 5, GENRES: 5, BOOKS: 10, CUSTOMERS: 5, ORDERS: 5, ORDER_ITEMS: 9 };
  for (const [tbl, minRows] of Object.entries(expectedRows)) {
    try {
      const res = await query(conn, `SELECT COUNT(*) AS CNT FROM ${tbl}`);
      const cnt = res.rows[0].CNT;
      cnt >= minRows
        ? ok(`${tbl}: ${cnt} записей (ожидалось ≥ ${minRows})`)
        : fail(`${tbl}: ${cnt} записей (ожидалось ≥ ${minRows})`);
    } catch (e) { fail(`Подсчёт строк ${tbl}`, e); }
  }

  // FK integrity
  try {
    const res = await query(conn,
      `SELECT COUNT(*) AS CNT FROM order_items oi
       LEFT JOIN orders o ON o.order_id = oi.order_id
       WHERE o.order_id IS NULL`);
    res.rows[0].CNT === 0
      ? ok('Целостность FK: order_items → orders')
      : fail(`Нарушение FK: ${res.rows[0].CNT} сирот в order_items`);
  } catch (e) { fail('Проверка FK', e); }

  // Constraints: price > 0
  try {
    const res = await query(conn, `SELECT COUNT(*) AS CNT FROM books WHERE price <= 0`);
    res.rows[0].CNT === 0
      ? ok('Ограничение CHECK: price > 0')
      : fail(`CHECK нарушен: ${res.rows[0].CNT} книг с price <= 0`);
  } catch (e) { fail('CHECK price', e); }
}

// ─── Lab 3: procedures & functions ──────────────────────────────────────────

async function verifyLab3(conn) {
  section('Лабораторная работа 3 — Процедуры и функции');

  const expected = [
    { name: 'PLACE_ORDER',          type: 'PROCEDURE' },
    { name: 'CANCEL_ORDER',         type: 'PROCEDURE' },
    { name: 'UPDATE_STOCK',         type: 'PROCEDURE' },
    { name: 'GENERATE_SALES_REPORT',type: 'PROCEDURE' },
    { name: 'GET_CUSTOMER_TOTAL',   type: 'FUNCTION'  },
    { name: 'GET_BOOK_AVAILABILITY',type: 'FUNCTION'  },
    { name: 'CALCULATE_DISCOUNT',   type: 'FUNCTION'  },
    { name: 'GET_AUTHOR_FULL_NAME', type: 'FUNCTION'  },
    { name: 'GET_TOP_BOOK',         type: 'FUNCTION'  },
  ];

  for (const obj of expected) {
    try {
      const res = await query(conn,
        `SELECT COUNT(*) AS CNT FROM user_objects
         WHERE object_name = :1 AND object_type = :2 AND status = 'VALID'`,
        [obj.name, obj.type]);
      res.rows[0].CNT > 0
        ? ok(`${obj.type} ${obj.name} — VALID`)
        : fail(`${obj.type} ${obj.name} не найдена или INVALID`);
    } catch (e) { fail(`${obj.type} ${obj.name}`, e); }
  }

  // Call: get_customer_total(1)
  try {
    const res = await query(conn,
      `SELECT get_customer_total(1) AS v FROM dual`);
    const v = res.rows[0].V;
    v >= 0
      ? ok(`get_customer_total(1) = ${v} руб.`)
      : fail(`get_customer_total вернула отрицательное значение`);
  } catch (e) { fail('get_customer_total', e); }

  // Call: get_book_availability(1)
  try {
    const res = await query(conn,
      `SELECT get_book_availability(1) AS v FROM dual`);
    const v = res.rows[0].V;
    v && v.length > 0
      ? ok(`get_book_availability(1) = "${v}"`)
      : fail(`get_book_availability вернула пустую строку`);
  } catch (e) { fail('get_book_availability', e); }

  // Call: calculate_discount
  const discountCases = [[500, 0], [1500, 5], [2500, 10], [6000, 15]];
  for (const [amount, expectedPct] of discountCases) {
    try {
      const res = await query(conn,
        `SELECT calculate_discount(:1) AS v FROM dual`, [amount]);
      const v = res.rows[0].V;
      v === expectedPct
        ? ok(`calculate_discount(${amount}) = ${v}%`)
        : fail(`calculate_discount(${amount}): ожидалось ${expectedPct}%, получено ${v}%`);
    } catch (e) { fail(`calculate_discount(${amount})`, e); }
  }

  // Call: get_author_full_name(1)
  try {
    const res = await query(conn,
      `SELECT get_author_full_name(1) AS v FROM dual`);
    const v = res.rows[0].V;
    v && v.length > 0
      ? ok(`get_author_full_name(1) = "${v}"`)
      : fail(`get_author_full_name вернула пустую строку`);
  } catch (e) { fail('get_author_full_name', e); }

  // Call: get_top_book
  try {
    const res = await query(conn, `SELECT get_top_book() AS v FROM dual`);
    const v = res.rows[0].V;
    v && v.length > 0
      ? ok(`get_top_book() = "${v}"`)
      : fail('get_top_book вернула пустую строку');
  } catch (e) { fail('get_top_book', e); }

  // place_order: create a test order (customer=5, book=4, qty=1) then cancel it
  try {
    const result = await conn.execute(
      `BEGIN place_order(:cust, :book, :qty, :oid); END;`,
      {
        cust: { val: 5,    dir: oracledb.BIND_IN,  type: oracledb.NUMBER },
        book: { val: 4,    dir: oracledb.BIND_IN,  type: oracledb.NUMBER },
        qty:  { val: 1,    dir: oracledb.BIND_IN,  type: oracledb.NUMBER },
        oid:  { val: null, dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    const newOid = result.outBinds.oid;
    ok(`place_order выполнена, order_id = ${newOid}`);

    // cancel the test order
    await conn.execute(
      `BEGIN cancel_order(:oid); END;`,
      { oid: { val: newOid, dir: oracledb.BIND_IN, type: oracledb.NUMBER } }
    );
    ok(`cancel_order(${newOid}) выполнена`);
  } catch (e) { fail('place_order / cancel_order', e); }

  // update_stock: add 5 to book 1
  try {
    const before = await query(conn,
      `SELECT stock_quantity AS q FROM books WHERE book_id = 1`);
    const qBefore = before.rows[0].Q;

    await conn.execute(
      `BEGIN update_stock(:bid, :delta); END;`,
      {
        bid:   { val: 1, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
        delta: { val: 5, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
      }
    );

    const after = await query(conn,
      `SELECT stock_quantity AS q FROM books WHERE book_id = 1`);
    const qAfter = after.rows[0].Q;

    qAfter === qBefore + 5
      ? ok(`update_stock: остаток book_id=1 изменён ${qBefore} → ${qAfter}`)
      : fail(`update_stock: ожидалось ${qBefore + 5}, получено ${qAfter}`);

    // Restore
    await conn.execute(
      `BEGIN update_stock(:bid, :delta); END;`,
      {
        bid:   { val: 1, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
        delta: { val: -5, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
      }
    );
  } catch (e) { fail('update_stock', e); }
}

// ─── Lab 4: APEX objects ─────────────────────────────────────────────────────

async function verifyLab4(conn) {
  section('Лабораторная работа 4 — APEX / Views');

  // Verify that all functions used in APEX pages are callable
  const apexQueries = [
    {
      label: 'Dashboard: total revenue',
      sql: `SELECT NVL(SUM(total_amount), 0) AS v FROM orders WHERE status = 'DELIVERED'`,
    },
    {
      label: 'Books report with availability',
      sql: `SELECT b.title, get_book_availability(b.book_id) AS avail
            FROM books b FETCH FIRST 3 ROWS ONLY`,
    },
    {
      label: 'Customer loyalty report',
      sql: `SELECT c.customer_id,
                   get_customer_total(c.customer_id)      AS spent,
                   calculate_discount(
                       get_customer_total(c.customer_id)) AS disc
            FROM customers c FETCH FIRST 3 ROWS ONLY`,
    },
    {
      label: 'Top book for home card',
      sql: `SELECT get_top_book() AS v FROM dual`,
    },
    {
      label: 'Orders with discount column',
      sql: `SELECT o.order_id, o.total_amount,
                   calculate_discount(o.total_amount) AS disc_pct
            FROM orders o FETCH FIRST 3 ROWS ONLY`,
    },
  ];

  for (const { label, sql } of apexQueries) {
    try {
      await query(conn, sql);
      ok(label);
    } catch (e) { fail(label, e); }
  }
}

// ─── main ────────────────────────────────────────────────────────────────────

async function main() {
  console.log(`\n${BOLD}Oracle Labs Verification${RESET}`);
  console.log(`Подключение: ${DB_CONFIG.connectString} (user: ${DB_CONFIG.user})`);

  let conn;
  try {
    conn = await oracledb.getConnection(DB_CONFIG);
    console.log(`${GREEN}Соединение установлено${RESET}`);
  } catch (e) {
    console.error(`${RED}Не удалось подключиться к Oracle:${RESET}`, e.message);
    console.error('Убедитесь, что контейнер запущен: docker compose up -d');
    process.exit(1);
  }

  try {
    if (targetLab === 0 || targetLab === 2) await verifyLab2(conn);
    if (targetLab === 0 || targetLab === 3) await verifyLab3(conn);
    if (targetLab === 0 || targetLab === 4) await verifyLab4(conn);
  } finally {
    await conn.close();
  }

  console.log(`\n${BOLD}Итог: ${GREEN}${passed} пройдено${RESET}${BOLD}, ${RED}${failed} не пройдено${RESET}\n`);
  process.exit(failed > 0 ? 1 : 0);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
