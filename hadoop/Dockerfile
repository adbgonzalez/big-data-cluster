ARG UBUNTU_VERSION=22.04
FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ARG HADOOP_VERSION=3.4.3
ARG JAVA_MAJOR=17
ARG AWS_SDK_V2_BUNDLE_VERSION=2.35.4
ENV HADOOP_VERSION=${HADOOP_VERSION}
ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_MAJOR}-openjdk-amd64
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_INSTALL=$HADOOP_HOME
ENV HADOOP_MAPRED_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_HOME=$HADOOP_HOME
ENV HADOOP_HDFS_HOME=$HADOOP_HOME
ENV HADOOP_YARN_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
ENV HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
ENV HADOOP_CLASSPATH=$HADOOP_HOME/share/hadoop/tools/lib/*
ENV PYSPARK_PYTHON=/usr/bin/python3
ENV PYSPARK_DRIVER_PYTHON=/usr/bin/python3

# Instalar Java e utilidades base
RUN sed -i 's|http://archive.ubuntu.com/ubuntu|http://azure.archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list \
 && sed -i '/jammy-backports/d' /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      software-properties-common gnupg \
      openjdk-${JAVA_MAJOR}-jdk-headless \
      ssh rsync wget curl net-tools ca-certificates \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Engadir Python 3.12 sobre Ubuntu 22.04
RUN add-apt-repository -y ppa:deadsnakes/ppa \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      python3.12 python3.12-venv \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Deixar Python 3.12 como runtime por defecto
RUN wget -q -O /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py \
 && python3.12 /tmp/get-pip.py \
 && rm -f /tmp/get-pip.py \
 && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
 && ln -sf /usr/bin/python3.12 /usr/bin/python

# Crear usuario/grupo reutilizando UID/GID 1000 se xa existen na base
RUN set -eux; \
    existing_group="$(getent group 1000 | cut -d: -f1 || true)"; \
    if [ -n "${existing_group}" ]; then \
      group_name="${existing_group}"; \
    else \
      groupadd --gid 1000 hadoop; \
      group_name="hadoop"; \
    fi; \
    if id -u hadoop >/dev/null 2>&1; then \
      usermod -g "${group_name}" hadoop; \
    elif getent passwd 1000 >/dev/null 2>&1; then \
      existing_user="$(getent passwd 1000 | cut -d: -f1)"; \
      usermod -l hadoop "${existing_user}"; \
      usermod -d /home/hadoop -m -g "${group_name}" -s /bin/bash hadoop; \
    else \
      useradd --uid 1000 --gid "${group_name}" --create-home --shell /bin/bash hadoop; \
    fi

WORKDIR /home/hadoop

# Descargar, extraer e borrar o tarball na mesma capa
RUN set -eux; \
    url="https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"; \
    wget -O /tmp/hadoop.tar.gz "$url"; \
    tar -xzf /tmp/hadoop.tar.gz -C /usr/local/; \
    mv /usr/local/hadoop-${HADOOP_VERSION} ${HADOOP_HOME}; \
    rm -f /tmp/hadoop.tar.gz; \
    chown -R hadoop:hadoop ${HADOOP_HOME}

# JARs para MinIO/S3A
RUN set -eux; \
    mkdir -p "$HADOOP_HOME/share/hadoop/tools/lib"; \
    base_url="https://repo1.maven.org/maven2"; \
    wget -O "$HADOOP_HOME/share/hadoop/tools/lib/hadoop-aws-${HADOOP_VERSION}.jar" \
      "$base_url/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar"; \
    wget -O "$HADOOP_HOME/share/hadoop/tools/lib/bundle-${AWS_SDK_V2_BUNDLE_VERSION}.jar" \
      "$base_url/software/amazon/awssdk/bundle/${AWS_SDK_V2_BUNDLE_VERSION}/bundle-${AWS_SDK_V2_BUNDLE_VERSION}.jar"; \
    chown -R hadoop:hadoop "$HADOOP_HOME/share/hadoop/tools/lib"

# Dirs de datos
RUN install -d -o hadoop -g hadoop /home/hadoop/namenode /home/hadoop/datanode

# Config
COPY conf/core-site.xml $HADOOP_HOME/etc/hadoop/
COPY conf/hdfs-site.xml $HADOOP_HOME/etc/hadoop/
COPY conf/mapred-site.xml $HADOOP_HOME/etc/hadoop/
COPY conf/yarn-site.xml $HADOOP_HOME/etc/hadoop/
COPY conf/capacity-scheduler.xml $HADOOP_HOME/etc/hadoop/
COPY conf/log4j.properties $HADOOP_HOME/etc/hadoop/

USER hadoop

# SSH para pseudo-distribuido
RUN mkdir -p ~/.ssh \
 && ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa \
 && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys \
 && chmod 700 ~/.ssh \
 && chmod 600 ~/.ssh/authorized_keys

EXPOSE 8088 8042 9870 9864 9866 8020 9000
CMD ["bash"]
