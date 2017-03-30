#!/bin/bash

gcloud compute --project "slavayssiere-sandbox" networks create "wereport-network" --mode "auto"

gcloud compute --project "slavayssiere-sandbox" firewall-rules create "wereport-network-allow-internal" \
    --allow all \
    --network "wereport-network"
    
gcloud compute --project "slavayssiere-sandbox" firewall-rules create "allow-wereport-backend" \
    --allow=tcp:31080,tcp:31081,tcp:31082 \
    --network "wereport-network"

gcloud container --project "slavayssiere-sandbox" clusters create "wereport" \
    --zone "europe-west1-b" \
    --machine-type "n1-standard-1" \
    --image-type "GCI" \
    --disk-size "100" \
    --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
    --network "wereport-network" \
    --enable-cloud-logging \
    --no-enable-cloud-monitoring \
    --num-nodes "1" \
    --enable-autoscaling --min-nodes "1" --max-nodes "5"

gcloud container  --project "slavayssiere-sandbox" clusters get-credentials "wereport" --zone europe-west1-b

kubectl create -f namespaces.yaml 
kubectl create -f cassandra.yaml --namespace=dev

find_cassandra_pods="kubectl get pods -l name=cassandra --namespace=dev"

first_running_seed=$($find_cassandra_pods --no-headers | \
    grep Running | \
    grep 1/1 | \
    head -1 | \
    awk '{print $1}')

cluster_status=$(kubectl exec $first_running_seed \
    -c cassandra \
    --namespace=dev \
    -- nodetool status -r)

echo
echo "  C* Node      Kubernetes Pod"
echo "  -------      --------------"

while read -r line; do
    node_name=$(echo $line | awk '{print $1}')
    status=$(echo "$cluster_status" | grep $node_name | awk '{print $1}')

    long_status=$(echo "$status" | \
        sed 's/U/  Up/g' | \
	sed 's/D/Down/g' | \
	sed 's/N/|Normal /g' | \
	sed 's/L/|Leaving/g' | \
	sed 's/J/|Joining/g' | \
	sed 's/M/|Moving /g')

    : ${long_status:="            "}

    echo "$long_status   $line"
done <<< "$($find_cassandra_pods)"

# kubectl scale rc cassandra --replicas=4 --namespace=dev

# kubectl proxy

kubectl create -f wereport-backend.yaml --namespace=dev
