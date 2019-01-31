# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOVET=$(GOCMD) vet
GOFMT=gofmt
GOLINT=golint
BINARY_NAME=user-microservice

all: clean build lint tool test

test:
	$(GOTEST) -v -short ./...

test-integration: 
	export GIN_MODE=release \
	&& $(GOTEST) -v -short ./... -tags=integration

build: deps
	$(GOBUILD) -v .

build-linux: deps
	GOOS=linux $(GOBUILD) -v .

tool:
	$(GOVET) ./...; true
	$(GOFMT) -w .

coverage:
	scripts/coverage.sh

clean:
	go clean -i .
	rm -rf docs
	rm -rf vendor
	rm -f $(BINARY_NAME)

lint:
	$(GOLINT) -set_exit_status $($(GOCMD) list ./... | grep -v /vendor/)

generate-swagger:
	$(GOGET) github.com/swaggo/swag/cmd/swag
	swag init

deps: generate-swagger
	$(GOGET) github.com/golang/dep/cmd/dep
	$(GOGET) golang.org/x/lint/golint
	dep ensure

docker-build: build-linux
	docker build -t $(BINARY_NAME) .

run-as-lambda: build-linux
	sam local start-api

continuous-integration: deps build lint tool test-integration coverage


help:
	@echo "make: compile packages and dependencies"
	@echo "make tool: run specified go tool"
	@echo "make lint: golint ./..."
	@echo "make clean: remove object files and cached files"
	@echo "make deps: get the deployment tools"
	@echo "make coverage: get the coverage of my files"
	@echo "make docker-build: build a docker image and run the container"