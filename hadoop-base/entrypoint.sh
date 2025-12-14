#!/usr/bin/env bash
set -euo pipefail

ROLE="${ROLE:-}"
NN_ID="${NN_ID:-nn1}"
LOCK_FILE="/data/hdfs/namenode/.init_done"

wait_for_host() {
  local host="$1"
  local port="$2"
  echo "Waiting for $host:$port ..."
  for i in {1..60}; do
    if nc -z "$host" "$port"; then
      echo "$host:$port is up."
      return 0
    fi
    sleep 2
  done
  echo "Timeout waiting for $host:$port"
  exit 1
}

export HADOOP_HOME=/opt/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
mkdir -p /var/log/hadoop

case "$ROLE" in
  journalnode)
    echo "Starting JournalNode..."
    "$HADOOP_HOME"/bin/hdfs --daemon start journalnode
    ;;

  namenode)
    # Warten auf ZK
    wait_for_host zk1 2181 || true
    wait_for_host zk2 2181 || true
    wait_for_host zk3 2181 || true

    if [ ! -f "$LOCK_FILE" ]; then
      echo "First start of $NN_ID..."
      if [ "$NN_ID" = "nn1" ]; then
        echo "Formatting NameNode (nn1)..."
        "$HADOOP_HOME"/bin/hdfs namenode -format -force -nonInteractive
      else
        echo "Bootstrapping Standby NameNode ($NN_ID)..."
        "$HADOOP_HOME"/bin/hdfs namenode -bootstrapStandby
      fi
      touch "$LOCK_FILE"
    else
      echo "$NN_ID already initialized, skipping format/bootstrap."
    fi

    echo "Starting NameNode daemon..."
    "$HADOOP_HOME"/bin/hdfs --daemon start namenode

    echo "Starting ZKFC daemon..."
    "$HADOOP_HOME"/bin/hdfs --daemon start zkfc
    ;;

  datanode)
    echo "Starting DataNode..."
    "$HADOOP_HOME"/bin/hdfs --daemon start datanode
    ;;

  resourcemanager)
    echo "Starting ResourceManager..."
    "$HADOOP_HOME"/bin/yarn --daemon start resourcemanager
    ;;

  nodemanager)
    echo "Starting NodeManager..."
    "$HADOOP_HOME"/bin/yarn --daemon start nodemanager
    ;;

  *)
    echo "Unknown ROLE=$ROLE"
    exit 1
    ;;
esac

# Container am Leben halten
tail -F /var/log/hadoop/* 2>/dev/null || tail -f /dev/null
