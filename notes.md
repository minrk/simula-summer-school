Basic setup: create project, select it, create cluster and init helm

    gcloud projects create simula-summer-school
    gcloud config set project simula-summer-school
    gcloud container clusters create sss --zone=europe-west1-b --num-nodes=1 --machine-type n1-standard-4
    helm init

Switch to simula-summer-school:

    kubectx sss=.
    kubectx sss

Delete it all: `helm delete --purge hub`

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

