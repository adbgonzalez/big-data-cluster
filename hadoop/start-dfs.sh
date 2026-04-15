#!/bin/bash
set -euo pipefail

if [ ! -d "/home/hadoop/namenode/current" ]; then
    echo "Formatting NameNode..."
    hdfs namenode -format -nonInteractive
fi

exec hdfs namenode
