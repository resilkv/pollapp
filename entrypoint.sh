#!/bin/sh

set -e #stop if anything fails

echo "Waiting for database..."

until pg_isready -h "$DBHOST" -p "$DBPORT" -U "$DBUSER" -d "$DBNAME"; do
  echo "Postgres is unavailable - sleeping"
  sleep 1
done

python manage.py migrate

echo "Collect Static"

python manage.py collectstatic --noinput

exec "$@"