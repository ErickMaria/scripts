#!bin/bash

rqtt=1320
total_resquest_sucecess=0

while [ $total_resquest_sucecess != $rqtt ]
do
  current=0
  canary=0
  get_versions=$(siege -p -r110 -d1 -c12 http://lb-helloapp.35.196.211.203.xip.io | awk '{ print $5 }' )
  for version in $get_versions
  do
      if [ $version == "1.0.0" ]
      then
        ((current++))
      fi     
      if [ $version == "2.0.0" ]
      then
        ((canary++))
      fi
  done
  total_resquest_sucecess=$((current+canary))
done

echo "total requests => $total_resquest_sucecess"
echo "current (v1.0.0) => $current"
echo "canary  (v2.0.0) => $canary"
