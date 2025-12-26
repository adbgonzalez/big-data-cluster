#!/usr/bin/env bash
set -euo pipefail

# AXUSTA AQUÍ se os checkpoints non están en ./work
WORK_DIR="$(cd "$(dirname "$0")/.." && pwd)/work"

if [ ! -d "$WORK_DIR" ]; then
  echo "Non existe: $WORK_DIR"
  exit 0
fi

rm -rf "$WORK_DIR"/kafka-wordcount-checkpoint*
echo "Checkpoints borrados en $WORK_DIR"
