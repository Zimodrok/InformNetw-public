#!/usr/bin/env bash
set -euo pipefail

DB_URL="${DATABASE_URL:-postgres://musicuser:1122334455@localhost/musicdb}"
SCHEMA_FILE="$(dirname "$0")/schema.sql"

if ! command -v psql >/dev/null 2>&1; then
  echo "psql not found; install PostgreSQL client and rerun" >&2
  exit 1
fi

echo "Initializing database using $SCHEMA_FILE"
psql "$DB_URL" -f "$SCHEMA_FILE"
