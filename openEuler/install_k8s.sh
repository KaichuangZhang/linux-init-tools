#!/bin/sh
#set -e
## dir
path=$(
  cd "$(dirname "$0")"
  pwd
)
echo "dir:$path"

ip=`hostname -I | awk '{print $1}'`
echo "ip:$ip"


## hostname
nodes_info="$path/nodes_info.txt"
hostname=`cat $nodes_info | grep $ip | awk '{print $1}'`
echo $hostname
sudo echo $hostname > /etc/hostname

## hosts
hosts_path="/etc/hosts"
host_content=`cat /etc/hosts | grep $ip`
if [[ $host_content == "" ]]; then
    cat $nodes_info >> $hosts_path
fi


## swap
swapoff -a

## firewall
systemctl stop firewalld
systemctl disable firewalld

if [[ $hostname == "master" ]]; then
    # install docker
    dnf install -y docker
    systemctl enable docker
    systemctl start docker
    docker --version
    # install kubeadm
    dnf install -y kubernetes-kubeadm
    kubeadm_version=`kubeadm version -o short`
    # install kubelet
    dnf install -y kubernetes-kubelet
    systemctl enable kubelet.service
    systemctl start kubelet.service
    # install kubernetes master
    dnf install -y kubernetes-master
    # install conntrack
    dnf install -y conntrack
    # kubeadm init 
    kubeadm reset
    kubeadm init \
        --apiserver-advertise-address=192.168.123.208 \
        --image-repository registry.aliyuncs.com/google_containers \
        --kubernetes-version $kubeadm_version \
        --service-cidr=10.1.0.0/16 \
        --pod-network-cidr=10.244.0.0/16
else
    # pass
    echo "pass"
fi

