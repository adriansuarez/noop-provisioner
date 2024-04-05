IMAGE?=noop-provisioner

.PHONY: dep
dep:
	go mod tidy

noop-provisioner: dep
	CGO_ENABLED=0 go build -a -o noop-provisioner .

image:
	docker build -t $(IMAGE) -f Dockerfile.scratch .

clean:
	rm -rf noop-provisioner
