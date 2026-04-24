FROM adbgonzalez/hadoop:3.4.3-py312

# --- pasar a root para instalar e preparar Spark ---
USER root

# Instalar paquetes (sen recomendados) e limpar caches NA MESMA CAPA
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      wget \
      ca-certificates \
      tar \
      netcat-openbsd \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# ---- Spark ----
ARG SPARK_VERSION=4.1.1
ARG HADOOP_VERSION=3.4.3
ARG HADOOP_KAFKA_CLIENT_VERSION=3.4.2
ARG AWS_SDK_V2_BUNDLE_VERSION=2.35.4
ARG ICEBERG_RUNTIME_VERSION=1.10.1
ARG DELTA_VERSION=4.1.0
ARG KAFKA_CLIENTS_VERSION=3.9.1
ARG COMMONS_POOL2_VERSION=2.12.1
ARG JSR305_VERSION=3.0.0
ARG SCALA_PARALLEL_COLLECTIONS_VERSION=1.2.0
ARG SPARK_FILE=spark-${SPARK_VERSION}-bin-without-hadoop.tgz
ARG SPARK_URL=https://downloads.apache.org/spark/spark-${SPARK_VERSION}/${SPARK_FILE}

ENV SPARK_HOME=/opt/spark

RUN wget -q ${SPARK_URL} \
 && mkdir -p ${SPARK_HOME} \
 && tar -xzf ${SPARK_FILE} -C ${SPARK_HOME} --strip-components 1 \
 && rm -f ${SPARK_FILE}

 # ------------------------------------------------------------------
# JARs extra (S3A + Iceberg + Delta + Kafka) dentro da imaxe
# ------------------------------------------------------------------
RUN set -e; \
    mkdir -p /opt/spark/jars-extra; \
    wget -q -O /opt/spark/jars-extra/hadoop-aws-${HADOOP_VERSION}.jar \
      https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar; \
    wget -q -O /opt/spark/jars-extra/bundle-${AWS_SDK_V2_BUNDLE_VERSION}.jar \
      https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/${AWS_SDK_V2_BUNDLE_VERSION}/bundle-${AWS_SDK_V2_BUNDLE_VERSION}.jar; \
    wget -q -O /opt/spark/jars-extra/iceberg-spark-runtime-4.0_2.13-${ICEBERG_RUNTIME_VERSION}.jar \
      https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-4.0_2.13/${ICEBERG_RUNTIME_VERSION}/iceberg-spark-runtime-4.0_2.13-${ICEBERG_RUNTIME_VERSION}.jar; \
    wget -q -O /opt/spark/jars-extra/delta-spark_2.13-${DELTA_VERSION}.jar \
      https://repo1.maven.org/maven2/io/delta/delta-spark_2.13/${DELTA_VERSION}/delta-spark_2.13-${DELTA_VERSION}.jar; \
    wget -q -O /opt/spark/jars-extra/delta-storage-${DELTA_VERSION}.jar \
      https://repo1.maven.org/maven2/io/delta/delta-storage/${DELTA_VERSION}/delta-storage-${DELTA_VERSION}.jar; \
    wget -q -O /opt/spark/jars-extra/spark-sql-kafka-0-10_2.13-${SPARK_VERSION}.jar \
      https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.13/${SPARK_VERSION}/spark-sql-kafka-0-10_2.13-${SPARK_VERSION}.jar; \
    wget -q -O /opt/spark/jars-extra/spark-token-provider-kafka-0-10_2.13-${SPARK_VERSION}.jar \
      https://repo1.maven.org/maven2/org/apache/spark/spark-token-provider-kafka-0-10_2.13/${SPARK_VERSION}/spark-token-provider-kafka-0-10_2.13-${SPARK_VERSION}.jar; \
    wget -q -O /opt/spark/jars-extra/kafka-clients-${KAFKA_CLIENTS_VERSION}.jar \
      https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/${KAFKA_CLIENTS_VERSION}/kafka-clients-${KAFKA_CLIENTS_VERSION}.jar; \
    wget -q -O /opt/spark/jars-extra/commons-pool2-${COMMONS_POOL2_VERSION}.jar \
      https://repo1.maven.org/maven2/org/apache/commons/commons-pool2/${COMMONS_POOL2_VERSION}/commons-pool2-${COMMONS_POOL2_VERSION}.jar; \
    wget -q -O /opt/spark/jars-extra/jsr305-${JSR305_VERSION}.jar \
      https://repo1.maven.org/maven2/com/google/code/findbugs/jsr305/${JSR305_VERSION}/jsr305-${JSR305_VERSION}.jar; \
    wget -q -O /opt/spark/jars-extra/scala-parallel-collections_2.13-${SCALA_PARALLEL_COLLECTIONS_VERSION}.jar \
      https://repo1.maven.org/maven2/org/scala-lang/modules/scala-parallel-collections_2.13/${SCALA_PARALLEL_COLLECTIONS_VERSION}/scala-parallel-collections_2.13-${SCALA_PARALLEL_COLLECTIONS_VERSION}.jar; \
    wget -q -O /opt/spark/jars-extra/hadoop-client-runtime-${HADOOP_KAFKA_CLIENT_VERSION}.jar \
      https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-client-runtime/${HADOOP_KAFKA_CLIENT_VERSION}/hadoop-client-runtime-${HADOOP_KAFKA_CLIENT_VERSION}.jar; \
    wget -q -O /opt/spark/jars-extra/hadoop-client-api-${HADOOP_KAFKA_CLIENT_VERSION}.jar \
      https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-client-api/${HADOOP_KAFKA_CLIENT_VERSION}/hadoop-client-api-${HADOOP_KAFKA_CLIENT_VERSION}.jar


# variables de entorno (unificadas e sen conflitos)
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV LD_LIBRARY_PATH=${HADOOP_HOME}/lib/native
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PYSPARK_PYTHON=/usr/bin/python3
ENV PYSPARK_DRIVER_PYTHON=/usr/bin/python3
ENV SPARK_CONF=${SPARK_HOME}/conf
ENV SPARK_LOG_DIR=hdfs:///spark-logs
ENV SPARK_HISTORY_UI_PORT=18080
ENV SPARK_EVENTLOG_ENABLED=true
ENV SPARK_HISTORY_FS_LOG_DIRECTORY=hdfs:///spark-logs
ENV SPARK_EVENT_LOG_DIR=${SPARK_HISTORY_FS_LOG_DIRECTORY}
ENV SPARK_DAEMON_MEMORY=2g
ENV SPARK_HISTORY_FS_CLEANER_ENABLED=true
ENV SPARK_HISTORY_STORE_MAXDISKUSAGE=100g
ENV SPARK_HISTORY_FS_CLEANER_INTERVAL=8h
ENV SPARK_HISTORY_FS_CLEANER_MAXAGE=5d
ENV SPARK_HISTORY_FS_UPDATE_INTERVAL=10s
ENV SPARK_HISTORY_RETAINED_APPLICATIONS=100
ENV SPARK_HISTORY_UI_MAXAPPLICATIONS=500

# corrixido: "native" e non "nativ"
ENV HADOOP_INSTALL=${HADOOP_HOME}
ENV HADOOP_MAPRED_HOME=${HADOOP_HOME}
ENV HADOOP_COMMON_HOME=${HADOOP_HOME}
ENV HADOOP_HDFS_HOME=${HADOOP_HOME}
ENV HADOOP_YARN_HOME=${HADOOP_HOME}
ENV HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_HOME}/lib/native
ENV HADOOP_OPTS="-Djava.library.path=${HADOOP_HOME}/lib/native"

# PATHs
ENV PATH=${HADOOP_HOME}/sbin:${HADOOP_HOME}/bin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}

# spark-env: definir HADOOP_CONF_DIR/JAVA_HOME e SPARK_DIST_CLASSPATH dinámico
RUN mkdir -p ${SPARK_CONF} && \
    printf "export JAVA_HOME=%s\nexport HADOOP_CONF_DIR=%s\nexport SPARK_DIST_CLASSPATH=\$(${HADOOP_HOME}/bin/hadoop classpath)\n" \
      "${JAVA_HOME}" "${HADOOP_CONF_DIR}" > ${SPARK_CONF}/spark-env.sh && \
    chmod +x ${SPARK_CONF}/spark-env.sh

# Directorio de saída para o history server (local; os logs irán a HDFS segundo ENV)

RUN chown -R hadoop:hadoop ${SPARK_HOME} && \
    mkdir -p ${SPARK_HOME}/logs/history && \
    chown -R hadoop:hadoop ${SPARK_HOME}/logs && \
    chmod -R a+rwX ${SPARK_HOME}/logs


COPY conf/yarn-site.xml /usr/local/hadoop/etc/hadoop/yarn-site.xml
COPY spark-conf/spark-defaults.conf /opt/spark/conf/spark-defaults.conf


# --- (opcional) volver ao usuario non root se a base usa 'hadoop' ---
# Se a imaxe base tiña creado o usuario 'hadoop' (habitual), volve a el:
USER hadoop

# Directorio de traballo
WORKDIR ${SPARK_HOME}

# Portos Spark / YARN / HDFS (os 50070/50075/50090 son antigos; deixo só os modernos)
EXPOSE 8080 4040 7077 18080 8088 8042 9870 9864 9866 8020 9000

# Comando por defecto
CMD ["/bin/bash", "-c", "sleep infinity"]
