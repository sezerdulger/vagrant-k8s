#!/bin/bash

vagrant up

vagrant halt k8s-master-1 k8s-master-2 k8s-master-3

vagrant up --provision k8s-master-1
vagrant up --provision k8s-master-2 k8s-master-3
