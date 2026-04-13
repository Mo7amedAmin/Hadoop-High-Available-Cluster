# 🚀 Hadoop High Availability (HA) Cluster | Docker-Based Big Data System

![Hadoop](https://img.shields.io/badge/Hadoop-3.3.x-orange) ![Docker](https://img.shields.io/badge/Docker-Containerized-blue) ![Zookeeper](https://img.shields.io/badge/Zookeeper-Coordination-green) ![HA](https://img.shields.io/badge/High%20Availability-Failover-red) ![Status](https://img.shields.io/badge/Status-Production--Simulated-success)

This project implements a **production-like Hadoop High Availability cluster** using Docker to simulate real distributed systems architecture with automatic failover, fault tolerance, and coordination mechanisms.

ARCHITECTURE OVERVIEW:
                    Zookeeper Ensemble
        ------------------------------------------------
        node01        node02        node03
            \            |            /
             \           |           /
              ---- Leader Election & Coordination ----
                              |
        ------------------------------------------------
        Active NameNode (node01)   Standby NameNode (node02)
                              |
                ---- JournalNodes (QJM Layer) ----
                  node02      node04      node05
                              |
                DataNodes + NodeManagers Layer
                node03      node04      node05

CORE FEATURES:
- High Availability HDFS with Active/Standby NameNode
- Automatic Failover using ZKFC (ZooKeeper Failover Controller)
- Zookeeper-based coordination and leader election
- Quorum JournalNodes (QJM) for shared edits and metadata sync
- YARN ResourceManager and NodeManagers for distributed compute
- Fully containerized multi-node Hadoop cluster using Docker
- No single point of failure architecture

HOW HIGH AVAILABILITY WORKS:
Zookeeper continuously monitors the cluster state and manages leader election. ZKFC runs on both NameNodes and checks health. If the Active NameNode fails, Zookeeper triggers failover and promotes the Standby NameNode to Active. JournalNodes ensure both NameNodes share consistent metadata so failover is seamless with no data loss.

DEPLOYMENT:
docker build -t hadoop-ha .
docker compose up -d

INITIAL SETUP (RUN ONLY ONCE):
On node01:
hdfs namenode -format
hdfs namenode -initializeSharedEdits
hdfs zkfc -formatZK

On node02:
hdfs namenode -bootstrapStandby

SERVICES DISTRIBUTION:
node01: Active NameNode, ZKFC, ResourceManager, Zookeeper
node02: Standby NameNode, ZKFC, ResourceManager, JournalNode
node03: DataNode, NodeManager, Zookeeper
node04: DataNode, NodeManager, JournalNode
node05: DataNode, NodeManager, JournalNode

FAILOVER TESTING:
Check status:
hdfs haadmin -getServiceState nn1
hdfs haadmin -getServiceState nn2

Create test data:
hdfs dfs -mkdir /test
hdfs dfs -touchz /test/file1

Simulate failure:
docker stop node01

Verify failover:
hdfs haadmin -getServiceState nn2
Expected result: active

Verify data consistency:
hdfs dfs -ls /test

KEY CONFIGURATION:
dfs.nameservices=mycluster
dfs.ha.automatic-failover.enabled=true
dfs.ha.fencing.methods=shell(/bin/true)
JournalNodes port=8485
Zookeeper ensemble for coordination and leader election

IMPORTANT NOTES:
initializeSharedEdits must run only once during cluster bootstrap
ZKFC must run on both NameNodes for failover control
Zookeeper ensemble must be stable before starting HDFS
Persistent Docker volumes are required for real HA behavior

CONCEPTS DEMONSTRATED:
Hadoop High Availability architecture
Distributed systems coordination using Zookeeper
Quorum Journal Manager (QJM)
Automatic failover and leader election
Fault tolerance and system resilience
Containerized Big Data infrastructure

FUTURE IMPROVEMENTS:
Prometheus + Grafana monitoring integration
Kafka streaming layer for real-time ingestion
Airflow orchestration for pipeline automation
Kubernetes migration for orchestration
Chaos engineering for resilience testing

AUTHOR:
This project is a Big Data Engineering / Distributed Systems implementation simulating a real production-grade Hadoop ecosystem with High Availability, automatic failover, and distributed coordination.