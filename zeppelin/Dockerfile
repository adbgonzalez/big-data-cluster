FROM adbgonzalez/spark:3.5.7

ENV Z_VERSION=0.12.0

# Pasar a root para poder instalar paquetes
USER root

# Instalar curl e descargar Zeppelin
RUN mkdir -p /var/lib/apt/lists/partial && \
    apt-get update && apt-get install -y curl && \
    curl -L https://dlcdn.apache.org/zeppelin/zeppelin-${Z_VERSION}/zeppelin-${Z_VERSION}-bin-all.tgz \
      | tar -xz -C /opt && \
    mv /opt/zeppelin-${Z_VERSION}-bin-all /opt/zeppelin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV ZEPPELIN_HOME=/opt/zeppelin
ENV SPARK_HOME=/opt/spark
ENV PATH=$SPARK_HOME/bin:$ZEPPELIN_HOME/bin:$PATH

# Crear directorios que Zeppelin necesita e darlles permisos ao usuario 1000
RUN mkdir -p /opt/zeppelin/logs /opt/zeppelin/run && \
    chown -R 1000:1000 /opt/zeppelin

WORKDIR /opt/zeppelin

EXPOSE 8080

# ⚠️ Executar Zeppelin como o mesmo usuario que usas no notebook (UID 1000)
USER 1000:1000

CMD ["bin/zeppelin.sh"]
