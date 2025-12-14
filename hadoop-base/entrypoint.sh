#!/usr/bin/env bash
set -euo pipefail

ROLE="${ROLE:-}"
NN_ID="${NN_ID:-nn1}"

# Paths
NN_DIR="/data/hdfs/namenode"
LOCK_FILE="${NN_DIR}/.init_done"

# Hadoop env
export HADOOP_HOME=/opt/hadoop
export HADOOP_LOG_DIR=/opt/hadoop/logs
export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH"

mkdir -p "$HADOOP_LOG_DIR"

wait_for_host() {
  local host="$1" port="$2" name="${3:-$host:$port}"
  echo "Waiting for ${name} ..."
  for i in $(seq 1 60); do
    if nc -z "$host" "$port"; then
      echo "${name} is up."
      return 0
    fi
    sleep 2
  done
  echo "Timeout waiting for ${name}"
  exit 1
}

wait_for_journalnodes() {
  wait_for_host jn1 8485 "JournalNode jn1:8485"
  wait_for_host jn2 8485 "JournalNode jn2:8485"
  wait_for_host jn3 8485 "JournalNode jn3:8485"
}

wait_for_zk() {
  wait_for_host zk1 2181 "ZooKeeper zk1:2181"
  wait_for_host zk2 2181 "ZooKeeper zk2:2181"
  wait_for_host zk3 2181 "ZooKeeper zk3:2181"
}

case "${ROLE}" in
  journalnode)
    echo "Starting JournalNode..."
    # Ensure JN dir exists (if you use /tmp/hadoop/dfs/journalnode in hdfs-site.xml)
    mkdir -p /tmp/hadoop/dfs/journalnode || true
    "$HADOOP_HOME"/bin/hdfs --daemon start journalnode
    ;;

  namenode)
    echo "Preparing NameNode(${NN_ID})..."
    wait_for_zk
    wait_for_journalnodes

    if [ ! -f "${LOCK_FILE}" ]; then
      echo "First start detected for ${NN_ID}"

      if [ "${NN_ID}" = "nn1" ]; then
        echo "Formatting NameNode (nn1)..."
        "$HADOOP_HOME"/bin/hdfs namenode -format -force -nonInteractive

        echo "Formatting ZKFC state (one-time)..."
        "$HADOOP_HOME"/bin/hdfs zkfc -formatZK
      else
        echo "Bootstrapping Standby NameNode (${NN_ID})..."
        "$HADOOP_HOME"/bin/hdfs namenode -bootstrapStandby
      fi

      touch "${LOCK_FILE}"
    else
      echo "${NN_ID} already initialized, skipping one-time initialization."
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
    echo "Unknown ROLE=${ROLE}"
    exit 1
    ;;
esac

# Keep container running by tailing Hadoop logs
touch "${HADOOP_LOG_DIR}/entrypoint.log"
tail -F "${HADOOP_LOG_DIR}"/*.log "${HADOOP_LOG_DIR}/entrypoint.log"
