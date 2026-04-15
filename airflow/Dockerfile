FROM apache/airflow:3.1.8

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends openjdk-11-jre-headless && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=${JAVA_HOME}/bin:${PATH}

USER airflow

ARG AIRFLOW_VERSION=3.1.8
COPY requirements.txt /tmp/requirements.txt
RUN PYTHON_VERSION=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')") && \
    CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt" && \
    pip install --no-cache-dir --constraint "${CONSTRAINT_URL}" -r /tmp/requirements.txt
