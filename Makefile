OUT_DIR := out
PROG := docker-machine-driver-outscale

GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)

export GO111MODULE=on

ifeq ($(GOOS),windows)
	BIN_SUFFIX := ".exe"
endif

.PHONY: build
build: dep
	go build -ldflags "-X github.com/jerome.jutteau/docker-machine-driver-outscale/pkg/drivers/outscale.VERSION=`git describe --always`" -o $(OUT_DIR)/$(PROG)$(BIN_SUFFIX) ./

.PHONY: dep
dep:
	@GO111MODULE=on
	go get -d ./
	go mod verify

.PHONY: reuse
reuse:
	docker run --rm --volume $(pwd):/data fsfe/reuse:0.11.1 lint

.PHONY: test
test: dep reuse
	go test -race ./...

.PHONY: check
check:
	gofmt -l -s -d pkg/
	go vet

.PHONY: clean
clean:
	$(RM) $(OUT_DIR)/$(PROG)$(BIN_SUFFIX)

.PHONY: uninstall
uninstall:
	$(RM) $(GOPATH)/bin/$(PROG)$(BIN_SUFFIX)

.PHONY: install
install: build
	go install
