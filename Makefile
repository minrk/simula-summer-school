IMAGE=minrk/simula-summer-school:2021
KUBE_CTX=sss
GKE_PROJECT=simula-summer-school-202212
GKE_ZONE=europe-west1
NS=jupyterhub

.PHONY: image push conda-rsync terraform kube-creds

image: $(wildcard image/*)
	docker build -t $(IMAGE) image

image/conda-linux-64.lock: image/environment.yml
	cd image; conda-lock --platform linux-64 -f environment.yml 

push:
	docker push $(IMAGE)

terraform:
	cd terraform; terraform init; terraform apply

kube-creds:
	gcloud --project=$(GKE_PROJECT) container clusters get-credentials --region $(GKE_ZONE) $(KUBE_CTX)
	kubectx sss=.

upgrade:
	helm dep up ./jupyterhub
	helm upgrade --install --namespace=$(NS) hub --kube-context=$(KUBE_CTX) ./jupyterhub -f config.yaml -f secrets.yaml --cleanup-on-fail

conda:
	docker build -t conda-pkgs conda-recipes

conda-rsync:
	rsync -av --delete -e 'docker-machine ssh sss-builder' conda-recipes/ :$(PWD)/conda-recipes/

conda/%: conda
	docker run --rm -it -v $(PWD)/conda-bld:/io/conda-bld -v $(PWD)/conda-recipes:/conda-recipes conda-pkgs build-conda /conda-recipes/$*

run:
	docker run -it --rm -p9999:8888 $(IMAGE) jupyter notebook --ip=0.0.0.0

pull:
	- $(foreach instance, \
		$(shell gcloud compute instances list --format json --project=$(GKE_PROJECT) | jq -r ".[].name"), \
  		gcloud --project=$(GKE_PROJECT) compute ssh --zone=$(GKE_ZONE) $(instance) -- docker pull $(IMAGE);)

clean-jobs:
	kubectl --context=$(KUBE_CTX) delete jobs $(shell kubectl get jobs -a | sed '1d' | awk '{print $$1}')
