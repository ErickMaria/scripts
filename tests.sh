#!/bin/bash
LOCAL_IP=`ip route get 1.1.1.1 | grep -oP 'src \K\S+'`
RANCHER_SERVER_URL=$LOCAL_IP
docker run -e "CATTLE_AGENT_IP=$LOCAL_IP" --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.2.11 $RANCHER_SERVER_URL
