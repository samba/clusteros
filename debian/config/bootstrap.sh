#/bin/bash

# CONFIG file for cluster setup

# The first host will become a control-plane server, and must have a static IP, initially.
# This address must be reachable by all other hosts in the cluster, and you'll probably need to communicate with it too from your network.
CP_FIRST_HOST_STATIC_IP=192.168.253.9

# To allow for later high-availability a name alias will be advertised.
CP_ALT_NAME=cluster.local

# Optional, but recommended for fault tolerance
# 2 or 4 hosts which will take control-plane roles, as secondary.
CP_SECONDARY_STATIC_IP=(192.168.253.10 192.168.253.11)


# Which version of Kubernetes to run?
KUBERNETES_VERSION=1.28
CALICO_VERSION=3.27.3

# Ensure that these do not conflict with address ranges your host network uses
POD_CIDR="10.6.0.0/16"
SERVICE_CIDR="10.7.1.0/24"


# Should workload pods be allowed to execute on the control plane?
# (in small clusters, maybe yes?)
ALLOW_POD_EXEC_ON_CP=true


# Override default system user name
USER=tunafish
