FROM jfloff/alpine-python:2.7-slim

COPY files/requirements.txt /app/requirements.txt
COPY files/app_a.py /app/app_a.py

RUN pip install --upgrade pip \
    && pip install -r /app/requirements.txt

EXPOSE 5000

CMD ["python", "/app/app_a.py"]
