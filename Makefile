IMAGE=minrk/simula-summer-school:test

.PHONY: image push

image:
	docker build -t $(IMAGE) image
push:
	docker push $(IMAGE)
