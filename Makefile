KUBE_CTX=sss
GKE_PROJECT=simula-summer-school-2023
GKE_ZONE=europe-west1
IMAGE=$(GKE_ZONE)-docker.pkg.dev/$(GKE_PROJECT)/sss/simula-summer-school:2023
NS=jupyterhub
BUILDER_NAME=sss-builder

.PHONY: image image-test push conda-rsync conda-fetch terraform kube-creds

image: $(wildcard image/*)
	docker buildx build --platform linux/amd64 --load -t $(IMAGE) image

image/conda-linux-64.lock: image/environment.yml
	conda-lock lock -k explicit --mamba --channel conda-forge --channel minrk --platform linux-64 --filename-template $@ -f $<

image-test:
	docker buildx build --load -t image-test --build-arg IMAGE=$(IMAGE) image-test
	docker run --rm -it image-test pytest -vs $(ARG)

dive:
	dive $(IMAGE)

push-creds:
	gcloud auth configure-docker $(GKE_ZONE)-docker.pkg.dev

push:
	docker push $(IMAGE)

# list images
# gcloud compute images list --filter=name=ubuntu

# https://gitlab.com/gitlab-org/ci-cd/docker-machine/-/issues/47
# Error 404: The resource 'projects/simula-summer-school-2023/global/firewalls/docker-machines' was not found, notFound

builder-firewall-rule:
	gcloud --project=$(GKE_PROJECT) compute firewall-rules create docker-machines --allow=tcp:22

builder-new:
	docker-machine create $(BUILDER_NAME) \
	    --driver=google \
	    --google-project=$(GKE_PROJECT) \
	    --google-preemptible \
	    --google-disk-size=100 \
	    --google-machine-image=ubuntu-os-cloud/global/images/ubuntu-minimal-2204-jammy-v20230413 \
	    --google-machine-type=e2-standard-4 \
	    --google-zone=europe-west1-b
	docker-machine ssh $(BUILDER_NAME) -- sudo apt-get install -y rsync
	docker-machine ssh $(BUILDER_NAME) -- sudo mkdir -p $(PWD)
	docker-machine ssh $(BUILDER_NAME) -- sudo chown ubuntu $(PWD)

builder-start:
	docker-machine start $(BUILDER_NAME)
	make builder-certs

builder-certs:
	docker-machine regenerate-certs -f $(BUILDER_NAME)

builder-env:
	@docker-machine env $(BUILDER_NAME)

builder-rm:
	docker-machine rm $(BUILDER_NAME)

terraform:
	cd terraform; terraform init -upgrade; terraform apply

kube-creds:
	gcloud --project=$(GKE_PROJECT) container clusters get-credentials --region $(GKE_ZONE) $(KUBE_CTX)
	kubectx $(KUBE_CTX)=.
	@kubectl create namespace jupyterhub
	kubens jupyterhub

HELM_ARGS := hub --namespace=$(NS) --kube-context=$(KUBE_CTX) ./jupyterhub -f config.yaml -f secrets.yaml

helm-diff:
	helm diff upgrade $(HELM_ARGS)

helm-upgrade:
	helm dep up ./jupyterhub
	helm upgrade --install --cleanup-on-fail $(HELM_ARGS)

conda:
	docker build -t conda-pkgs conda-recipes

conda-rsync:
	rsync -av --delete -e 'docker-machine ssh $(BUILDER_NAME)' conda-recipes/ :$(PWD)/conda-recipes/

conda-fetch:
	rsync -av --delete -e 'docker-machine ssh $(BUILDER_NAME)' :$(PWD)/conda-bld/linux-64/ $(PWD)/conda-bld/linux-64/

conda/%: conda conda-rsync
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
