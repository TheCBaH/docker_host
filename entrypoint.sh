#!/bin/sh
set -eux
if [ $# -ge 1 ]; then
    if [ "$1" = run ]; then
        shift;

        while true; do
            if [ $# -eq 0 ]; then
                break;
            fi
            case $1 in
            *)
                break
                ;;
           esac
           shift
        done

        username=$(cat /root/username)
        HOME=/home/$username
        export HOME
        USER=$username
        export USER
        cd ${HOME}
        exec chroot --skip-chdir --userspec=$username:$username / "$@"
    fi
    if [ "$1" = exec ]; then
        shift
        username=$(cat /root/username)
        exec chroot --skip-chdir --userspec=$username:$username / "$@"
    fi
fi
exec "$@"
