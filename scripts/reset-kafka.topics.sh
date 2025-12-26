#!/usr/bin/env bash
set -euo pipefail

TOPICS=("entrada" "salida" "test-notebook")

for t in "${TOPICS[@]}"; do
  echo "Borrando topic $t ..."
  docker exec -it kafka bash -lc "/opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --delete --topic $t" || true
done
