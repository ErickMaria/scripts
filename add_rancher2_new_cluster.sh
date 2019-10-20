
# VARIABLES

if [ ${1,,} == yes ] || [ ${1,,} == no ];
then
    FIRST_ACCESS=${1,,}
else
    echo "invalid value, try: $0 ('yes' or 'no') "
    exit
fi


RANCHER_SERVER_IP=40.117.123.127
RANCHER_SERVER_URL=40.117.123.127
RANCHER_SERVER_PASSWORD=admin
CLUSTER_NAME=cluster001
ROLEFLAGS="--etcd --controlplane --worker"

# echo -e "SHOW VARIABLES\n"
# echo $RANCHER_SERVER_IP
# echo $RANCHER_SERVER_PASSWORD
# echo $CLUSTER_NAME
# echo $ROLEFLAGS
# echo -e "\n"

echo "MAKE LOGIN"
LOGINTOKEN=`curl https://$RANCHER_SERVER_IP/v3-public/localProviders/local?action=login -H 'content-type: application/json' --data-binary '{"username":"admin","password":"admin"}' --insecure --silent | jq -r .token`

echo -e "token: $LOGINTOKEN\n"

if [ $FIRST_ACCESS == "yes" ];
then

    echo "UPDATE RANCHER SERVER PASSWORD"
    curl -s https://$RANCHER_SERVER_IP/v3/users?action=changepassword -H 'content-type: application/json' -H "Authorization: Bearer $LOGINTOKEN" --data-binary '{"currentPassword":"admin","newPassword":"'$RANCHER_SERVER_PASSWORD'"}' --insecure

    echo -e "PASSWORD UPDATE SUCCESSFUL FOR '$RANCHER_SERVER_PASSWORD'\n"

fi

echo "CREATE API KEY"
APITOKEN=`curl -s https://$RANCHER_SERVER_IP/v3/token -H 'content-type: application/json' -H "Authorization: Bearer $LOGINTOKEN" --data-binary '{"type":"token","description":"automation"}' --insecure | jq -r .token`
echo -e "token: $APITOKEN\n"

if [ $FIRST_ACCESS -eq "yes" ];
then

    echo "SET RANCHER SERVER URL"
    RANCHER_SERVER_UPDATE=`curl -s https://$RANCHER_SERVER_IP/v3/settings/server-url -H 'content-type: application/json ' -H "Authorization: Bearer $APITOKEN" -X PUT --data-binary '{"name":"server-url","value":"'$RANCHER_SERVER_URL'"}' --insecure | jq -r .value`

    echo -e "RANCHER SERVER URL WAS UPDATED FOR '$RANCHER_SERVER_UPDATE'\n"

fi

echo "CREATE CUSTOM CLUSTER"
CLUSTERID=`curl -s https://$RANCHER_SERVER_URL/v3/cluster -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" --data-binary '{"dockerRootDir":"/var/lib/docker","enableNetworkPolicy":false,"type":"cluster","rancherKubernetesEngineConfig":{"addonJobTimeout":30,"ignoreDockerVersion":true,"sshAgentAuth":false,"type":"rancherKubernetesEngineConfig","authentication":{"type":"authnConfig","strategy":"x509"},"network":{"type":"networkConfig","plugin":"canal"},"ingress":{"type":"ingressConfig","provider":"nginx"},"monitoring":{"type":"monitoringConfig","provider":"metrics-server"},"services":{"type":"rkeConfigServices","kubeApi":{"podSecurityPolicy":false,"type":"kubeAPIService"},"etcd":{"snapshot":false,"type":"etcdService","extraArgs":{"heartbeat-interval":500,"election-timeout":5000}}}},"name":"'$CLUSTER_NAME'"}' --insecure | jq -r .id`

echo -e "cluster id: $CLUSTERID\n"

echo "CREATING CLUSTER REGISTRATION TOKEN"
curl -s https://$RANCHER_SERVER_URL/v3/clusterregistrationtoken -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" --data-binary '{"type":"clusterRegistrationToken","clusterId":"'$CLUSTERID'"}' --insecure > /dev/null

echo -e "CLUSTER REGISTRATION TOKEN WAS CREATED SUCCESSFUL\n"

echo "NODE COMMAND"
AGENTCMD=`curl -s https://$RANCHER_SERVER_URL/v3/clusterregistrationtoken?id="'$CLUSTERID'" -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" --insecure | jq -r '.data[].nodeCommand' | head -1`
DOCKERRUNCMD="$AGENTCMD $ROLEFLAGS"

echo -e "$DOCKERRUNCMD"
