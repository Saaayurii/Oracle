#!/usr/bin/env bash
# Run all init SQL scripts manually inside a running oracle_xe container.
# Usage: bash scripts/setup.sh [container_name]
set -euo pipefail

CONTAINER=${1:-oracle_xe}
SYS_PASS=${ORACLE_PASSWORD:-Oracle123}
APP_PASS=${APP_USER_PASSWORD:-Bookstore123}
APP_USER=${APP_USER:-bookstore}
PDB=${ORACLE_DATABASE:-XEPDB1}

run_sql() {
  local file="$1"
  local conn="$2"
  echo "▶  $(basename "$file")"
  docker exec -i "$CONTAINER" bash -c "sqlplus -S $conn <<'ENDSQL'
$(cat "$file")
EXIT;
ENDSQL"
}

echo "=== Oracle XE Setup: $CONTAINER / $PDB ==="

# 1. Create app user (as SYSDBA)
echo ""
echo "Step 1: Creating user $APP_USER..."
docker exec -i "$CONTAINER" bash -c "sqlplus -S sys/${SYS_PASS}@${PDB} as sysdba" <<ENDSQL
BEGIN
  EXECUTE IMMEDIATE 'CREATE USER ${APP_USER} IDENTIFIED BY ${APP_PASS}
    DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp QUOTA UNLIMITED ON users';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -1920 THEN
      DBMS_OUTPUT.PUT_LINE('User ${APP_USER} already exists, skipping.');
    ELSE RAISE;
    END IF;
END;
/
GRANT CONNECT, RESOURCE, CREATE VIEW TO ${APP_USER};
GRANT CREATE PROCEDURE TO ${APP_USER};
GRANT CREATE SEQUENCE TO ${APP_USER};
GRANT CREATE TRIGGER TO ${APP_USER};
SELECT 'USER OK' AS status FROM dual;
EXIT;
ENDSQL

APP_CONN="${APP_USER}/${APP_PASS}@${PDB}"
INIT_DIR="$(cd "$(dirname "$0")/../init" && pwd)"

# 2–5: Run remaining init scripts as app user
for script in "$INIT_DIR"/0{2,3,4,5}_*.sql; do
  echo ""
  echo "Step: running $(basename "$script")..."
  docker cp "$script" "${CONTAINER}:/tmp/$(basename "$script")"
  docker exec "$CONTAINER" bash -c "sqlplus -S $APP_CONN @/tmp/$(basename "$script")"
done

echo ""
echo "=== Setup complete! Run: cd verify && npm run verify ==="
