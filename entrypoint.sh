#!/bin/sh

set -e

echo "Waiting for database..."

until pg_isready \
  -h "$DBHOST" \
  -p "$DBPORT" \
  -U "$DBUSER" \
  -d "$DBNAME"; do

  echo "Postgres is unavailable - sleeping"
  sleep 1

done

echo "Postgres is ready!"

echo "Running migrations..."

python manage.py migrate

echo "Migrations completed!"

echo "Collect Static..."

python manage.py collectstatic --noinput

echo "Starting application..."

exec "$@"