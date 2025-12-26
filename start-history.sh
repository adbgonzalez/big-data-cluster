#!/bin/bash
set -e

echo "***** Inicio do script start-history.sh *****"

# Variables básicas
export SPARK_HOME=${SPARK_HOME:-/opt/spark}
export HADOOP_HOME=${HADOOP_HOME:-/usr/local/hadoop}
export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-$HADOOP_HOME/etc/hadoop}
export SPARK_LOG_DIR=${SPARK_LOG_DIR:-/opt/spark/logs}
export SPARK_HISTORY_UI_PORT=${SPARK_HISTORY_UI_PORT:-18080}
export EVENTLOG_DIR_URI=${EVENTLOG_DIR_URI:-hdfs://namenode:9000/spark-logs}

echo "SPARK_HOME = $SPARK_HOME"
echo "HADOOP_CONF_DIR = $HADOOP_CONF_DIR"
echo "SPARK_LOG_DIR = $SPARK_LOG_DIR"
echo "SPARK_HISTORY_UI_PORT = $SPARK_HISTORY_UI_PORT"
echo "EVENTLOG_DIR_URI = $EVENTLOG_DIR_URI"

# 1) Esperar a que o namenode resolva no DNS
for i in $(seq 1 60); do
  getent hosts namenode >/dev/null 2>&1 && break
  echo "Agardando a que o DNS resolva 'namenode'..."
  sleep 2
done

# 2) Esperar a que HDFS responda
for i in $(seq 1 60); do
  $HADOOP_HOME/bin/hdfs dfs -ls hdfs://namenode:9000/ >/dev/null 2>&1 && break
  echo "Agardando a que HDFS estea dispoñible..."
  sleep 2
done

# 3) Crear o directorio de event logs en HDFS como 'hadoop'
export HADOOP_USER_NAME=hadoop
$HADOOP_HOME/bin/hdfs dfs -mkdir -p "$EVENTLOG_DIR_URI" || true
$HADOOP_HOME/bin/hdfs dfs -chmod 1777 "$EVENTLOG_DIR_URI" || true

# 4) Crear o directorio local de logs se non existe
mkdir -p "$SPARK_LOG_DIR"


cat "$SPARK_HOME/conf/spark-defaults.conf"

# 6) Lanzar o HistoryServer en primeiro plano
export SPARK_HISTORY_OPTS="-Dspark.history.fs.logDirectory=$EVENTLOG_DIR_URI -Dspark.history.ui.port=$SPARK_HISTORY_UI_PORT"
export SPARK_NO_DAEMONIZE=true

echo "***** Iniciando Spark History Server *****"
exec $SPARK_HOME/sbin/start-history-server.sh