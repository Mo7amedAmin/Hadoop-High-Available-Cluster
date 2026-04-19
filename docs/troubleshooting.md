# 🛠️ Troubleshooting & Challenges

This section highlights the main issues faced while building the Hadoop HA cluster and how they were resolved.

---
## 1. Hadoop configs management

**Issue:**
Managing Hadoop configuration across containers was difficult.

**Fix:**
Used **bind mounting** to share config files:
```bash
./shared/conf/hadoop:/opt/hadoop/etc/hadoop
```

---

## 2. Containers exiting immediately

**Issue:**
Containers stopped right after `docker compose up`.

**Fix:**
Kept container running using:
```bash
tail -f /dev/null
```
---

## 3. Service readiness problems

**Issue:**
Services were starting before dependencies were ready.

**Fix:**
Used different readiness checks depending on the service:

For ZooKeeper:
```bash
until echo ruok | nc host 2181 2>/dev/null | grep imok &>/dev/null; do
  sleep 2
done
```

For JournalNodes:
```bash
until nc -z host port &>/dev/null; do
  sleep 2
done
```

For NameNode:
```bash
until hdfs haadmin -getServiceState nn1 | grep active &>/dev/null; do
  sleep 2
done
```

---



## 4. Rebuild crashes

**Issue:**
Rebuilding containers caused crashes due to repeated initialization steps.

**Fix:**
Added checks before each step to avoid re-running initialization:

For NameNode format:
```bash
if [[ -f /opt/hadoop/yarn_data/hdfs/namenode/current/VERSION ]]; then
  echo "NameNode already formatted"
else
  hdfs namenode -format
fi
```

For shared edits:
```bash
if [[ ! -f /opt/hadoop/yarn_data/hdfs/namenode/.shared_edit_initialized ]]; then
  hdfs namenode -initializeSharedEdits -force
  touch /opt/hadoop/yarn_data/hdfs/namenode/.shared_edit_initialized
fi
```

For Standby bootstrap:
```bash
if [[ ! -d /opt/hadoop/yarn_data/hdfs/namenode/current ]]; then
  hdfs namenode -bootstrapStandby
fi
```

For ZooKeeper format:
```bash
if ! zkCli.sh -server node01:2181 ls /hadoop-ha/mycluster &>/dev/null; then
  hdfs zkfc -formatZK
fi
```

---

## 5. Shared edits initialization re-running

**Issue:**
`initializeSharedEdits` was being executed multiple times after restarting containers, causing crashes.

**Cause:**
The check was based on a file that was not persisted. When containers restarted, the file was lost, so the system assumed initialization hadn’t been done and tried to run it again.

**Fix:**
Added a persistent check file stored in mounted storage:

```bash
if [[ ! -f /opt/hadoop/yarn_data/hdfs/namenode/.shared_edit_initialized ]]; then
  hdfs namenode -initializeSharedEdits -force
  touch /opt/hadoop/yarn_data/hdfs/namenode/.shared_edit_initialized
fi
```

This ensures initialization runs only once and survives container restarts.

---

## 6. ZooKeeper `myid` issue (WSL)

**Issue:**
ZooKeeper couldn't read `myid` file properly on WSL.

**Fix:**
Created `myid` dynamically inside the container:
```bash
echo "1" > /opt/zookeeper/data/myid
```

---

## 7. Failover failing with SSH fencing

**Issue:**
Failover was not completing when testing by stopping the NameNode manually.

**Cause:**
SSH-based fencing was failing. When the NameNode was already down, the fencing command returned a non-zero exit code, so Hadoop blocked the failover.

**Fix:**
Used a shell-based fencing method during testing:

```bash
<value>shell(/bin/true)</value>
```

This ensured the fencing step always returned success, allowing failover to proceed.

---

## 8. Failover not triggering

**Issue:**
Failover didn't happen when running:
```bash
docker stop node01
```

**Cause:**
The container stopped immediately, so:
- NameNode didn’t shut down gracefully
- ZKFC didn’t detect failure properly

**Fix:**
Used `trap` to gracefully stop services:
```bash
trap "
hdfs --daemon stop namenode
yarn --daemon stop resourcemanager
" SIGTERM
```

---

## 9. ZooKeeper `ruok` not working

**Issue:**
ZooKeeper was not responding to:
```
echo ruok | nc host 2181
```

**Cause:**
4-letter commands are disabled by default.

**Fix:**
Enabled it in `zoo.cfg`:
```bash
4lw.commands.whitelist=ruok
```
---