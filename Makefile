KUBE_CTX=sss
GKE_PROJECT=simula-summer-school-2024
GKE_REGION=europe-west1
GKE_ZONE=$(GKE_REGION)-b
IMAGE=$(GKE_REGION)-docker.pkg.dev/$(GKE_PROJECT)/sss/simula-summer-school:2024
NS=jupyterhub
BUILDER_NAME=sss-builder

.PHONY: image image-test push conda-rsync conda-fetch terraform kube-creds builder-new-new

image: $(wildcard image/*)
	docker buildx build --platform linux/amd64 --load -t $(IMAGE) image

image/conda-linux-64.lock: image/environment.yml image/virtual-packages.yaml
	conda-lock lock -k explicit --mamba --channel conda-forge --channel minrk --platform linux-64 --virtual-package-spec image/virtual-packages.yaml --filename-template $@ -f $<

image-test:
	docker buildx build --load -t image-test --build-arg IMAGE=$(IMAGE) image-test
	docker run --rm -it image-test pytest -vs $(ARG)

dive:
	dive $(IMAGE)

push-creds:
	gcloud auth configure-docker $(GKE_REGION)-docker.pkg.dev

push:
	docker push $(IMAGE)

# list images
# gcloud compute images list --filter=name=ubuntu

# https://gitlab.com/gitlab-org/ci-cd/docker-machine/-/issues/47
# Error 404: The resource 'projects/simula-summer-school-2023/global/firewalls/docker-machines' was not found, notFound

builder-firewall-rule:
	gcloud --project=$(GKE_PROJECT) compute firewall-rules create docker-machines --allow=tcp:22

builder-new:
	gcloud compute instances create $(BUILDER_NAME) \
		--project=$(GKE_PROJECT) \
		--zone=$(GKE_ZONE) \
		--preemptible \
		--machine-type=e2-standard-4 \
		--boot-disk-size=100 \
		--boot-disk-type=pd-balanced \
		--image-project=ubuntu-os-cloud \
		--image-family=ubuntu-minimal-2204-lts
	gcloud compute config-ssh --project=$(GKE_PROJECT)
	# setup docker
	gcloud compute ssh --project=$(GKE_PROJECT) --zone=$(GKE_ZONE) $(BUILDER_NAME) -- "curl https://get.docker.com | bash; sudo usermod -aG docker $$(whoami)"
	# setup rsync
	gcloud compute ssh --project=$(GKE_PROJECT) --zone=$(GKE_ZONE) $(BUILDER_NAME) -- 'sudo apt-get -y install rsync'
	gcloud compute ssh --project=$(GKE_PROJECT) --zone=$(GKE_ZONE) $(BUILDER_NAME) -- 'sudo mkdir -p $(PWD) && sudo chown $$(whoami) $(PWD)'

builder-start:
	gcloud compute instances start --project=$(GKE_PROJECT) --zone=$(GKE_ZONE) $(BUILDER_NAME)
	# reload
	gcloud compute config-ssh --project=$(GKE_PROJECT)

builder-env:
	@echo "export DOCKER_HOST=ssh://$(BUILDER_NAME).$(GKE_ZONE).$(GKE_PROJECT)"

builder-rm:
	docker-machine rm $(BUILDER_NAME)

terraform:
	cd terraform; terraform init -upgrade; terraform apply

kube-creds:
	gcloud --project=$(GKE_PROJECT) container clusters get-credentials --region $(GKE_REGION) $(KUBE_CTX)
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
	rsync -av --delete -e 'gcloud compute ssh --project $(GKE_PROJECT) $(BUILDER_NAME) --' conda-recipes/ :$(PWD)/conda-recipes/

conda-fetch:
	rsync -av --delete -e 'gcloud compute ssh --project $(GKE_PROJECT) $(BUILDER_NAME) --' :$(PWD)/conda-bld/linux-64/ $(PWD)/conda-bld/linux-64/

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
