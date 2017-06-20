BASE_IMAGE=jupyter/scipy-notebook:bb222f49222e
IMAGE=minrk/simula-summer-school:2017

.PHONY: image push

image:
	docker build -t $(IMAGE) image
push:
	docker push $(IMAGE)

upgrade:
	helm upgrade hub ./helm-chart/jupyterhub -f config.yaml -f secrets.yaml

conda:
	docker build -t conda-pkgs conda-recipes

run:
	docker run -it --rm -p9999:8888 $(IMAGE) jupyter notebook
