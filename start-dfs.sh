#!/bin/bash
echo "HEEERE******************************************************"
if [ ! -d "/home/hadoop/namenode/current" ]; then
    echo "Formatting NameNode..."
    hdfs namenode -format
fi
hdfs namenode