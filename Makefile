IMAGE=minrk/simula-summer-school:2018
HUB_VERSION=v0.7-c72aad9

.PHONY: image push

image:
	docker build -t $(IMAGE) image

push:
	docker push $(IMAGE)

upgrade:
	# helm dep up ./jupyterhub
	helm upgrade --install hub ./jupyterhub -f config.yaml -f secrets.yaml --namespace=default

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
