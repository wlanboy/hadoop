FROM ubuntu:22.04

ARG HADOOP_VERSION=3.4.2
ENV DEBIAN_FRONTEND=noninteractive
ENV HADOOP_HOME=/opt/hadoop
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$JAVA_HOME/bin:$PATH

# OS + Java 11 + utilities
RUN apt-get update && apt-get install -y \
    curl tar gzip openjdk-11-jdk procps netcat ca-certificates bash \
 && rm -rf /var/lib/apt/lists/*

# Hadoop
RUN curl -fsSL https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    -o /tmp/hadoop.tar.gz \
 && mkdir -p /opt \
 && tar -xzf /tmp/hadoop.tar.gz -C /opt \
 && mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
 && rm /tmp/hadoop.tar.gz

# Data dirs
RUN mkdir -p /data/hdfs/namenode /data/hdfs/datanode /data/hdfs/journal /var/log/hadoop

# Minimal SSH-less environment for Hadoop daemons
RUN sed -i 's@# export JAVA_HOME=.*@export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64@' $HADOOP_HOME/etc/hadoop/hadoop-env.sh \
 && echo "export HADOOP_LOG_DIR=/var/log/hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# Entry
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR $HADOOP_HOME
CMD ["/usr/local/bin/entrypoint.sh"]
