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
        ssh -t $target "set -eux;scp -o StrictHostKeyChecking=no ${self}:${this_script} /tmp/setup.sh;env ceph_user=${ceph_user} /tmp/setup.sh client ${self};rm /tmp/setup.sh;echo DONE"
        ;;
    client)
        echo 'eth0: \4{eth0}' | sudo tee -a /etc/issue
        sudo sh -ceux 'dd if=/dev/zero of=/swapfile bs=1024 count=524288;chmod 600 /swapfile;mkswap /swapfile;
            echo "/swapfile none    swap    sw      0       0" >>/etc/fstab'
        sudo useradd --system -d /home/$ceph_user -m $ceph_user
        echo "$ceph_user ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$ceph_user
        sudo chmod 0440 /etc/sudoers.d/$ceph_user
        sudo cp -av ~/.ssh /home/$ceph_user/
        sudo chown -R $ceph_user /home/$ceph_user
        ;;
    *)
        echo "Unknown $mode" >&2
        exit 1
esac