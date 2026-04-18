# Use Ubuntu 24.04 as base image
FROM ubuntu:24.04

# Install required dependencies
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    openssh-client \
    openssh-server \
    rsync \
    wget \
    nano \
    sudo \
    curl \
    netcat-openbsd

# Set JAVA_HOME and simplify Java path
RUN mv /usr/lib/jvm/java-11-openjdk-amd64 /usr/lib/jvm/java

ENV JAVA_HOME=/usr/lib/jvm/java
ENV PATH=$JAVA_HOME/bin:$PATH


# Setup SSH for passwordless access
RUN mkdir -p /root/.ssh \
    && ssh-keygen -t rsa -m PEM -b 2048 -f /root/.ssh/id_rsa -N "" \
    && cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys \
    && chmod 700 /root/.ssh \
    && chmod 600 /root/.ssh/authorized_keys


# Download and install Hadoop
WORKDIR /opt
RUN wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz \
    && tar -xzvf hadoop-3.3.6.tar.gz \
    && mv hadoop-3.3.6 hadoop \
    && chmod -R 755 /opt/hadoop

# Set Hadoop environment variables
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
ENV HADOOP_MAPRED_HOME=/opt/hadoop
ENV HADOOP_COMMON_HOME=/opt/hadoop
ENV HADOOP_HDFS_HOME=/opt/hadoop
ENV HADOOP_YARN_HOME=/opt/hadoop
ENV PATH=$PATH:/opt/hadoop/bin
ENV PATH=$PATH:/opt/hadoop/sbin
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
ENV HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib"


# Download and install ZooKeeper
RUN wget https://downloads.apache.org/zookeeper/zookeeper-3.8.6/apache-zookeeper-3.8.6-bin.tar.gz \
    && tar -xzvf apache-zookeeper-3.8.6-bin.tar.gz \
    && mv apache-zookeeper-3.8.6-bin zookeeper

# Set ZooKeeper environment variables
ENV ZOOKEEPER_HOME=/opt/zookeeper
ENV PATH=$PATH:$ZOOKEEPER_HOME/bin


# Create required directories for HDFS and temp storage
RUN mkdir -p /opt/hadoop/yarn_data/hdfs/namenode \
    && mkdir -p /opt/hadoop/yarn_data/hdfs/datanode \
    && mkdir -p /app/hadoop/tmp \
    && chmod -R 777 /app/hadoop/tmp \
    && chmod -R 777 /opt/hadoop/yarn_data


# Copy startup script and make it executable
COPY scripts/start-all.sh /start-all.sh
RUN chmod +x /start-all.sh

# Start all Hadoop services when container runs
ENTRYPOINT ["/start-all.sh"]
