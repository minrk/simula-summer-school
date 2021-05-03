KUBE_CTX=sss
GKE_PROJECT=simula-summer-school-202212
IMAGE=gcr.io/$(GKE_PROJECT)/simula-summer-school:2021
GKE_ZONE=europe-west1
NS=jupyterhub

.PHONY: image image-test push conda-rsync conda-fetch terraform kube-creds

image: $(wildcard image/*)
	docker buildx build --load -t $(IMAGE) image

image/conda-linux-64.lock: image/environment.yml
	cd image; conda-lock --mamba --channel conda-forge --channel minrk --platform linux-64 -f environment.yml

image-test:
	docker buildx build --load -t image-test --build-arg IMAGE=$(IMAGE) image-test
	docker run --rm -it image-test pytest -v $(ARG)

dive:
	dive $(IMAGE)

push:
	docker push $(IMAGE)

builder-new:
	docker-machine create sss-builder \
	    --driver=google \
	    --google-project=jupyter-simula \
	    --google-preemptible \
	    --google-disk-size=100 \
	    --google-machine-type=n1-standard-4 \
	    --google-zone=europe-west1-b

builder-start:
	docker-machine start sss-builder
	docker-machine regenerate-certs -f sss-builder

builder-env:
	@docker-machine env sss-builder

terraform:
	cd terraform; terraform init; terraform apply

kube-creds:
	gcloud --project=$(GKE_PROJECT) container clusters get-credentials --region $(GKE_ZONE) $(KUBE_CTX)
	kubectx sss=.

HELM_ARGS := hub --namespace=$(NS) --kube-context=$(KUBE_CTX) ./jupyterhub -f config.yaml -f secrets.yaml
helm-diff:
	helm diff upgrade $(HELM_ARGS)

helm-upgrade:
	helm dep up ./jupyterhub
	helm upgrade --install --cleanup-on-fail $(HELM_ARGS)

conda:
	docker build -t conda-pkgs conda-recipes

conda-rsync:
	rsync -av --delete -e 'docker-machine ssh sss-builder' conda-recipes/ :$(PWD)/conda-recipes/

conda-fetch:
	rsync -av --delete -e 'docker-machine ssh sss-builder' :$(PWD)/conda-bld/linux-64/ $(PWD)/conda-bld/linux-64/

conda/%: conda
	docker run --rm -it -e CPU_COUNT=4 -v $(PWD)/conda-bld:/io/conda-bld -v $(PWD)/conda-recipes:/conda-recipes -v /tmp/conda-pkgs:/opt/conda/pkgs conda-pkgs build-conda /conda-recipes/$*

conda-upload/%:
	docker run --rm -it -v $(PWD)/conda-bld:/io/conda-bld conda-pkgs sh -c 'anaconda upload /io/conda-bld/linux-64/$*-*.tar.bz2'

run:
	docker run -it --rm -p9999:8888 $(IMAGE) $(ARG)

pull:
	- $(foreach instance, \
		$(shell gcloud compute instances list --format json --project=$(GKE_PROJECT) | jq -r ".[].name"), \
  		gcloud --project=$(GKE_PROJECT) compute ssh --zone=$(GKE_ZONE) $(instance) -- docker pull $(IMAGE);)

clean-jobs:
	kubectl --context=$(KUBE_CTX) delete jobs $(shell kubectl get jobs -a | sed '1d' | awk '{print $$1}')
