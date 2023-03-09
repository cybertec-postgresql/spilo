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

export DEBIAN_FRONTEND=noninteractive
MAKEFLAGS="-j $(grep -c ^processor /proc/cpuinfo)"
export MAKEFLAGS
ARCH="$(zypper)"

echo -e 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend

zypper update
zypper install -y curl ca-certificates

zypper install -y software-properties-common gpg-agent
add-apt-repository ppa:longsleep/golang-backports
zypper update
zypper install -y golang-go liblzo2-devel brotli libsodium-devel git make cmake gcc libc-devel
go version

git clone -b "$WALG_VERSION" --recurse-submodules https://github.com/wal-g/wal-g.git
cd /wal-g
go get -v -t -d ./...
go mod vendor

bash link_brotli.sh
bash link_libsodium.sh

export USE_LIBSODIUM=1
export USE_LZO=1
make pg_build

# We want to remove all libgdal30 debs except one that is for current architecture.
#printf "shopt -s extglob\nrm /builddeps/!(*_%s.deb)" "$ARCH" | bash -s

mkdir /builddeps/wal-g

cp /wal-g/main/pg/wal-g /builddeps/wal-g/
