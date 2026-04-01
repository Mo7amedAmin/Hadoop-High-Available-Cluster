FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    openssh-client \
    openssh-server \
    rsync \
    wget \
    nano \
    sudo \
    curl

RUN mv /usr/lib/jvm/java-11-openjdk-amd64 /usr/lib/jvm/java

ENV JAVA_HOME=/usr/lib/jvm/java
ENV PATH=$JAVA_HOME/bin:$PATH




# RUN groupadd hadoop \
#    && useradd -m -g hadoop hduser \
#    && echo "hduser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# USER hduser



RUN mkdir -p /root/.ssh \
    && ssh-keygen -t rsa -f "/root/.ssh/id_rsa" -N "" \
    && cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys \
    && chmod 700 /root/.ssh \
    && chmod 600 /root/.ssh/authorized_keys



WORKDIR /opt
RUN wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz \
    && tar -xzvf hadoop-3.3.6.tar.gz \
    && mv hadoop-3.3.6 hadoop \
#    && chown -R hduser:hadoop /opt/hadoop \
    && chmod -R 755 /opt/hadoop


ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
ENV HADOOP_MAPRED_HOME=/opt/hadoop
ENV HADOOP_COMMON_HOME=/opt/hadoop
ENV HADOOP_HDFS_HOME=/opt/hadoop
ENV YARN_HOME=/opt/hadoop
ENV PATH=$PATH:/opt/hadoop/bin
ENV PATH=$PATH:/opt/hadoop/sbin
 
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
ENV HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib"


RUN wget https://downloads.apache.org/zookeeper/zookeeper-3.8.6/apache-zookeeper-3.8.6-bin.tar.gz \
    && tar -xzvf apache-zookeeper-3.8.6-bin.tar.gz \
    && mv apache-zookeeper-3.8.6-bin zookeeper


ENV ZOOKEEPER_HOME=/opt/zookeeper
ENV PATH=$PATH:$ZOOKEEPER_HOME/bin



RUN mkdir -p /opt/hadoop/yarn_data/hdfs/namenode \
    && mkdir -p /opt/hadoop/yarn_data/hdfs/datanode \
    && mkdir -p /app/hadoop/tmp \
    && chmod -R 777 /app/hadoop/tmp \
    && chmod -R 777 /opt/hadoop/yarn_data

# COPY hadoop_config /opt/hadoop/etc/hadoop

CMD service ssh start && tail -f /dev/null
