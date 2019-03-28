FROM jfloff/alpine-python:2.7

COPY files/* /app/

RUN apk add --no-cache sqlite \
    && pip install --upgrade pip \
    && pip install -r /app/requirements.txt

EXPOSE 5001

CMD sqlite3 database.db < /app/schema.sql && python /app/app_b.py
