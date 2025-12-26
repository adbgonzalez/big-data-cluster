#!/bin/bash
set -e

KAFKA_DIR=/opt/kafka
CONFIG_FILE="$KAFKA_DIR/config/server.properties"
LOG_DIRS=${KAFKA_LOG_DIRS:-/tmp/kraft-combined-logs}

# Se a config non existe OU é legacy (non ten process.roles), rexenerámola para KRaft
if [ ! -f "$CONFIG_FILE" ] || ! grep -qE '^\s*process\.roles\s*=' "$CONFIG_FILE"; then
  echo ">> Xerando $CONFIG_FILE en modo KRaft (sobrescribindo legacy se existía)..."
  cat > "$CONFIG_FILE" <<EOF
process.roles=broker,controller
node.id=${KAFKA_NODE_ID:-1}

controller.quorum.voters=${KAFKA_CONTROLLER_QUORUM_VOTERS:-1@kafka:9093}

listeners=${KAFKA_LISTENERS:-PLAINTEXT://:9092,CONTROLLER://:9093}
advertised.listeners=${KAFKA_ADVERTISED_LISTENERS:-PLAINTEXT://kafka:9092}
listener.security.protocol.map=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT
inter.broker.listener.name=PLAINTEXT
controller.listener.names=CONTROLLER

log.dirs=${LOG_DIRS}
num.partitions=${KAFKA_NUM_PARTITIONS:-3}
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1

auto.create.topics.enable=${KAFKA_AUTO_CREATE_TOPICS_ENABLE:-true}
log.retention.hours=168
EOF
fi


# Format KRaft storage se aínda non está inicializado
if [ -z "$(ls -A "${LOG_DIRS}" 2>/dev/null)" ] || [ ! -f "${LOG_DIRS}/meta.properties" ]; then
  echo ">> Formateando storage KRaft en ${LOG_DIRS} ..."
  CLUSTER_ID=${KAFKA_CLUSTER_ID:-$("$KAFKA_DIR/bin/kafka-storage.sh" random-uuid)}
  "$KAFKA_DIR/bin/kafka-storage.sh" format -t "$CLUSTER_ID" -c "$CONFIG_FILE"
fi

echo ">> Arrincando Kafka en modo KRaft..."
exec "$KAFKA_DIR/bin/kafka-server-start.sh" "$CONFIG_FILE"
