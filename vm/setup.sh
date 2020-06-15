#!/bin/sh
set -eux
this_script=$(readlink -f $0)
mode=$1;shift
target=$1;shift
case "$mode" in
    server)
        self=$(id -un)@$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)
        #scp -p ~/.ssh/id_rsa.pub ${target}:~/.ssh/authorized_keys
        ssh-copy-id ${target}
        #scp -p ~/.ssh/id_rsa  ~/.ssh/id_rsa.pub ${target}:~/.ssh
        ssh -t $target "set -eux;scp -o StrictHostKeyChecking=no ${self}:${this_script} /tmp/setup.sh;/tmp/setup.sh client ${self};rm /tmp/setup.sh"
        ;;
    client)
        #scp ${target}:.ssh/id_rsa ~/.ssh
        #scp ${target}:.ssh/id_rsa.pub ~/.ssh
        #cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
        sudo sh -ceux 'echo "eth0: \4{eth0}" >>/etc/issue'
        sudo sh -ceux 'dd if=/dev/zero of=/swapfile bs=1024 count=524288;chmod 600 /swapfile;mkswap /swapfile;
            echo "/swapfile none    swap    sw      0       0" >>/etc/fstab'
        ;;
    *)
        echo "Unknown $mode" >&2
        exit 1
esac

