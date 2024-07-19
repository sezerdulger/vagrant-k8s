#!/bin/bash

ip=$1

k3sup install --ip $ip --user vagrant --cluster --k3s-extra-args "--advertise-address $ip --node-external-ip $ip --node-ip $ip" &
