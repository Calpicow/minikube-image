# Portions Copyright 2016 The Kubernetes Authors All rights reserved.
# Portions Copyright 2018 AspenMesh
#
# Licensed under the Apache License, Version 2.0 (the “License”);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Based on:
# https://github.com/kubernetes/minikube/tree/master/deploy/docker/localkube-dind

FROM debian:jessie

ENV DOCKER_VERSION=18.06.1
ENV CRICTL_VERSION=v1.12.0
ENV KUBECTL_VERSION=v1.11.4
ENV MINIKUBE_VERSION=v0.30.0

# Install minikube dependencies
RUN apt-get update -y && \
    apt-get -yy -q install \
    apt-transport-https \
    aufs-tools \
    bridge-utils \
    ca-certificates \
    cifs-utils \
    conntrack \
    curl \
    ebtables \
    ethtool \
    git \
    glusterfs-client \
    gnupg2 \
    ipcalc \
    iptables \
    netcat \
    nfs-common \
    socat \
    software-properties-common \
    sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install docker
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-"${DOCKER_VERSION}"-ce.tgz | tar zx && \
    mv docker/* /usr/local/bin/ && \
    rm -rf docker
VOLUME /var/lib/docker
EXPOSE 2375

# Install crictl
RUN curl -fsSL https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz | tar zx && \
    mv crictl /usr/local/bin/

# Install kubectl
RUN curl -fsSLo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/"${KUBECTL_VERSION}"/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Install minikube
RUN curl -fsSLo /usr/local/bin/minikube https://storage.googleapis.com/minikube/releases/"${MINIKUBE_VERSION}"/minikube-linux-amd64 && \
    chmod +x /usr/local/bin/minikube
ENV MINIKUBE_WANTUPDATENOTIFICATION=false
ENV MINIKUBE_WANTREPORTERRORPROMPT=false
ENV CHANGE_MINIKUBE_NONE_USER=true
# minikube –vm-driver=none checks systemctl before starting. Instead of
# setting up a real systemd environment, install this shim to tell minikube
# what it wants to know
COPY fake-systemctl.sh /usr/local/bin/systemctl
EXPOSE 8443

COPY manifests/* /tmp/manifests/

# Copy local start.sh
COPY start.sh /
RUN chmod +x /start.sh

# If nothing else specified, start up docker and kubernetes.
CMD ["/start.sh"]
