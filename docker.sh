set -eux
apt-get install -y \
    apparmor git git-man iptables less libbsd0 libcurl3-gnutls libedit2 \
    liberror-perl libgdbm-compat4 libgdbm5 libip4tc0 libip6tc0 libiptc0 libltdl7 \
    libmnl0 libnetfilter-conntrack3 libnfnetlink0 libperl5.26 libssl1.0.0 \
    libx11-6 libx11-data libxau6 libxcb1 libxdmcp6 libxext6 libxmuu1 \
    libxtables12 multiarch-support netbase openssh-client patch perl \
    perl-modules-5.26 xauth
env http_proxy= curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
env http_proxy= apt-get update
env http_proxy= apt-get install docker-ce docker-ce-cli containerd.io
