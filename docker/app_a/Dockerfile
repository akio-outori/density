FROM jfloff/alpine-python:3.7

COPY files/requirements.txt /app/requirements.txt
COPY files/app_a.py /app/app_a.py

RUN pip install --upgrade pip \
    && pip install -r /app/requirements.txt

CMD python /app/app_a.py
