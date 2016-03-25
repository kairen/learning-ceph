# Benchmark Ceph Cluster Performance

### Benchmark your disks
The simplest way to benchmark your disk is with dd. Use the following command to read and write a file, remembering to add the oflag parameter to bypass the disk page cache:
```sh
dd if=/dev/zero of=here bs=1G count=1 oflag=direct
```

### Benchmark your network
Using ```iperf``` to bench network. You can install ```iperf``` using below command：
```sh
sudo apt-get install iperf -y
```

iperf needs to be installed on at least two nodes in your cluster. Then, on one of the nodes, start the iperf server using the following command:
```sh
iperf -s
```

On another node, start the client with the following command, remembering to use the IP address of the node hosting the iperf server:
```sh
iperf -c <server>
```
> NOTE: Before running any of the benchmarks in subsequent sections, drop all caches using a command like this:
> 
``` 
echo 3 | sudo tee /proc/sys/vm/drop_caches && sudo sync
```

### Benchmark a ceph storage pool
Ceph includes the rados bench command, designed specifically to benchmark a RADOS storage cluster. To use it, create a storage pool and then use rados bench to perform a write benchmark, as shown below.The rados command is included with Ceph.
Create benchmark pool：
```sh
ceph osd pool create scbench 100 100
```
Run rados write benchmark：
```sh
rados bench -p scbench 10 write --no-cleanup
```
Run rados random reads benchmark：
```sh
 rados bench -p scbench 10 seq
```
Run rados sequential reads benchmark：
```sh
 rados bench -p scbench 10 rand
```
> if you want clean pool,you can using 
```
rados -p scbench cleanup
```

### Benchmark a ceph block device
Before using either of these two tools, though, create a block device using the commands below,first create pool：
```sh
 ceph osd pool create rbd 128 128
```
Creating block device image：
```sh
rbd create bench-image --size 1024 --pool rbd
```
Mapping block device image：
```sh
rbd map bench-image --pool rbd --name client.admin
```
Partition block device：
```sh
sudo mkfs.ext4 -m0 /dev/rbd1
```
Creating directory to mount block device：
```sh
sudo mkdir -p /mnt/ceph-block-device
```
Mounting block device：
```sh
sudo mount /dev/rbd1 /mnt/ceph-block-device
```
#### Using rbd benchmark
The rbd bench-write command generates a series of sequential writes to the image and measure the write throughput and latency. Here's an example:
```sh
rbd bench-write bench-image --pool=rbd
```

#### Using fio benchmark 
You can use fio to benchmark your block device. An example rbd.fio template is included with the fio source code, which performs a 4K random write test against a RADOS block device via librbd. Note that you will need to update the template with the correct names for your pool and device, as shown below.First create fio configuration file：
```sh
[global]
ioengine=rbd
clientname=admin
pool=rbd
rbdname=ssd-image
rw=randwrite
bs=4k

[rbd_iodepth32]
iodepth=32

#[seq-write]
#stonewall
#rw=write

#[seq-read]
#stonewall
#rw=read
```
Then, run fio as follows:
```sh
fio <filename.fio>
```
> latest version：
```
$ sudo apt-get install librbd-dev zlib1g-dev libaio1 libaio-dev
$ git clone git://git.kernel.dk/fio.git
$ ./configure
$ make && sudo make install
```

### Benchmark a ceph object gateway
When it comes to benchmarking the Ceph object gateway, look no further than swift-bench, the benchmarking tool included with OpenStack Swift. The swift-bench tool tests the performance of your Ceph cluster by simulating client PUT and GET requests and measuring their performance.

You can install ```swift-bench``` using ```pip install swift``` && ```pip install swift-bench```.

To use swift-bench, you need to first create a gateway user and subuser, as shown below:
```sh
sudo radosgw-admin user create --uid="benchmark" --display-name="benchmark" 
```
Create subuser ：
```sh
sudo radosgw-admin subuser create --uid=benchmark --subuser=benchmark:swift
--access=full
```
Create key：
```sh
sudo radosgw-admin key create --subuser=benchmark:swift --key-type=swift
--secret=guessme
```
Modify user：
```sh
radosgw-admin user modify --uid=benchmark --max-buckets=0
```
Next, create a configuration file for swift-bench on a client host：
```sh
[bench]
auth = http://gateway-node/auth/v1.0
user = benchmark:swift
key = guessme
auth_version = 1.0
```

You can now run a benchmark as below. Use the -c parameter to adjust the number of concurrent connections (this example uses 64) and the -s parameter to adjust the size of the object being written (this example uses 4K objects). The -n and -g parameters control the number of objects to PUT and GET respectively.
```sh
swift-bench -c 64 -s 4096 -n 1000 -g 100 /tmp/swift.conf
```

### OSD Benchmark
You can use ```tell``` command to benchmark osd,Follow below：
```sh
time ceph tell osd.5 bench
```

### Cosbench Object stroage

### Ceph Benchmarking Tool