#!/bin/env bash

K8S_VERSION="v1.29"

# k8s
#
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

#
curl -#fSL https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

#
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

#
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# helm
#
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null

#
sudo apt-get install apt-transport-https --yes

#
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

#
sudo apt-get update
sudo apt-get install helm

# kind
#
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64

#
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
