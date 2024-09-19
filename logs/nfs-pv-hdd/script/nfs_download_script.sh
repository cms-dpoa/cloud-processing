#!/bin/bash
kubectl cp nfs-server-7c569b7755-v2kqb:/tmp/200.txt ./200.txt | pv
kubectl cp nfs-server-7c569b7755-v2kqb:/tmp/300.txt ./300.txt | pv
kubectl cp nfs-server-7c569b7755-v2kqb:/tmp/512.txt ./512.txt | pv
kubectl cp nfs-server-7c569b7755-v2kqb:/tmp/700.txt ./700.txt | pv
kubectl cp nfs-server-7c569b7755-v2kqb:/tmp/1GB.zip ./1GB.zip | pv
kubectl cp nfs-server-7c569b7755-v2kqb:/tmp/2GB.zip ./2GB.zip | pv
kubectl cp nfs-server-7c569b7755-v2kqb:/tmp/3GB.zip ./3GB.zip | pv
#kubectl cp nfs-server-7c569b7755-v2kqb:/tmp/10GB.zip ./10GB.zip | pv

