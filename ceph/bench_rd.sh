#!/bin/sh
set -eux
dev=$1;shift
smartctl -a $dev || true
fio --eta=always --filename=$dev --direct=1 --rw=randread --bs=4k --ioengine=libaio --iodepth=64 --runtime=20 --numjobs=4 --time_based --group_reporting --name=iops-test-job --eta-newline=1 --readonly

fio --eta=always --filename=$dev --direct=1 --rw=randread --bs=4k --ioengine=libaio --iodepth=1 --numjobs=1 --time_based --group_reporting --name=readlatency-test-job --runtime=20 --eta-newline=1 --readonly

fio --eta=always --filename=$dev --direct=1 --rw=read --bs=1m --ioengine=libaio --iodepth=64 --runtime=20 --numjobs=1 --time_based --group_reporting --name=throughput-test-job --eta-newline=1 --readonly
