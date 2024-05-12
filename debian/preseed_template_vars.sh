#!/bin/bash
# Provides the environment for generating preseed configuration.
# Passwords must be generated via [crypt(3) hash]



export USER=${USER:-user}
export USER_FULLNAME="Debian User"
export CREATE_USER=true

export ENABLE_ROOT=true

USER_PASSWORD_PLAIN=$(openssl rand -base64 8)
ROOT_PASSWORD_PLAIN=$(openssl rand -base64 10)

export DISK_CRYPTO_KEY=$(openssl rand -hex 36)
export USER_PASSWORD=$(openssl passwd -1 "${USER_PASSWORD_PLAIN}")
export ROOT_PASSWORD=$(openssl passwd -1 "${ROOT_PASSWORD_PLAIN}")
export KUBEADM_CERTS=$(openssl rand -hex 32)
export KUBEADM_TOKEN="$(openssl rand -hex 3).$(openssl rand -hex 8)"
export CLUSTER_ENDPOINT="cluster-endpoint-$(openssl rand -hex 2)"

# NB: this hostname is only temporarily used during setup, and gets regenerated on first boot.
# unassigned is default
#export HOSTNAME=unassigned-hostname
#export DOMAIN=unassigned-domain
export HOSTNAME="node-$(openssl rand -hex 2)"
export DOMAIN=cluster.local

# Exposed in machine readable format for later...
echo "DISK_CRYPTO_KEY=${DISK_CRYPTO_KEY}" >&2
echo "PASSWORD_USER=${USER_PASSWORD_PLAIN}" >&2
echo "PASSWORD_ROOT=${ROOT_PASSWORD_PLAIN}" >&2
echo "KUBEADM_CERTS=${KUBEADM_CERTS}" >&2
echo "KUBEADM_TOKEN=${KUBEADM_TOKEN}" >&2
echo "CLUSTER_ENDPOINT=${CLUSTER_ENDPOINT}" >&2
echo "CLUSTER_SERVICE_NAME=homecloud-$(openssl rand -hex 2)" >&2

export LVM_VOLUME_GROUP=vgdefault
export DEBIAN_SUITE=stable
export MIRROR_PROXY=
export ASSUME_UEFI=true

# TODO: more security
# export USER_SHELL=/bin/rbash
export USER_SHELL=/bin/bash
