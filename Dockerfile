FROM adbgonzalez/hadoop:3.3.6

# --- pasar a root para instalar e preparar Spark ---
USER root

# Instalar paquetes (sen recomendados) e limpar caches NA MESMA CAPA
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 \
      wget \
      ca-certificates \
      tar \
      netcat-openbsd \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# ---- Spark ----
ARG SPARK_VERSION=3.5.7
ARG SPARK_FILE=spark-${SPARK_VERSION}-bin-without-hadoop.tgz
ARG SPARK_URL=https://downloads.apache.org/spark/spark-${SPARK_VERSION}/${SPARK_FILE}

ENV SPARK_HOME=/opt/spark

RUN wget -q ${SPARK_URL} \
 && mkdir -p ${SPARK_HOME} \
 && tar -xzf ${SPARK_FILE} -C ${SPARK_HOME} --strip-components 1 \
 && rm -f ${SPARK_FILE}

 # ------------------------------------------------------------------
# JARs extra (S3A + Iceberg runtime) dentro da imaxe
# ------------------------------------------------------------------
RUN set -e; \
    mkdir -p /opt/spark/jars-extra; \
    wget -q -O /opt/spark/jars-extra/hadoop-aws-3.3.6.jar \
      https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar; \
    wget -q -O /opt/spark/jars-extra/aws-java-sdk-bundle-1.12.262.jar \
      https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar; \
    wget -q -O /opt/spark/jars-extra/iceberg-spark-runtime-3.5_2.12-1.5.0.jar \
      https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.5.0/iceberg-spark-runtime-3.5_2.12-1.5.0.jar


# variables de entorno (unificadas e sen conflitos)
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV LD_LIBRARY_PATH=${HADOOP_HOME}/lib/native
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
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


# --- (opcional) volver ao usuario non root se a base usa 'hadoop' ---
# Se a imaxe base tiña creado o usuario 'hadoop' (habitual), volve a el:
USER hadoop

# Directorio de traballo
WORKDIR ${SPARK_HOME}

# Portos Spark / YARN / HDFS (os 50070/50075/50090 son antigos; deixo só os modernos)
EXPOSE 8080 4040 7077 18080 8088 8042 9870 9864 9866 8020 9000

# Comando por defecto
CMD ["/bin/bash", "-c", "sleep infinity"]