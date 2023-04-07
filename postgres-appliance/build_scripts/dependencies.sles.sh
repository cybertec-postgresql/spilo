
#!/bin/bash

## ------------------
## Dependencies magic
## ------------------

set -ex

# should exist when $DEMO=TRUE to avoid 'COPY --from=dependencies-builder /builddeps/wal-g ...' failure

if [ "$DEMO" = "true" ]; then
    mkdir /builddeps/wal-g
    exit 0
fi

MAKEFLAGS="-j $(grep -c ^processor /proc/cpuinfo)"
export MAKEFLAGS

#GO_VERSION="go1.20.linux-amd64.tar.gz"
#export GO_VERSION

ARCH="$(arch)"

zypper -q ref -s
zypper -q update -y

# 'curl' is already installed.
# No update candidate for 'curl-7.79.1-150400.5.15.1.x86_64'. The highest available version is already installed.
# 'ca-certificates' is already installed.
# No update candidate for 'ca-certificates-2+git20210309.21162a6-2.1.noarch'. The highest available version is already installed.
zypper -q -n in curl ca-certificates gzip tar git cmake gawk lzo-devel libsodium-devel 
zypper -q -n in -t pattern devel_basis 

# removed when use 
# FROM registry.suse.com/bci/golang:1.19
# insted of 
# FROM $BASE_IMAGE as dependencies-builder
# ˇˇˇ
# install go
#curl -L -O https://go.dev/dl/$GO_VERSION
#rm -rf /usr/local/go && tar -C /usr/local -xzf $GO_VERSION
#export PATH=$PATH:/usr/local/go/bin
#go version

export WALG_VERSION=v2.0.1

git clone -b "$WALG_VERSION" --recurse-submodules https://github.com/wal-g/wal-g.git
cd /wal-g

# fix for following 
#go: warning: github.com/Azure/go-autorest/autorest/adal@v0.9.14: retracted by module author: retracted due to token refresh errors
#go: to switch to the latest unretracted version, run:
#        go get github.com/Azure/go-autorest/autorest/adal@latest
go get -v -u github.com/Azure/go-autorest/autorest/adal@latest

go get -v -t -d ./...
go mod vendor

bash link_brotli.sh
bash link_libsodium.sh

export USE_LIBSODIUM=1
export USE_LZO=1
make pg_build

# remove
# libgdal30_3.4.1+dfsg-1build4_amd64.deb
# libgdal30_3.4.1+dfsg-1build4_arm64.deb
printf 'shopt -s extglob\nrm /builddeps/!(*_%s.deb)' "$ARCH" | bash -s
# this should be updated to remove rpm as well if rpms are added

mkdir /builddeps/wal-g

cp /wal-g/main/pg/wal-g /builddeps/wal-g/

