# 🚀 Hadoop High Availability (HA) Cluster | Docker-Based Big Data System

![Hadoop](https://img.shields.io/badge/Hadoop-3.3.x-orange)  
![Docker](https://img.shields.io/badge/Docker-Containerized-blue)  
![Zookeeper](https://img.shields.io/badge/Zookeeper-Coordination-green)  
![HA](https://img.shields.io/badge/High%20Availability-Failover-red)  
![Status](https://img.shields.io/badge/Status-Production--Simulated-success)

## 📌 Overview

This project simulates a **production-grade Hadoop High Availability (HA) cluster** using Docker.

It demonstrates:
- Fault tolerance  
- Automatic failover  
- Data consistency  
- Coordination using ZooKeeper  

---

## 🏗️ Architecture Overview

```
ZooKeeper Ensemble
-----------------------------------------
node01        node02        node03
    \            |            /
     \           |           /
  Leader Election & Coordination
                  |
-----------------------------------------
Active NN (node01)   Standby NN (node02)
                  |
---- JournalNodes (QJM Layer) ----
  node02      node04      node05
                  |
DataNodes + NodeManagers Layer
  node03      node04      node05
```

---

## ⚙️ Core Features

- HDFS High Availability (Active/Standby NameNode)
- Automatic Failover using ZKFC
- ZooKeeper-based coordination
- Quorum Journal Manager (QJM)
- YARN distributed processing
- Docker-based multi-node cluster

---

## 🚀 Deployment

```bash
docker build -t hadoop-ha .
docker compose up -d
```

---

## 🧩 Initial Setup

### node01
```bash
hdfs namenode -format
hdfs namenode -initializeSharedEdits
hdfs zkfc -formatZK
```

### node02
```bash
hdfs namenode -bootstrapStandby
```

---

## 🧪 Failover Test

```bash
docker stop node01
```

```bash
hdfs haadmin -getServiceState nn2
```

Expected:
```
active
```

---

## ⚠️ Notes

- Run initializeSharedEdits only once
- ZooKeeper must be ready before HDFS
- Use persistent volumes

---

## 👨‍💻 Author

Hadoop HA cluster project simulating real distributed systems.