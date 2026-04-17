# 🐘 Hadoop High Availability (HA) Cluster Architecture

This project demonstrates a **High Availability Hadoop Cluster** using:

* HDFS HA (Active / Standby NameNode)
* ZooKeeper Ensemble (Failover coordination)
* JournalNodes Quorum (Shared edits)
* Distributed Worker Nodes

---

## 📊 Architecture Diagram

![Hadoop HA Architecture](/docs/images/HA_Diagram.svg)

---

## 🧠 Architecture Overview

The cluster is designed to ensure:

* No single point of failure
* Automatic failover
* Consistent metadata replication

---

## 🔷 Core Components

### 1. NameNode (HA Setup)

* **Active NameNode**

  * Handles all client requests
  * Writes edit logs

* **Standby NameNode**

  * Continuously syncs with Active
  * Takes over automatically on failure

---

### 2. ZooKeeper Ensemble

* Runs on:

  * node01, node02, node03

* Responsibilities:

  * Leader election
  * Failover coordination
  * Ensuring only one Active NameNode

---

### 3. ZKFC (ZooKeeper Failover Controller)

* Runs on both NameNodes
* Communicates with ZooKeeper
* Handles:

  * Health checks
  * Automatic failover

---

### 4. JournalNodes Quorum

* Runs on:

  * node02, node04, node05

* Responsibilities:

  * Store **edit logs**
  * Maintain consistency using quorum (majority)

---

## 🔁 Edit Log Flow

### Write Path (Active NameNode)

1. Active NameNode writes edit logs
2. Logs are sent to all JournalNodes
3. Operation is successful when **majority (2/3)** acknowledges

---

### Read Path (Standby NameNode)

1. Standby reads edit logs from JournalNodes
2. Applies transactions in order
3. Maintains up-to-date state

---

## 🔄 Failover Process

1. Active NameNode fails
2. ZKFC detects failure
3. ZooKeeper elects a new Active
4. Standby NameNode becomes Active
5. Cluster continues without interruption

---

## 🗂️ Cluster Layout

| Node   | Components                                                      |
| ------ | --------------------------------------------------------------- |
| node01 | Active NameNode, ResourceManager, ZKFC, ZooKeeper               |
| node02 | Standby NameNode, ResourceManager, ZKFC, JournalNode, ZooKeeper |
| node03 | DataNode, NodeManager, ZooKeeper                                |
| node04 | DataNode, NodeManager, JournalNode                              |
| node05 | DataNode, NodeManager, JournalNode                              |

---

## ⚙️ Initialization Flow (Simplified)

* Start ZooKeeper Ensemble
* Start JournalNodes
* Format NameNode
* Initialize shared edits:

```bash
hdfs namenode -initializeSharedEdits
```

* Bootstrap Standby:

```bash
hdfs namenode -bootstrapStandby
```

* Start NameNodes + ZKFC

---

## 🎯 Key Concepts

* **High Availability (HA)**
* **Quorum-based consistency**
* **Leader election using ZooKeeper**
* **Separation of metadata and storage**

---

## 📌 Notes

* This is a **pseudo-distributed cluster**
* Some services are co-located for simplicity
* Architecture reflects real production design principles

---

## 🧠 Summary

> The Active NameNode writes metadata changes to a quorum of JournalNodes, while the Standby continuously syncs from them. ZooKeeper ensures safe failover by electing exactly one active node at any time.

---

## ⭐ Support

If this helped you understand Hadoop HA, consider giving the repo a ⭐
