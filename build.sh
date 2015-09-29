#!/bin/bash

docker run --rm -v "$PWD":/go/src/github.com/hashicorp/vault-ssh-helper -w /go/src/github.com/hashicorp/vault-ssh-helper golang make docker
