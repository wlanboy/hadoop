# build
```bash
docker compose build
```

# init
```bash
# ZK + JNs zuerst
docker compose up -d zk1 zk2 zk3 jn1 jn2 jn3

docker compose run --rm nn1 bash
hdfs namenode -format
HADOOP_OPTS="-Ddfs.ha.namenode.id=nn1" hdfs zkfc -formatZK
hdfs --daemon start namenode
hdfs --daemon start zkfc
exit

docker compose run --rm nn2 bash
hdfs namenode -bootstrapStandby
hdfs --daemon start namenode
hdfs --daemon start zkfc
exit

# NameNodes starten
docker compose up -d nn1
docker compose up -d nn2

# Datanodes und yarn
docker-compose up -d dn1 dn2 dn3 rm nm
``

# start after init
```bash
docker compose up -d
```

# web uis
* http://localhost:9870
* http://localhost:9871

# commands
```bash
docker exec -it nn1 hdfs --daemon start zkfc
docker exec -it nn2 hdfs --daemon start zkfc

docker exec -it nn1 hdfs haadmin -getServiceState nn1
docker exec -it nn1 hdfs haadmin -getServiceState nn2
docker exec -it nn1 hdfs haadmin -transitionToActive nn1
```

# init transfer folder and start transfer
```bash
docker exec nn1 hdfs dfs -ls /

docker exec nn1 hdfs dfs -mkdir -p /data

docker exec nn1 hadoop distcp hdfs://oldcluster:8020/data hdfs://ns1/data
```

# delete
```bash 
docker compose down -v 
``