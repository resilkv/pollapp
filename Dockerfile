FROM python:3.11.15-slim AS build

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_TIMEOUT=60 

RUN apt-get update && apt-get install -y \
    postgresql postgresql-contrib \
    build-essential \
    libpq-dev && rm -rf /var/lib/apt/lists/*


WORKDIR /app


COPY requirements.txt .


RUN pip install -r requirements.txt 

COPY . .

FROM python:3.11.15-slim

RUN apt-get update && apt-get install -y \
    postgresql postgresql-contrib \
    build-essential \
    libpq-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app .
COPY --from=build /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/
COPY --from=build /usr/local/bin/gunicorn /usr/local/bin/gunicorn

COPY entrypoint.sh /app/entrypoint.sh 


RUN chmod +x entrypoint.sh
ENTRYPOINT [ "./entrypoint.sh" ]


EXPOSE 8000
CMD ["gunicorn", "mysite.wsgi:application","--bind" ,"0.0.0.0:8000"]