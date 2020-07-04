#!/bin/sh
set -eux
this_script=$(readlink -f $0)
mode=$1;shift
case "$mode" in
    server)
        target=$1;shift
        ceph_user=$1;shift
        self=$(id -un)@$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)
        ssh-copy-id -i ~/.ssh/ceph_id_rsa ${target}
        scp -i ~/.ssh/ceph_id_rsa ${this_script} ${target}:/tmp/setup.sh
        ssh -i ~/.ssh/ceph_id_rsa -t $target "set -eux;/tmp/setup.sh client ${self} ${ceph_user};rm /tmp/setup.sh;echo DONE"
        ;;
    server.provision)
        target=$1;shift
        ceph_user=$1;shift
        host=$1;shift
        scp -i ~/.ssh/ceph_id_rsa ${this_script} ${ceph_user}@${target}:/tmp/setup.sh
        ssh -i ~/.ssh/ceph_id_rsa -t ${ceph_user}@${target} "set -eux;/tmp/setup.sh client.provision ${host};rm -f /tmp/setup.sh;echo DONE"
        ;;
    client.provision)
        host=$1;shift
        sudo hostname $host
        sudo sed -i "s/debian/${host}/g" /etc/hosts
        echo "${host}"|sudo tee /etc/hostname
        sudo update-grub
        ;;
    client)
        server=$1;shift
        ceph_user=$1;shift
        sudo sed -i -E 's/(ext4[ ]+)(def|err)/\1noatime,\2/' /etc/fstab
        grep ext4 /etc/fstab
        if grep -q eth0 /etc/issue; then
            true
        else
            echo 'eth0: \\4{eth0}' | sudo tee -a /etc/issue
        fi
        if id -u $ceph_user >/dev/null 2>&1; then
            true
        else
            sudo useradd --system -d /home/$ceph_user -m $ceph_user
            echo "$ceph_user ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$ceph_user
            sudo chmod 0440 /etc/sudoers.d/$ceph_user
            sudo cp -av ~/.ssh /home/$ceph_user/
            sudo chown -R $ceph_user /home/$ceph_user
        fi
        sudo mkdir -p /boot/efi/EFI/boot
        sudo cp /boot/efi/EFI/debian/grubx64.efi /boot/efi/EFI/boot/bootx64.efi
        sudo sed --in-place 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0"/' /etc/default/grub
        sudo update-grub
        sudo apt-get update
        sudo apt-get install -y --no-install-recommends gnupg python2 wget
        sudo apt-get install -y --no-install-recommends software-properties-common
        sudo apt-add-repository non-free
        sudo apt-get update
        sudo apt-get install -y --no-install-recommends firmware-amd-graphics firmware-realtek
        sudo apt-get purge -y software-properties-common
        sudo apt-get auto-remove -y software-properties-common
        sudo apt-get install -y --no-install-recommends screen sysstat
        sudo apt-get clean; sudo rm -rf /var/lib/apt/lists/*
        ;;
    *)
        echo "Unknown $mode" >&2
        exit 1
esac