#!/bin/bash

ip=$1
master=$2

k3sup join --ip $ip --user vagrant --server-user vagrant --server-ip $master --k3s-extra-args "--node-external-ip $ip --node-ip $ip" &