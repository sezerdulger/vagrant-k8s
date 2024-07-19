#!/bin/bash

ip=$1
master=$2
k3sup join --ip $ip --user vagrant --server-user vagrant --server-ip $master --server --k3s-extra-args "--advertise-address $ip --node-external-ip $ip --node-ip $ip" &

