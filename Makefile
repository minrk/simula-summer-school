IMAGE=minrk/simula-summer-school:2018
HUB_VERSION=

.PHONY: image push

image:
	docker build -t $(IMAGE) image

push:
	docker push $(IMAGE)

install:
	helm repo add jupyterhub
	helm repo update
	helm install hub jupyterhub --version=$(HUB_VERSION) -f config.yaml -f secrets.yaml

upgrade:
	helm install --upgrade hub jupyterhub --version=$(HUB_VERSION) -f config.yaml -f secrets.yaml

conda:
	docker build -t conda-pkgs conda-recipes

run:
	docker run -it --rm -p9999:8888 $(IMAGE) jupyter notebook

pull:
	- kubectl delete jobs pull-manual 2>/dev/null
	kubectl create -f ./puller.yaml
	- watch kubectl get pods -a --selector=job-name=pull-manual
	kubectl delete jobs pull-manual

clean-jobs:
	kubectl delete jobs $(shell kubectl get jobs -a | sed '1d' | awk '{print $$1}')
