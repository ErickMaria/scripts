#!/bin/bash
LOCAL_IP=`ip route get 1.1.1.1 | grep -oP 'src \K\S+'`
RANCHER_SERVER_URL=$1
RANCHER_TOKEN=$2
RANCHER_CHECKSUM=$3
echo sudo docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run rancher/rancher-agent:v2.3.0-rc2 --server $RANCHER_SERVER_URL --token $RANCHER_TOKEN --ca-checksum $RANCHER_CHECKSUM --internal-address $LOCAL_IP --etcd --controlplane --worker
