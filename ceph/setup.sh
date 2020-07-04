#!/bin/sh
set -eux
this_script=$(readlink -f $0)
mode=$1;shift
target=$1;shift
ceph_user=$1;shift
case "$mode" in
    server)
        self=$(id -un)@$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)
        ssh-copy-id -i ~/.ssh/ceph_id_rsa ${target}
        ssh -i ~/.ssh/ceph_id_rsa -t $target "set -eux;scp -o StrictHostKeyChecking=no ${self}:${this_script} /tmp/setup.sh;/tmp/setup.sh client ${self} ${ceph_user};rm /tmp/setup.sh;echo DONE"
        ;;
    client)
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