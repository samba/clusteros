#!/bin/bash
# This script runs inside the target installed host.
# This is NOT where you put your config.

set -euf -o pipefail

usage () {
 return
}


export SSH_PORT=22
export SSH_SERVICE_TYPE=_ssh._tcp


# NB: this needs some improvement to handle hosts with multiple NICs
export HOST_IP=$(ip --brief addr | awk '{ if ( $2 == "UP" ){ split($3, v, "/"); print v[1]; } }')
export HOST_IFACE=$(ip --brief addr | grep UP | grep ${HOST_IP} | awk '{ print $1 }')

main () {
    local kargs=NONE hostrandom=NONE hostserial=NONE credfile=NONE
    while getopts ":k:r:s:c:h" opt; do
        case ${opt} in
            k)  kargs="${OPTARG}";;
            r)  hostrandom="${OPTARG}";;
            s)  hostserial="${OPTARG}";;
            c)  credfile="${OPTARG}";;
            h)  usage && exit 0;;
        esac
    done
    shift $((OPTIND -1));

    source ${credfile}

    ALT_USER=$(grep -oE 'USER=(\w+)' ${credfile} | cut -d = -f 2)
    ALT_HOST=$(grep -oE 'HOSTNAME=(\w+)' ${credfile} | cut -d = -f 2)

    setup_kernel
    setup_network_bridge
    setup_containerd
    setup_kubernetes_repo ${KUBERNETES_VERSION}

    # Insall Kubernetes components
    apt-get update && apt-get install -y \
        kubelet kubeadm kubectl cri-tools kubernetes-cni

    set_hostname "${ALT_HOST}-${hostserial:-${hostrandom}}"
    echo "127.0.1.1 ${ALT_HOST}-${hostserial:-${hostrandom}}" >> /etc/hosts


    for i in ssh sftp-ssh; do
        ln -s /usr/share/doc/avahi/${i}.service /etc/avahi/services/ ;
    done


    for s in ssh containerd avahi-daemon; do
        systemctl enable ${s}
        systemctl start ${s}
    done

    avahi-publish -s ${CLUSTER_SERVICE_NAME} ${SSH_SERVICE_TYPE} ${SSH_PORT} "SSH for bootstrapping ${CLUSTER_SERVICE_NAME}"
    avahi-publish -a ${CLUSTER_ENDPOINT} ${HOST_IP}


    # LASTLY
    systemctl disable firstboot
}

set_hostname () {
    hostnamectl hostname "${1}"
    # sed -i -E "s/(unassigned-hostname|${2})/${1} ${2} \\1/g" /etc/hosts
}


setup_network_bridge () {
    mkdir -p /etc/network/interfaces.d

    # set manual mode for main interface
    bridge=/etc/network/interfaces.d/bridge
    echo "auto br0" >> ${bridge}
    echo "iface br0 inet dhcp" >> ${bridge}
    echo "\tbridge_ports ${HOST_IFACE}" >> ${bridge}
    echo "\tbridge_stp off" >> ${bridge}
    echo "\tbridge_fd 0" >> ${bridge}
    echo "\tbridge_maxwait 0" >> ${bridge}
    echo "\tmetric 100" >> ${bridge}

    hostnet=/etc/network/interfaces.d/hostnet
    echo "auto ${HOST_IFACE}" >> ${hostnet}
    echo "iface ${HOST_IFACE} inet manual" >> ${hostnet}
    echo "iface ${HOST_IFACE} inet6 manual" >> ${hostnet}


    sed -i .old "/${HOST_IFACE}/d" /etc/network/interfaces

    echo 'source /etc/network/interfaces.d/*' >> /etc/network/interfaces

    systemctl restart networking
}


setup_containerd () {
    containerd config default | sed -E 's/(SystemdCgroup =) false/\1 true/g;' > /etc/containerd/config.toml
    systemctl restart containerd
}

setup_kernel () {
    echo "overlay" >> /etc/modules-load.d/containerd.conf
    echo "br_netfilter" >> /etc/modules-load.d/containerd.conf

    for m in overlay br_netfilter; do
        modprobe ${m}
    done

    ( # several lines...
    echo "net.bridge.bridge-nf-call-iptables = 1"
    echo "net.bridge.bridge-nf-call-ip6tables = 1"
    echo "net.ipv4.ip_forward = 1"
    )>> /etc/sysctl.d/99-kubernetes-k8s.conf

    sysctl --system  # reload
}


setup_kubernetes_repo () {
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${1}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v${1}/deb/Release.key |sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
}


apt-get purge --auto-remove -y

# TODO: generate new key for storage, remove original key
# TODO:  enroll TPM key for disk crypto
# https://blog.fernvenue.com/archives/debian-with-luks-and-tpm-auto-decryption/

test $# -gt 1 && main "$@" || usage

