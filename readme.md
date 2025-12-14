# build
```bash
docker compose build
```

# init
```bash
# ZK + JNs zuerst
docker compose up -d zk1 zk2 zk3 jn1 jn2 jn3

# start primary namenode -> init script format
docker compose up -d --no-recreate nn1

# start secondary namenode -> init script bootstrap
docker compose up -d --no-recreate nn2

# ONLY if timing issues due to slow laptops
docker exec -it nn1 hdfs haadmin -transitionToActive nn1 --forcemanual

# Datanodes
docker-compose up -d --no-recreate dn1 dn2 dn3 

# Ressource Manager
docker-compose up -d --no-recreate rm 

# Nodemanager runner
docker-compose up -d --no-recreate nm

# restart rm/nm for config changes
docker compose restart rm nm
```

# start after init
```bash
docker compose up -d
```

# web uis
* http://localhost:9870
![active namenode with 3 datanodes](./screenshots/hadoop-namenode.png)
* http://localhost:9871
![passive  namenode with 3 datanodes](./screenshots/hadoop-namenode2.png)
* http://localhost:8088
![ressource manager](./screenshots/hadoop-ressourcemanager.png)
* http://localhost:8042/node/allApplications
![ressource manager](./screenshots/hadoop-nodemanager.png)

# commands
```bash
docker exec -it nn1 hdfs haadmin -getServiceState nn1
docker exec -it nn1 hdfs haadmin -getServiceState nn2
```

# init transfer folder and start transfer
```bash
docker exec nn1 hdfs dfs -ls /

# Create a local file inside the container
docker exec nn1 bash -c 'echo "Hello HDFS" > /tmp/hello.txt'

# Copy it into HDFS
docker exec nn1 hdfs dfs -put /tmp/hello.txt /data/

docker exec nn1 hdfs dfs -ls /

docker exec nn1 hadoop distcp hdfs://oldcluster:8020/data hdfs://ns1/data
```

# run yarn examples
```bash
docker exec rm ls -l /opt/hadoop/share/hadoop/yarn/yarn-service-examples
total 16
drwxr-xr-x 2 1001 1001 4096 Aug 20 11:13 appcatalog
drwxr-xr-x 2 1001 1001 4096 Aug 20 11:13 httpd
drwxr-xr-x 2 1001 1001 4096 Aug 20 11:13 httpd-no-dns
drwxr-xr-x 2 1001 1001 4096 Aug 20 11:13 sleeper

docker exec rm ls -l /opt/hadoop/share/hadoop/mapreduce/
total 5492
-rw-r--r-- 1 1001 1001  592059 Aug 20 10:49 hadoop-mapreduce-client-app-3.4.2.jar
-rw-r--r-- 1 1001 1001  789755 Aug 20 10:49 hadoop-mapreduce-client-common-3.4.2.jar
-rw-r--r-- 1 1001 1001 1843760 Aug 20 10:49 hadoop-mapreduce-client-core-3.4.2.jar
-rw-r--r-- 1 1001 1001  183362 Aug 20 10:49 hadoop-mapreduce-client-hs-3.4.2.jar
-rw-r--r-- 1 1001 1001   10413 Aug 20 10:49 hadoop-mapreduce-client-hs-plugins-3.4.2.jar
-rw-r--r-- 1 1001 1001 1663667 Aug 20 10:49 hadoop-mapreduce-client-jobclient-3.4.2-tests.jar
-rw-r--r-- 1 1001 1001   50253 Aug 20 10:49 hadoop-mapreduce-client-jobclient-3.4.2.jar
-rw-r--r-- 1 1001 1001   90946 Aug 20 10:49 hadoop-mapreduce-client-nativetask-3.4.2.jar
-rw-r--r-- 1 1001 1001   63404 Aug 20 10:49 hadoop-mapreduce-client-shuffle-3.4.2.jar
-rw-r--r-- 1 1001 1001   22851 Aug 20 10:49 hadoop-mapreduce-client-uploader-3.4.2.jar
-rw-r--r-- 1 1001 1001  281633 Aug 20 10:49 hadoop-mapreduce-examples-3.4.2.jar
```

# word count beispiel
```bash
# Datei in HDFS anlegen
docker exec nn1 bash -c 'echo "Hello Hadoop Hello YARN" > /tmp/input.txt'
docker exec nn1 hdfs dfs -mkdir -p /input
docker exec nn1 hdfs dfs -put /tmp/input.txt /input/

# WordCount starten
docker exec rm hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.2.jar wordcount /input /output
2025-12-14 08:59:25,614 INFO  org.apache.hadoop.yarn.client.DefaultNoHARMFailoverProxyProvider: Connecting to ResourceManager at rm/172.19.0.10:8032
2025-12-14 08:59:26,256 INFO  org.apache.hadoop.mapreduce.JobResourceUploader: Disabling Erasure Coding for path: /tmp/hadoop-yarn/staging/root/.staging/job_1765702733708_0001
2025-12-14 08:59:26,677 INFO  org.apache.hadoop.mapreduce.lib.input.FileInputFormat: Total input files to process : 1
2025-12-14 08:59:26,821 INFO  org.apache.hadoop.mapreduce.JobSubmitter: number of splits:1
2025-12-14 08:59:27,103 INFO  org.apache.hadoop.mapreduce.JobSubmitter: Submitting tokens for job: job_1765702733708_0001
2025-12-14 08:59:27,103 INFO  org.apache.hadoop.mapreduce.JobSubmitter: Executing with tokens: []
2025-12-14 08:59:27,346 INFO  org.apache.hadoop.conf.Configuration: resource-types.xml not found
2025-12-14 08:59:27,347 INFO  org.apache.hadoop.yarn.util.resource.ResourceUtils: Unable to find 'resource-types.xml'.
2025-12-14 08:59:27,873 INFO  org.apache.hadoop.yarn.client.api.impl.YarnClientImpl: Submitted application application_1765702733708_0001
2025-12-14 08:59:27,957 INFO  org.apache.hadoop.mapreduce.Job: The url to track the job: http://rm:8088/proxy/application_1765702733708_0001/
2025-12-14 08:59:27,958 INFO  org.apache.hadoop.mapreduce.Job: Running job: job_1765702733708_0001
2025-12-14 08:59:37,307 INFO  org.apache.hadoop.mapreduce.Job: Job job_1765702733708_0001 running in uber mode : true
2025-12-14 08:59:37,309 INFO  org.apache.hadoop.mapreduce.Job:  map 100% reduce 0%
2025-12-14 08:59:39,400 INFO  org.apache.hadoop.mapreduce.Job:  map 100% reduce 100%
2025-12-14 08:59:39,422 INFO  org.apache.hadoop.mapreduce.Job: Job job_1765702733708_0001 completed successfully
2025-12-14 08:59:39,587 INFO  org.apache.hadoop.mapreduce.Job: Counters: 57
        File System Counters
                FILE: Number of bytes read=116
                FILE: Number of bytes written=190
                FILE: Number of read operations=0
                FILE: Number of large read operations=0
                FILE: Number of write operations=0
                HDFS: Number of bytes read=272
                HDFS: Number of bytes written=639035
                HDFS: Number of read operations=37
                HDFS: Number of large read operations=0
                HDFS: Number of write operations=8
                HDFS: Number of bytes read erasure-coded=0
        Job Counters 
                Launched map tasks=1
                Launched reduce tasks=1
                Other local map tasks=1
                Total time spent by all maps in occupied slots (ms)=0
                Total time spent by all reduces in occupied slots (ms)=0
                TOTAL_LAUNCHED_UBERTASKS=2
                NUM_UBER_SUBMAPS=1
                NUM_UBER_SUBREDUCES=1
                Total time spent by all map tasks (ms)=280
                Total time spent by all reduce tasks (ms)=1219
                Total vcore-milliseconds taken by all map tasks=0
                Total vcore-milliseconds taken by all reduce tasks=0
                Total megabyte-milliseconds taken by all map tasks=0
                Total megabyte-milliseconds taken by all reduce tasks=0
        Map-Reduce Framework
                Map input records=1
                Map output records=4
                Map output bytes=40
                Map output materialized bytes=42
                Input split bytes=91
                Combine input records=4
                Combine output records=3
                Reduce input groups=3
                Reduce shuffle bytes=42
                Reduce input records=3
                Reduce output records=3
                Spilled Records=6
                Shuffled Maps =1
                Failed Shuffles=0
                Merged Map outputs=1
                GC time elapsed (ms)=28
                CPU time spent (ms)=1320
                Physical memory (bytes) snapshot=801300480
                Virtual memory (bytes) snapshot=6182551552
                Total committed heap usage (bytes)=461373440
                Peak Map Physical memory (bytes)=393637888
                Peak Map Virtual memory (bytes)=3087605760
                Peak Reduce Physical memory (bytes)=407662592
                Peak Reduce Virtual memory (bytes)=3094945792
        Shuffle Errors
                BAD_ID=0
                CONNECTION=0
                IO_ERROR=0
                WRONG_LENGTH=0
                WRONG_MAP=0
                WRONG_REDUCE=0
        File Input Format Counters 
                Bytes Read=24
        File Output Format Counters 
                Bytes Written=24

# Ergebnis ansehen
docker exec nn1 hdfs dfs -cat /output/part-r-00000
Hadoop  1
Hello   2
YARN    1
```

# delete
```bash 
docker compose down -v 
```
