FROM jfloff/alpine-python:3.7

COPY files/* /app/

RUN apk add --no-cache sqlite \
    && pip install --upgrade pip \
    && pip install -r /app/requirements.txt

CMD sqlite3 db.connection < /app/schema.sql && python /app/app_b.py
