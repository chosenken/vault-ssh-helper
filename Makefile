TEST?=./...
EXTERNAL_TOOLS=\
	github.com/tools/godep \
	github.com/mitchellh/gox \
	golang.org/x/tools/cmd/vet

default: build

# runs the dev target in a docker container.
docker:
	docker run --rm -v "$(PWD)":/go/src/github.com/hashicorp/vault-ssh-helper -w /go/src/github.com/hashicorp/vault-ssh-helper golang make dockerB

dockerB: bootstrap dev

build: generate
	@mkdir -p bin/
	go build -o bin/vault-ssh-helper

# bin generates the releaseable binaries for Vault
bin: generate
	@sh -c "'$(CURDIR)/scripts/build.sh'"

# dev creates binaries for testing Vault locally. These are put
# into ./bin/ as well as $GOPATH/bin
dev: generate
	@TF_DEV=1 sh -c "'$(CURDIR)/scripts/build.sh'"

# test runs the unit tests and vets the code
test: generate
	TF_ACC= godep go test $(TEST) $(TESTARGS) -timeout=30s -parallel=4

# testacc runs acceptance tests
testacc: generate
	@if [ "$(TEST)" = "./..." ]; then \
		echo "ERROR: Set TEST to a specific package"; \
		exit 1; \
	fi
	TF_ACC=1 godep go test $(TEST) -v $(TESTARGS) -timeout 45m

# testrace runs the race checker
testrace: generate
	TF_ACC= godep go test -race $(TEST) $(TESTARGS)

# vet runs the Go source code static analysis tool `vet` to find
# any common errors.
vet:
	@go list -f '{{.Dir}}' ./... \
		| grep -v '.*github.com/hashicorp/vault-ssh-helper$$' \
		| xargs go tool vet ; if [ $$? -eq 1 ]; then \
			echo ""; \
			echo "Vet found suspicious constructs. Please check the reported constructs"; \
			echo "and fix them if necessary before submitting the code for reviewal."; \
		fi

# generate runs `go generate` to build the dynamically generated
# source files.
generate:
	go generate ./...

# bootstrap the build by downloading additional tools
bootstrap:
	@for tool in  $(EXTERNAL_TOOLS) ; do \
		echo "Installing $$tool" ; \
    go get $$tool; \
	done

install: build
	@sudo cp bin/vault-ssh-helper /usr/local/bin


.PHONY: bin build default generate test dev vet bootstrap testacc install
