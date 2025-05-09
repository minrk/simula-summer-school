# simula summer school deployment

deployment config for simula SUURPh summer school at simula

Setup gcloud cli

enable APIs:

- artifact registry
- kubernetes engine

update image: use `pixi` commands in `image` (e.g. editing pixi.toml, `pixi update --no-install`)

build image:

```
make builder-firewall-rule
make builder-new
eval $(make builder-env)
make image
make push
```
