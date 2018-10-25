#!/bin/bash
if [[ ! -L /tmp/hostpath-provisioner ]]; then
    mkdir -p "${HOME}"/.minikube/minikube/hostpath-provisioner
    mv /tmp/hostpath-provisioner/* "${HOME}"/.minikube/minikube/hostpath-provisioner/
    rm -rf /tmp/hostpath-provisioner
    ln -s "${HOME}"/.minikube/minikube/hostpath-provisioner /tmp/hostpath-provisioner
fi

docker run --rm --pid=host --privileged --entrypoint=/bin/bash registry.jpl.nasa.gov/kube/minikube-image:latest -c "nsenter --mount=/proc/1/ns/mnt mkdir -p /var/lib/kubelet"
docker run -d \
    --rm \
    --cpus=0.5 \
    --env=KUBERNETES_VERSION="${KUBERNETES_VERSION:-v1.11.4}"
    --env=MINIKUBE_PATH="${HOME}"/.minikube \
    --name=minikube \
    --hostname=minikube \
    --net=host \
    --pid=host \
    --privileged \
    --volume=/sys:/sys:ro \
    --volume=/var/lib/docker:/var/lib/docker:rw \
    --volume=/var/lib/kubelet:/var/lib/kubelet:shared \
    --volume=/var/log:/var/log:rw \
    --volume=/var/run:/var/run:rw \
    --volume="${HOME}"/.minikube/cache:/root/.minikube:rw \
    --volume="${HOME}"/.minikube/kubernetes:/etc/kubernetes:rw \
    --volume="${HOME}"/.minikube/minikube:/var/lib/minikube-mod:rw \
    registry.jpl.nasa.gov/kube/minikube-image:latest
