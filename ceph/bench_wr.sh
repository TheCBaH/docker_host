#!/bin/sh
set -eux
dev=$1;shift
fio --eta=always --filename=$dev --direct=1 --rw=write --bs=1m --ioengine=libaio --iodepth=16 --runtime=20 --numjobs=1 --time_based --group_reporting --name=throughpu-write-job --eta-newline=1

fio --eta=always --filename=$dev --atomic=1 --direct=1 --rw=randwrite --bs=4k --ioengine=libaio --iodepth=1 --numjobs=1 --time_based --group_reporting --name=wrlatency-test-job --runtime=20 --eta-newline=1

fio --eta=always --filename=$dev --direct=1 --rw=randrw --bs=4k --ioengine=libaio --iodepth=256 --runtime=20 --numjobs=4 --time_based --group_reporting --name=iops-test-job --eta-newline=1

fio --eta=always --filename=$dev --direct=1 --rw=randrw --bs=4k --ioengine=libaio --iodepth=1 --numjobs=1 --time_based --group_reporting --name=rwlatency-test-job --runtime=20 --eta-newline=1
