#!/bin/sh

set -e #stop if anything fails

echo "Waiting for database..."

while ! pg_isready -h localhost -p 5432; do
    echo "Postgres is unavailable - sleeping"
    sleep 1
done

python manage.py migrate

echo "Collect Static"

python manage.py collectstatic --noinput

exec "$@"