#!/usr/bin/env bash

export CLUSTER_NAME="nodes-dev"
export CLUSTER_REGION="us-east-2"

CHECK_TOOLS="eksctl kubectl"
for i in $CHECK_TOOLS; do
	command -v $i >/dev/null 2>&1 || { echo "$i is required, but not installed. Exit."; exit 1; }
done

# DEPLOY
envsubst < ./common/node-cluster.yaml.tmpl > /tmp/node-cluster.yaml
eksctl utils describe-stacks --region=${CLUSTER_REGION} --cluster=${CLUSTER_NAME} | grep -E 'CREATE_COMPLETE|CREATE_IN_PROGRESS' > /dev/null || eksctl create cluster -f /tmp/node-cluster.yaml

for i in $( seq 1 50 ); do
    if [[ $(eksctl utils describe-stacks --region=${CLUSTER_REGION} --cluster=${CLUSTER_NAME} | grep 'CREATE_COMPLETE') ]]; then
    	echo "Stack was created"
        break
    else
    	echo "Please wait until stack will be created..."
    fi
    sleep 30
done

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
kubectl apply -f ./common/service-nlb.yaml

kubectl apply -f ./common/namespace.yaml

kubectl apply -f ./php/pvc.yaml
kubectl apply -f ./php/deployment.yaml
kubectl apply -f ./php/service.yaml

kubectl apply -f ./nginx/configmap.yaml
kubectl apply -f ./nginx/deployment.yaml
kubectl apply -f ./nginx/service.yaml
kubectl apply -f ./nginx/ingress.yaml
for i in $( seq 1 50 ); do
	LB=$(kubectl get ingress -n=nginx-php --no-headers=true -o=custom-columns=:.status.loadBalancer.ingress[0].hostname)
    if [[ $(echo ${LB} | grep 'amazonaws.com') ]]; then
    	sed -i "s|host:.*|host: ${LB}|" ./nginx/ingress.yaml
    	kubectl apply -f ./nginx/ingress.yaml
        break
    else
    	echo "Please wait until LB will be ready..."
    fi
    sleep 10
done

# TESTS
for i in $( seq 1 50 ); do
    if [[ $(curl -I -s -L http://${LB} | grep 'HTTP/1.1 200 OK') ]]; then
        break
    else
    	echo "Checking HTTP code, please wait until app will be ready..."
    fi
    sleep 10
done

for i in $( seq 1 50 ); do
    if [[ $(curl -s -L http://${LB} | grep 'Test Page') ]]; then
        break
    else
    	echo "Checking App Title, please wait until app will be ready..."
    fi
    sleep 10
done

echo "=========== APP is ready ==========="
echo "Use http://${LB} to access"
