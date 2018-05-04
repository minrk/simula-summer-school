IMAGE=minrk/simula-summer-school:2018
HUB_VERSION=v0.7-c72aad9
KUBE_CTX=sss

.PHONY: image push

image:
	docker build -t $(IMAGE) image

push:
	docker push $(IMAGE)

upgrade:
	# helm dep up ./jupyterhub
	helm upgrade hub --kube-context=$(KUBE_CTX) ./jupyterhub -f config.yaml -f secrets.yaml --namespace=default

conda:
	docker build -t conda-pkgs conda-recipes

conda/%: conda
	- cd conda-recipes
	docker run --rm -it -v $(PWD)/conda-bld:/opt/conda-bld -v $(PWD)/conda-recipes:/conda-recipes conda-pkgs conda build /conda-recipes/$*

run:
	docker run -it --rm -p9999:8888 $(IMAGE) jupyter notebook --ip=0.0.0.0

pull:
	- kubectl --context=$(KUBE_CTX) delete jobs pull-manual 2>/dev/null
	kubectl --context=$(KUBE_CTX) create -f ./puller.yaml
	- watch kubectl --context=$(KUBE_CTX) get pods -a --selector=job-name=pull-manual
	kubectl --context=$(KUBE_CTX) delete jobs pull-manual

clean-jobs:
	kubectl --context=$(KUBE_CTX) delete jobs $(shell kubectl get jobs -a | sed '1d' | awk '{print $$1}')
