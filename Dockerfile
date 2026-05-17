FROM superset-ru-final:latest

ARG BUILD_TRANSLATIONS=true

# Копирование файлов локализации
COPY messages.po /app/superset/translations/ru/LC_MESSAGES/messages.po
COPY messages.mo /app/superset/translations/ru/LC_MESSAGES/messages.mo
COPY messages.json /app/superset/translations/ru/LC_MESSAGES/messages.json

# Копирование конфигурационного файла Superset
COPY superset_config.py /app/superset_config.py

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        locales \
        gcc \
        python3-dev \
        libpq-dev && \
    sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=ru_RU.UTF-8 && \
    pip install psycopg2-binary && \
    apt-get remove -y gcc python3-dev && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU.UTF-8
ENV LC_ALL=ru_RU.UTF-8

# Указываем Superset использовать наш конфиг
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

USER superset