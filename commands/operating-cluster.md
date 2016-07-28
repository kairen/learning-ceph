# Operating a Cluster


### Delete OSD
#### STOPPING THE OSD
```sh
ssh {osd-host}
sudo stop ceph-osd-all
```

#### REMOVING THE OSD
```sh
ceph osd out {id}
ceph osd down {id}
ceph osd crush remove {osd.id}
ceph auth del {osd.id}

ceph osd rm {id}
```