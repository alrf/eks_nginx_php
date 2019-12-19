#!/usr/bin/env bash

kubectl delete namespaces nginx-php
kubectl delete namespaces ingress-nginx
eksctl delete cluster -f /tmp/node-cluster.yaml
