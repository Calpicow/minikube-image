#!/bin/bash
rm -f /etc/kubernetes/*.conf

# Clean kubelet mounts
find /var/lib/kubelet/pods -type d -exec umount {} \; &> /dev/null

echo "127.0.0.1 minikube" >> /etc/hosts
minikube start --vm-driver=none --feature-gates=MountPropagation=false --kubernetes-version="${KUBERNETES_VERSION}" &

# Wait until kubeadm is done
echo -e "HTTP/1.1 200 OK\r\n" | nc -l -p "${KUBELET_HEALTHZ_PORT:-10248}"

cp -r /var/lib/minikube/certs /var/lib/minikube-mod/
cp /root/.minikube/client.* /var/lib/minikube-mod/certs/

# Certs are overridden every time it starts
# A stable service account key is required for the cluster to continue working after restarts
if [[ ! -f /var/lib/minikube-mod/certs/service-account.key ]]; then
    cp /var/lib/minikube-mod/certs/sa.key /var/lib/minikube-mod/certs/service-account.key
fi

if [[ ! -f /var/lib/minikube-mod/certs/service-account.pub ]]; then
    cp /var/lib/minikube-mod/certs/sa.pub /var/lib/minikube-mod/certs/service-account.pub
fi

if [[ ${CP_MANIFESTS:-true} == true ]]; then
    cp /tmp/manifests/* /etc/kubernetes/manifests/
fi

# Fix permissions--kubeadm doesn't set them correctly
chmod 600 /var/lib/minikube-mod/kubeconfig
chmod 644 /var/lib/minikube-mod/certs/*.crt
chmod 644 /var/lib/minikube-mod/certs/*.pub
chmod 600 /var/lib/minikube-mod/certs/*.key
chmod 644 /var/lib/minikube-mod/certs/etcd/*.crt
chmod 600 /var/lib/minikube-mod/certs/etcd/*.key

chmod 600 /etc/kubernetes/addons/*.yaml
chmod 600 /etc/kubernetes/manifests/*.yaml

# Redirect persistent storage to host filesystem
find /etc/kubernetes/manifests -type f -exec sh -c "sed -i 's#path: /etc/kubernetes#path: "${MINIKUBE_PATH}"/kubernetes#' {}" \;
find /etc/kubernetes/manifests -type f -exec sh -c "sed -i 's#path: /var/lib/minikube#path: "${MINIKUBE_PATH}"/minikube#' {}" \;
find /etc/kubernetes/manifests -type f -exec sh -c "sed -i 's#path: /data/minikube#path: "${MINIKUBE_PATH}"/minikube/etcd#' {}" \;

# Fix ca-certificate mounting
find /etc/kubernetes/manifests -type f -exec sh -c "sed -i 's#path: /etc/ca-certificates#path: /tmp/etc/ca-certificates#' {}" \;
find /etc/kubernetes/manifests -type f -exec sh -c "sed -i 's#path: /etc/ssl/certs#path: /tmp/etc/ssl/certs#' {}" \;
find /etc/kubernetes/manifests -type f -exec sh -c "sed -i 's#path: /usr/local/share/ca-certificates#path: /tmp/usr/local/share/ca-certificates#' {}" \;
find /etc/kubernetes/manifests -type f -exec sh -c "sed -i 's#path: /usr/share/ca-certificates#path: /tmp/usr/share/ca-certificates#' {}" \;


# Rewrite dashboard port to 443
sed -i 's/port: 80/port: 443/' /etc/kubernetes/addons/dashboard-svc.yaml

# Use persistent service account key
find /etc/kubernetes/manifests -type f -exec sh -c "sed -i 's#/var/lib/minikube/certs/sa#/var/lib/minikube/certs/service-account#' {}" \;

# Remove *OrCreate flag since path won't exist in container
find /etc/kubernetes/manifests -type f -exec sh -c "sed -i '/OrCreate/d' {}" \;

kubectl config view --merge=true --flatten=true > /var/lib/minikube-mod/kubeconfig
eval $(cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf | grep ExecStart=/ | sed 's/ExecStart=//')
