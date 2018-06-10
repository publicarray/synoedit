#!/bin/sh

set -u

gofmt -s -w -- package/src/*.go
go build -ldflags "-s -w" -o package/ui/index.cgi -- package/src/*.go

