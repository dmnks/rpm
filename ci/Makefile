ROOT = $(shell git rev-parse --show-toplevel)

all: ci

image:
	podman build -t rpm -f $(PWD)/Dockerfile $(ROOT)
	@touch $@

ci: image
	@podman run -t --rm rpm

check: image
	@podman run -v $(ROOT):/srv/rpm -it --rm rpm make check
