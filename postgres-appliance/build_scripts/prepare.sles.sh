#!/bin/bash

#export DEBIAN_FRONTEND=noninteractive

#echo -e 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend

#apt-get update
zypper refresh -s
#apt-get -y upgrade
zypper -q update -y
#apt-get install -y curl ca-certificates less locales jq vim-tiny gnupg1 cron runit dumb-init libcap2-bin rsync sysstat gpg
zypper -n install curl ca-certificates less glibc-locale glibc-i18ndata gzip jq vim-small cron libcap2 rsync sysstat gpg2 gpgme lsb-release libcap-progs glibc-devel-static
zypper -q -n in -t pattern devel_basis

# runit
#zypper -n --no-gpg-checks install --no-recommends https://download.opensuse.org/repositories/home:/gps4net/15.3/x86_64/runit-2.1.1-lp153.14.1.x86_64.rpm
mkdir /package && cd /package
curl -sO http://smarden.org/runit/runit-2.1.2.tar.gz && tar -xzf runit-2.1.2.tar.gz 
cd admin/runit-2.1.2 && package/compile
cp -v /package/admin/runit-2.1.2/command/* /usr/bin/ && rm -r /package

# dumb-init
#zypper -n --no-gpg-checks install --no-recommends https://download.opensuse.org/repositories/Virtualization:/containers/SLE_12_SP5/x86_64/dumb-init-1.2.2-2.13.x86_64.rpm

# libclang9 

ln -s chpst /usr/bin/envdir

# Make it possible to use the following utilities without root (if container runs without "no-new-privileges:true")
setcap 'cap_sys_nice+ep' /usr/bin/chrt
setcap 'cap_sys_nice+ep' /usr/bin/renice

# Disable unwanted cron jobs
rm -fr /etc/cron.??*
truncate --size 0 /etc/crontab

if [ "$DEMO" != "true" ]; then
    # Required for wal-e
    zypper -n install pv lzop
    # install etcdctl
    ETCDVERSION=3.3.27
    ARCH=$(arch | sed 's/x86_64/amd64/')
    echo "https://github.com/etcd-io/etcd/releases/download/v${ETCDVERSION}/etcd-v${ETCDVERSION}-linux-${ARCH}.tar.gz"
    curl -L https://github.com/etcd-io/etcd/releases/download/v${ETCDVERSION}/etcd-v${ETCDVERSION}-linux-${ARCH}.tar.gz \
    | tar xz -C /bin --strip=1 --wildcards --no-anchored --no-same-owner etcdctl etcd
fi

# Dirty hack for smooth migration of existing dbs
bash /builddeps/locales.sh
mv /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive.22
ln -s /run/locale-archive /usr/lib/locale/locale-archive
ln -s /usr/lib/locale/locale-archive.22 /run/locale-archive

# Add PGDG repositories
#DISTRIB_CODENAME=$(sed -n 's/DISTRIB_CODENAME=//p' /etc/lsb-release)
#for t in deb deb-src; do
#    echo "$t http://apt.postgresql.org/pub/repos/apt/ ${DISTRIB_CODENAME}-pgdg main" >> /etc/apt/sources.list.d/pgdg.list
#done
#curl -s -o - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg

# Clean up
#apt-get purge -y libcap2-bin
#apt-get autoremove -y
#apt-get clean
#rm -rf /var/lib/apt/lists/* \
#            /var/cache/debconf/* \
#            /usr/share/doc \
#            /usr/share/man \
#            /usr/share/locale/?? \
#            /usr/share/locale/??_??
find /var/log -type f -exec truncate --size 0 {} \;
