FROM python:3.13.0-slim-bookworm AS builder

COPY requirements.txt /tmp
RUN \
    apt-get update && \
    apt-get install -y build-essential curl libpq-dev libmariadb-dev libffi-dev libssl-dev libcurl4-openssl-dev libpython3-dev pkg-config
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
ENV PATH=$PATH:/root/.cargo/bin
RUN \
    pip install --upgrade pip && \
    pip wheel --wheel-dir /wheels apprise uwsgi mysqlclient minio psycopg-c==3.2.3 -r /tmp/requirements.txt

COPY . /opt/healthchecks/
RUN \
    rm -rf /opt/healthchecks/.git && \
    rm -rf /opt/healthchecks/stuff

FROM python:3.13.0-slim-bookworm

RUN groupadd --gid 50000 hc && useradd --uid 50000 --gid 50000 --system hc

ENV PYTHONUNBUFFERED=1
WORKDIR /opt/healthchecks

RUN \
    apt-get update && \
    apt-get install -y libcurl4 libexpat1 libpq5 libmariadb3 libxml2 && \
    rm -rf /var/apt/cache && \
    rm -rf /var/lib/apt/lists

RUN --mount=type=bind,target=/wheels,source=/wheels,from=builder \
    pip install --upgrade pip && \
    pip install --no-cache /wheels/*

COPY --from=builder /opt/healthchecks/ /opt/healthchecks/
COPY docker/fetchstatus.py /opt/healthchecks/

RUN \
    rm -f /opt/healthchecks/hc/local_settings.py && \
    DEBUG=False SECRET_KEY=build-key ./manage.py collectstatic --noinput && \
    DEBUG=False SECRET_KEY=build-key ./manage.py compress

RUN mkdir /data && chown hc /data

USER hc

ENV USE_GZIP_MIDDLEWARE=True
HEALTHCHECK --interval=60s --retries=1 CMD ./fetchstatus.py
CMD [ "uwsgi", "/opt/healthchecks/docker/uwsgi.ini"]