FROM debian:11

# Actualizamos e instalamos dependencias do sistema
RUN apt update && \
    apt install -y \
        procps \
        openjdk-11-jre-headless \
        wget \
        ca-certificates \
    && apt clean && rm -rf /var/lib/apt/lists/*


# Descargamos e descomprimimos Kafka (3.9.0)
RUN wget -q https://downloads.apache.org/kafka/3.9.0/kafka_2.13-3.9.0.tgz -O /tmp/kafka.tgz && \
    tar -xzf /tmp/kafka.tgz -C /opt && \
    rm /tmp/kafka.tgz && \
    mv /opt/kafka_* /opt/kafka

# Directorio de logs para KRaft (broker + controller)
RUN mkdir -p /tmp/kraft-combined-logs

# Copiamos o script de entrada
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

# Definimos o directorio de traballo
WORKDIR /opt/kafka

# Expor porto de Kafka
EXPOSE 9092

# Variables de entorno por defecto (podes sobreescribilas en docker-compose)
ENV KAFKA_LOG_DIRS=/tmp/kraft-combined-logs \
    KAFKA_NODE_ID=1 \
    KAFKA_CONTROLLER_QUORUM_VOTERS=1@kafka:9093 \
    KAFKA_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093 \
    KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092 \
    KAFKA_NUM_PARTITIONS=3 \
    KAFKA_AUTO_CREATE_TOPICS_ENABLE=true

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
