#!/bin/bash

ips=$(cat /vagrant/blueprint.json | jq -r '.[]|.[]|.ip')

echo $ips

IFS=' ' readarray -t array <<< "$ips"

for ip in "${array[@]}"
do
  echo "$ip"

  expect sshcopyid.sh $ip
done

master_ips=$(cat /vagrant/blueprint.json | jq -r '.master[]|.ip')

master_init="${master_ips[0]}"

#./cluster-master-init.sh $master_init
unset 'master_ips[0]'
for ip in "${master_ips[@]}"
do
  echo "$ip"

  #expect sshcopyid.sh $ip
done