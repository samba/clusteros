

export DEFAULT_KUBE_PORT=6443

setup () {

    # Register the virtual alias initially, on all hosts
    # Later this can be removed when a VIP-based solution is integrated
    echo "${CP_FIRST_HOST_STATIC_IP}  ${CP_ALT_NAME} ${CLUSTER_ENDPOINT}" >> /etc/hosts

    case $(host_role ${CP_FIRST_HOST_STATIC_IP} ${CP_SECONDARY_STATIC_IP[*]}) in
    0)  # primary
        kubeadm init \
            --kubernetes-version="stable-${KUBERNETES_VERSION}" \
            --token=${KUBEADM_TOKEN} \
            --apiserver-advertise-address=${CP_FIRST_HOST_STATIC_IP} \
            --apiserver-cert-extra-sans=${CP_ALT_NAME},${CLUSTER_ENDPOINT} \
            --control-plane-endpoint=${CP_ALT_NAME}:${DEFAULT_KUBE_PORT} \
            --service-cidr=${SERVICE_CIDR} \
            --pod-network-cidr=${POD_CIDR} \
            --certificate-key=${KUBEADM_CERTS} \
            --upload-certs


        export KUBECONFIG=/etc/kubernetes/admin.conf

        mkdir ~${ALT_USER}/.kube
        cp -v ${KUBECONFIG} ~${ALT_USER}/.kube/admin.conf
        chown ${ALT_USER}: ~${ALT_USER}/.kube -R

        sleep 10;

        # remove node taints
        kubectl taint nodes --all node-role.kubernetes.io/control-plane-
        kubectl taint nodes --all node-role.kubernetes.io/master-


        # install Calico
        for i in tigera-operator custom-resources; do
            kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/${i}.yaml
        done



    ;;
    1|2|3|4)  # secondary
        while ! kubeadm join \
            --token=${KUBEADM_TOKEN} \
            --discovery-token-unsafe-skip-ca-verification \
            --apiserver-advertise-address=${CP_FIRST_HOST_STATIC_IP} \
            --certificate-key=${KUBEADM_CERTS} \
            --control-plane \
            ${CP_ALT_NAME}:${DEFAULT_KUBE_PORT} \
            ; do sleep 3; done  # retry loop


        export KUBECONFIG=/etc/kubernetes/admin.conf

        mkdir ~${ALT_USER}/.kube
        cp -v ${KUBECONFIG} ~${ALT_USER}/.kube/admin.conf
        chown ${ALT_USER}: ~${ALT_USER}/.kube -R

        # remove node taints
        kubectl taint nodes --all node-role.kubernetes.io/control-plane-
        kubectl taint nodes --all node-role.kubernetes.io/master-

    ;;
    *)
        while ! kubeadm join \
            --token=${KUBEADM_TOKEN} \
            --discovery-token-unsafe-skip-ca-verification \
            ${CP_ALT_NAME}:${DEFAULT_KUBE_PORT} \
            ; do sleep 3; done  # retry loop
    ;;
    esac


    for s in ssh containerd kubelet; do
        systemctl enable ${s}
        systemctl start ${s}
    done

}

    # TODO: disable node taints on CP, for home clusters
    # https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#control-plane-node-isolation
    # (if ${ALLOW_POD_EXEC_ON_CP} ...)



host_role () {
    ct=0
    myip=$(ip --brief addr | awk '{ if ( $2 == "UP" ){ split($3, v, "/"); print v[1]; } }')
    for i; do
        test "${myip}" == "${i}" && echo ${ct} && return
        ct=$((ct + 1))
    done

    echo "worker"
}

