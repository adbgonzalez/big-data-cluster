FROM adbgonzalez/spark:4.1.1-py312 AS spark_runtime

FROM apache/airflow:3.1.8

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-17-jre-headless \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=spark_runtime /opt/spark /opt/spark
COPY --from=spark_runtime /usr/local/hadoop /usr/local/hadoop

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV SPARK_HOME=/opt/spark
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_CONF_DIR=/opt/hadoop-conf
ENV HADOOP_INSTALL=${HADOOP_HOME}
ENV HADOOP_MAPRED_HOME=${HADOOP_HOME}
ENV HADOOP_COMMON_HOME=${HADOOP_HOME}
ENV HADOOP_HDFS_HOME=${HADOOP_HOME}
ENV HADOOP_YARN_HOME=${HADOOP_HOME}
ENV HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_HOME}/lib/native
ENV HADOOP_OPTS=-Djava.library.path=${HADOOP_HOME}/lib/native
ENV LD_LIBRARY_PATH=${HADOOP_HOME}/lib/native
ENV PATH=${JAVA_HOME}/bin:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}

USER airflow

ARG AIRFLOW_VERSION=3.1.8
COPY requirements.txt /tmp/requirements.txt
RUN PYTHON_VERSION=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')") && \
    CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt" && \
    pip install --no-cache-dir --constraint "${CONSTRAINT_URL}" -r /tmp/requirements.txt
