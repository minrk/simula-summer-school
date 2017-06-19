Basic setup: create project, select it, create cluster and init helm

    gcloud projects create simula-summer-school-2017
    gcloud config set project simula-summer-school-2017
    kubectl config use-context gke_simula-summer-school-2017_us-central1-a_simula-summer-school-2017
    gcloud container clusters create simula-summer-school-2017 --num-nodes=1 --machine-type n1-standard-4
    gcloud beta container clusters upgrade --cluster-version 1.6.4 --master simula-summer-school-2017
    helm init

Switch to simula-summer-school:

    kubectl config use-context gke_simula-summer-school-2017_us-central1-a_simula-summer-school-2017

Delete it all: `helm delete --purge hub`


Ingress (binderhub-deploy repo):

    helm install --namespace support support --name support
Redeploy:

    helm delete --purge hub
    helm install ./helm-chart/jupyterhub -f config.yaml -f secrets.yaml --name hub

Upgrade:

    helm upgrade hub ./helm-chart/jupyterhub -f config.yaml -f secrets.yaml


build image:

    eval $(docker-machine env builder)
    docker build -t minrk/simula-summer-school:test image
    docker push minrk/simula-summer-school:test

cleanup completed jobs:

    kubectl delete job $(kubectl get jobs --all-namespaces | sed '1d' | awk '{print $2}')
    kubectl delete pod $(kubectl get pod -a | grep Completed | awk '{print $1}')

