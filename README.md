# Poll App

A Django application for publishing questions, collecting votes, and displaying results. The repository also contains container, reverse-proxy, and Kubernetes deployment examples for running the app with PostgreSQL.

## Features

- Lists up to five most recently published questions; questions scheduled for the future are hidden.
- Shows a question's choices, accepts a vote, and displays the updated results.
- Provides Django admin pages for managing questions and choices, including inline choice editing, search, date filtering, and publication status.
- Uses PostgreSQL as its configured database and includes a Django migration for the poll models.
- Serves collected static assets through Nginx in the container examples.

## Technology

- Python 3.11 (Docker image)
- Django 5.0
- PostgreSQL and `psycopg2`
- Gunicorn
- Docker Compose, Docker Swarm, and Kubernetes deployment manifests
- Nginx for the containerized HTTP and static-file entry point

Redis is included as a service in the Compose and Swarm definitions, but the application does not currently use it.

## Run with Docker Compose

Docker Compose is the quickest way to run the full local stack. Create a `.env` file in the repository root with values for the database and Django connection:

```dotenv
DBNAME=pollapp
DBUSER=pollapp
DBPASSWORD=change-this-local-password
DBHOST=postgres
DBPORT=5432
```

Start the services:

```sh
docker compose up --build
```

The Django container waits for PostgreSQL, runs database migrations, collects static files, and starts Gunicorn. Nginx listens on port `80` and proxies requests to Django.

- Polls: <http://localhost/polls/>
- Django admin: <http://localhost/admin/>

Create an admin account in another terminal:

```sh
docker compose exec django python manage.py createsuperuser
```

Stop the stack with `Ctrl+C`, or run `docker compose down`. PostgreSQL data is stored in a named Docker volume and remains after containers stop. To remove it as well, run `docker compose down --volumes`.

## Run locally

Local development requires Python 3.11 or compatible and a PostgreSQL server. The Django settings read the database connection from environment variables; configure them for your local PostgreSQL instance before running management commands.

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt

export DBNAME=pollapp
export DBUSER=pollapp
export DBPASSWORD=your-local-password
export DBHOST=localhost
export DBPORT=5432

python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

Visit <http://127.0.0.1:8000/polls/>. The project root route is not mapped to the polls app; use `/polls/`.

## Tests

Run the Django test suite with a working PostgreSQL connection configured:

```sh
python manage.py test polls
```

The existing tests cover recent-publication logic and the question index, including the exclusion of future questions.

## Routes

| URL | Purpose |
| --- | --- |
| `/polls/` | Recent published questions |
| `/polls/<question-id>/` | Question and voting form |
| `/polls/<question-id>/vote/` | Submit a vote |
| `/polls/<question-id>/results/` | Vote totals |
| `/admin/` | Django administration |

## Repository layout

```text
mysite/             Django project settings and URL/WSGI/ASGI entry points
polls/              Poll models, views, routes, admin, tests, migration, templates, and styles
nginx/              Nginx reverse-proxy configuration
pollapp-k8s/        Kubernetes application, database, networking, storage, and RBAC manifests
static/             Collected Django admin static assets
Dockerfile          Multi-stage image build; runs Gunicorn via entrypoint.sh
entrypoint.sh       Waits for PostgreSQL, migrates, collects static files, then starts the app
docker-compose.yml  Local Django, PostgreSQL, Redis, and Nginx stack
docker-stack.yml    Docker Swarm example with replicated Django service
requirements.txt    Python dependencies
manage.py           Django management command entry point
```

## Container and cluster deployment files

`docker-compose.yml` describes a local stack with Django, PostgreSQL, Redis, and Nginx. `docker-stack.yml` is a separate Swarm-oriented example with an overlay network, persistent volumes, two Django replicas, and rolling-update settings. Both expose HTTP through Nginx; the Compose file also publishes PostgreSQL port `5432` for local access.

The `pollapp-k8s/` directory contains example Kubernetes resources for:

- Django deployment, service, configuration, secrets, and a one-off migration Job.
- An Nginx Ingress and CPU-based Horizontal Pod Autoscaler.
- PostgreSQL service/headless service, StatefulSet, persistent volume and claim, and a network policy.
- A scheduled Django cleanup CronJob, developer service account, Role and RoleBinding.
- A standalone pod and a Kind registry configuration.

These manifests are cluster-specific examples, not a turnkey production deployment. Review image names, namespaces, ingress support, storage configuration, image-pull secrets, and secret handling before applying them. The database configuration is not consistent across all manifests, and several files are alternate or development resources; do not apply the directory indiscriminately. The cleanup CronJob currently invokes `manage.py cleanup_old_data`, but this repository does not define that management command.

## Security and current limitations

- Do not deploy with the development `SECRET_KEY`, `DEBUG` setting, or empty `ALLOWED_HOSTS` unchanged. Configure production settings and secure secrets before exposing the app.
- Replace example Kubernetes credentials and image references with environment-specific values. Kubernetes Secret manifests are not a substitute for a managed secret store.
- Voting currently increments a choice's count without authentication or duplicate-vote prevention.
- Redis is provisioned in the container examples but is not integrated with the application.
- Configure Django's `ALLOWED_HOSTS` for the hostname used by your deployment; the current settings leave it empty.