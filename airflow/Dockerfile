FROM apache/airflow:3.1.8

ARG HADOOP_VERSION=3.4.3
ARG AWS_SDK_V2_BUNDLE_VERSION=2.35.4
ARG ICEBERG_RUNTIME_VERSION=1.10.1

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-17-jre-headless \
        wget \
        ca-certificates && \
    mkdir -p /opt/spark/jars-extra && \
    wget -q -O /opt/spark/jars-extra/hadoop-aws-${HADOOP_VERSION}.jar \
        https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar && \
    wget -q -O /opt/spark/jars-extra/bundle-${AWS_SDK_V2_BUNDLE_VERSION}.jar \
        https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/${AWS_SDK_V2_BUNDLE_VERSION}/bundle-${AWS_SDK_V2_BUNDLE_VERSION}.jar && \
    wget -q -O /opt/spark/jars-extra/iceberg-spark-runtime-4.0_2.13-${ICEBERG_RUNTIME_VERSION}.jar \
        https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-4.0_2.13/${ICEBERG_RUNTIME_VERSION}/iceberg-spark-runtime-4.0_2.13-${ICEBERG_RUNTIME_VERSION}.jar && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=${JAVA_HOME}/bin:${PATH}

USER airflow

ARG AIRFLOW_VERSION=3.1.8
COPY requirements.txt /tmp/requirements.txt
RUN PYTHON_VERSION=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')") && \
    CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt" && \
    pip install --no-cache-dir --constraint "${CONSTRAINT_URL}" -r /tmp/requirements.txt
