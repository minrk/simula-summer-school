BASE_IMAGE=jupyter/scipy-notebook:bb222f49222e
IMAGE=minrk/simula-summer-school:test

.PHONY: image push

image:
	docker build -t $(IMAGE) image
push:
	docker push $(IMAGE)

upgrade:
	helm upgrade hub ./helm-chart/jupyterhub -f config.yaml -f secrets.yaml

conda:
	docker run --rm -it $(BASE_IMAGE) -v conda-bld:/opt/conda/conda-bld
