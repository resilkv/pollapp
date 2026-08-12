#!/bin/sh

set -e #stop if anything fails

echo "Waiting for database..."

PGHOST="${POSTGRES_HOST:-host.docker.internal}"
PGPORT="${POSTGRES_PORT:-5432}"
PGUSER="${POSTGRES_USER:-resil}"

until pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER"; do
  echo "Postgres is unavailable - sleeping"
  sleep 1
done

python manage.py migrate

echo "Collect Static"

python manage.py collectstatic --noinput

exec "$@"