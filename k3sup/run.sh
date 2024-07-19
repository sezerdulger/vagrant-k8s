#!/bin/bash

k3sup install --host 192.168.2.10 --ip 192.168.2.10 --user vagrant --cluster --k3s-extra-args '--advertise-address 192.168.2.10 --node-external-ip 192.168.2.10 --node-ip 192.168.2.10'
ssh-keygen -t rsa
ssh-copy-id vagrant@192.168.2.50

k3sup join --ip 192.168.2.11 --user vagrant --server-user vagrant --server-ip 192.168.2.10 --server --k3s-extra-args '--advertise-address 192.168.2.11 --node-external-ip 192.168.2.11 --node-ip 192.168.2.11'



k3sup join --ip 192.168.2.50 --user vagrant --server-user vagrant --server-ip 192.168.2.10 --k3s-extra-args ' --node-external-ip 192.168.2.50 --node-ip 192.168.2.50'