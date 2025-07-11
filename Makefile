
APP=$(shell basename $(shell git remote get-url origin))
REGISTRY=ghcr.io/sakharuk
VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)

UNAME_S := $(shell uname -s 2>NUL || echo Windows_NT)
UNAME_M := $(shell uname -m 2>NUL || echo $(PROCESSOR_ARCHITECTURE))

ifeq ($(UNAME_S),Linux)
  TARGETOS := linux
else ifeq ($(UNAME_S),Darwin)
  TARGETOS := darwin
else ifeq ($(UNAME_S),Windows_NT)
  TARGETOS := windows
else
  TARGETOS := windows
endif

ifeq ($(UNAME_M),x86_64)
  TARGETARCH := amd64
else ifeq ($(UNAME_M),AMD64)
  TARGETARCH := amd64
else ifeq ($(UNAME_M),aarch64)
  TARGETARCH := arm64
else ifeq ($(UNAME_M),arm64)
  TARGETARCH := arm64
else
  TARGETARCH := amd64
endif

format:
	gofmt -s -w ./

lint:
	golint

test:
	go test -v

get: 
	go get

build: format get
	CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -v -o kbot -ldflags "-X="github.com/Sakharuk/kbot/cmd.appVersion=${VERSION}

linux:
	TARGETOS=linux TARGETARCH=amd64 $(MAKE) build

linux-arm:
	TARGETOS=linux TARGETARCH=arm64 $(MAKE) build

macos:
	TARGETOS=darwin TARGETARCH=amd64 $(MAKE) build

macos-arm:
	TARGETOS=darwin TARGETARCH=arm64 $(MAKE) build

windows:
	TARGETOS=windows TARGETARCH=amd64 $(MAKE) build

windows-arm:
	TARGETOS=windows TARGETARCH=arm64 $(MAKE) build

image: 	
	docker build --platform ${TARGETOS}/${TARGETARCH} -t ${REGISTRY}/${APP}:${VERSION}-${TARGETOS}-${TARGETARCH} . 
push:
	docker push ${REGISTRY}/${APP}:${VERSION}-${TARGETOS}-${TARGETARCH}

clean:
	rm -rf kbot
	docker rmi ${REGISTRY}/${APP}:${VERSION}-${TARGETOS}-${TARGETARCH}