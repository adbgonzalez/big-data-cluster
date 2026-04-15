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

# Instalar paquetes (sen recomendados) e limpar caches na mesma capa
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      openjdk-${JAVA_MAJOR}-jdk-headless ssh rsync wget curl net-tools ca-certificates \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Crear usuario/grupo
RUN groupadd --gid 1000 hadoop \
 && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash hadoop

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

USER hadoop

# SSH para pseudo-distribuido
RUN mkdir -p ~/.ssh \
 && ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa \
 && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys \
 && chmod 700 ~/.ssh \
 && chmod 600 ~/.ssh/authorized_keys

EXPOSE 8088 8042 9870 9864 9866 8020 9000
CMD ["bash"]
