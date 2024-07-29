#!/bin/bash
tar cf - 200.txt | pv | kubectl exec -i nfs-server-7c569b7755-v2kqb -- tar xf - -C /tmp/
tar cf - 300.txt | pv | kubectl exec -i nfs-server-7c569b7755-v2kqb -- tar xf - -C /tmp/
tar cf - 512.txt | pv | kubectl exec -i nfs-server-7c569b7755-v2kqb -- tar xf - -C /tmp/
tar cf - 700.txt | pv | kubectl exec -i nfs-server-7c569b7755-v2kqb -- tar xf - -C /tmp/
tar cf - 1GB.zip | pv | kubectl exec -i nfs-server-7c569b7755-v2kqb -- tar xf - -C /tmp/
tar cf - 2GB.zip | pv | kubectl exec -i nfs-server-7c569b7755-v2kqb -- tar xf - -C /tmp/
tar cf - 3GB.zip | pv | kubectl exec -i nfs-server-7c569b7755-v2kqb -- tar xf - -C /tmp/
#tar cf - 10GB.zip | pv | kubectl exec -i nfs-server-7c569b7755-v2kqb -- tar xf - -C /tmp/



