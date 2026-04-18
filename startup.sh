#!/bin/bash

echo "Starting services for Hadoop Cluster on $(hostname)"

# Start SSH
echo "Starting SSH..."
service ssh start

# Wait until DNS is ready
for host in node01 node02 node03 node04 node05; do 
    until getent hosts $host &>/dev/null; do 
        echo "waiting for $host..."
        sleep 2
    done
done

# Create zoo.cfg config
mkdir -p /opt/zookeeper/conf

echo "tickTime=2000" > /opt/zookeeper/conf/zoo.cfg
echo "dataDir=/opt/zookeeper/data" >> /opt/zookeeper/conf/zoo.cfg
echo "clientPort=2181" >> /opt/zookeeper/conf/zoo.cfg
echo "initLimit=5" >> /opt/zookeeper/conf/zoo.cfg
echo "syncLimit=2" >> /opt/zookeeper/conf/zoo.cfg
echo "server.1=node01:2888:3888" >> /opt/zookeeper/conf/zoo.cfg
echo "server.2=node02:2888:3888" >> /opt/zookeeper/conf/zoo.cfg
echo "server.3=node03:2888:3888" >> /opt/zookeeper/conf/zoo.cfg
echo "4lw.commands.whitelist=ruok" >> /opt/zookeeper/conf/zoo.cfg

# Config myid files for zookeeper
mkdir -p /opt/zookeeper/data

case "$HOSTNAME" in
    node01) echo "1" > /opt/zookeeper/data/myid ;;
    node02) echo "2" > /opt/zookeeper/data/myid ;;
    node03) echo "3" > /opt/zookeeper/data/myid ;;
esac

# Start Zookeeper
case "$HOSTNAME" in
    node01|node02|node03)
        echo "Starting ZooKeeper on $HOSTNAME"
        /opt/zookeeper/bin/zkServer.sh start
        ;;
esac

# Check Zookeeper Nodes are ready
for host in node01 node02 node03; do
    until echo ruok | nc $host 2181 2>/dev/null | grep imok &>/dev/null; do
        echo "Waiting for Zookeeper on $host..."
        sleep 2
    done
    echo "Zookeeper is ready on $host"
done



# Start Journalnodes
case "$HOSTNAME" in
    node02|node04|node05) 
        echo "Starting JournalNode on $HOSTNAME"
        hdfs --daemon start journalnode
        ;;
esac

# Check JournalNodes are ready
for host in node02 node04 node05; do
    until nc -z $host 8485 &>/dev/null; do
        echo "Waiting for JournalNode on host $host..."
        sleep 2
    done
    echo "JournalNode is ready on $host"
done



# Format and start NameNode and format zookeeper
if [[ "$HOSTNAME" == node01 ]]; then
    # Format NameNode once
    if [[ -f /opt/hadoop/yarn_data/hdfs/namenode/current/VERSION ]]; then
        echo "NameNode is already formatted"
    else
        echo "format namenode on $HOSTNAME..."
        hdfs namenode -format
    fi

    # Initalize shared edits 
    if [[ -f /opt/hadoop/yarn_data/hdfs/namenode/.shared_edit_initialized ]]; then
        echo "Shared edits is already initialized"
    else
        echo "Initalizing shared edits..."
        hdfs namenode -initializeSharedEdits -force
        touch /opt/hadoop/yarn_data/hdfs/namenode/.shared_edit_initialized
    fi

    # Starting Active NameNode
    echo "Starting active NameNode on $HOSTNAME..."
    hdfs --daemon start namenode

    # Formatting Zookeeper
    if zkCli.sh -server node01:2181 ls /hadoop-ha/mycluster &>/dev/null; then
        echo "ZK already initialized"
    else
        echo "Formatting Zookeeper on $HOSTNAME..."
        hdfs zkfc -formatZK
    fi

    # Start ZKFC (active)
    echo "Starting ZKFC for active NN on $HOSTNAME..."
    hdfs --daemon start zkfc
fi



if [[ "$HOSTNAME" == node02 ]]; then
    # Check active namenode
    until hdfs haadmin -getServiceState nn1 | grep active &>/dev/null; do
        echo "Waiting for active NameNode..."
        sleep 2
    done

    # Bootstrap Standby
    if [[ ! -d /opt/hadoop/yarn_data/hdfs/namenode/current ]]; then
        echo "Bootstrap Standby..."
        hdfs namenode -bootstrapStandby
    fi

    # Start standby NameNode
    echo "Starting standby NameNode"
    hdfs --daemon start namenode

    # Start ZKFC (standby)
    echo "Starting ZKFC for standby NN on $HOSTNAME..."
    hdfs --daemon start zkfc
fi


# Start DataNodes
case "$HOSTNAME" in
    node03|node04|node05)
        echo "Starting datanode on $HOSTNAME..."
        hdfs --daemon start datanode
        ;;
esac

# Start ResourceManager 
case "$HOSTNAME" in
    node01|node02)
        echo "Starting ResourceManager on $HOSTNAME..."
        yarn --daemon start resourcemanager
        ;;
esac

# Start NodeManagers
case "$HOSTNAME" in
    node03|node04|node05)
        echo "Starting NodeManager on $HOSTNAME..."
        yarn --daemon start nodemanager
        ;;
esac

echo "All services are ready on $HOSTNAME"

# Gracefully stop all Hadoop services on container shutdown
trap "
echo 'Stopping services...'
hdfs --daemon stop namenode 2>/dev/null
yarn --daemon stop resourcemanager 2>/dev/null
sleep 5
" SIGTERM

# Keep container running indefinitely
tail -f /dev/null 