#!/bin/bash

## -------------------------------------------
## Install PostgreSQL, extensions and contribs
## -------------------------------------------

#export DEBIAN_FRONTEND=noninteractive
MAKEFLAGS="-j $(grep -c ^processor /proc/cpuinfo)"
export MAKEFLAGS

set -ex

#apt-get update
#zypper -n addrepo https://download.postgresql.org/pub/repos/zypp/repo/pgdg-sles-15-pg15.repo
#zypper -n addrepo https://download.postgresql.org/pub/repos/zypp/repo/pgdg-sles-15-pg14.repo
#zypper -n addrepo https://download.postgresql.org/pub/repos/zypp/repo/pgdg-sles-15-pg13.repo
#zypper -n addrepo https://download.postgresql.org/pub/repos/zypp/repo/pgdg-sles-15-pg12.repo
zypper -n addrepo "https://download.postgresql.org/pub/repos/zypp/repo/pgdg-sles-15-pg$PGVERSION.repo"
zypper --gpg-auto-import-keys refresh -s
zypper update -y

#BUILD_PACKAGES=(devscripts equivs build-essential fakeroot debhelper git gcc libc6-dev make cmake libevent-dev libbrotli-dev libssl-dev libkrb5-dev)
#BUILD_PACKAGES=(gcc git krb5-devel libbrotli-devel libevent-devel libopenssl-devel cmake fakeroot debhelper awk) 
# following 2 need to be installed separately to avoid to be removed L:101
# libbrotli-devel libevent-devel 
BUILD_PACKAGES=(gcc git krb5-devel libopenssl-devel cmake fakeroot debhelper awk) 
if [ "$DEMO" = "true" ]; then
    export PG_SUPPORTED_VERSIONS="$PGVERSION"
    WITH_PERL=false
    rm -f ./*.deb

    #apt-get install -y "${BUILD_PACKAGES[@]}"
    zypper -n -q install "${BUILD_PACKAGES[@]}"
else
    #BUILD_PACKAGES+=(zlib1g-dev
    #                libprotobuf-c-dev
    #                libpam0g-dev
    #                libcurl4-openssl-dev
    #                libicu-dev
    #                libc-ares-dev
    #                pandoc
    #                pkg-config)
    BUILD_PACKAGES+=(libprotobuf-c-devel 
                    pam-devel 
                    libcurl-devel 
                    libicu-devel 
                    c-ares-devel 
                    pandoc)
    #apt-get install -y "${BUILD_PACKAGES[@]}" libcurl4
    zypper -n -q install "${BUILD_PACKAGES[@]}"

    # install pam_oauth2.so
    git clone -b "$PAM_OAUTH2" --recurse-submodules https://github.com/zalando-pg/pam-oauth2.git
    make -C pam-oauth2 install
    
    # prepare 3rd sources
    git clone -b "$PLPROFILER" https://github.com/bigsql/plprofiler.git
    tar -xzf "plantuner-${PLANTUNER_COMMIT}.tar.gz"
    curl -sL "https://github.com/zalando-pg/pg_mon/archive/$PG_MON_COMMIT.tar.gz" | tar xz
    
    #for p in python3-keyring python3-docutils ieee-data; do
    #    version=$(apt-cache show $p | sed -n 's/^Version: //p' | sort -rV | head -n 1)
    #    printf "Section: misc\nPriority: optional\nStandards-Version: 3.9.8\nPackage: %s\nVersion: %s\nDescription: %s" "$p" "$version" "$p" > "$p"
    #    equivs-build "$p"
    #done

    zypper -n -q install python3-keyring python3-docutils

    # install from the repo https://salsa.debian.org/debian/ieee-data
    git clone -b "debian/20220827.1" https://salsa.debian.org/debian/ieee-data.git
    mkdir -p /usr/share/ieee-data 
    make -C ieee-data/ install

fi

#if [ "$WITH_PERL" != "true" ]; then
    #version=$(apt-cache show perl | sed -n 's/^Version: //p' | sort -rV | head -n 1)
    #printf "Priority: standard\nStandards-Version: 3.9.8\nPackage: perl\nMulti-Arch: allowed\nReplaces: perl-base, perl-modules\nVersion: %s\nDescription: perl" "$version" > perl
    #equivs-build perl
#fi

curl -sL "https://github.com/zalando-pg/bg_mon/archive/$BG_MON_COMMIT.tar.gz" | tar xz
curl -sL "https://github.com/zalando-pg/pg_auth_mon/archive/$PG_AUTH_MON_COMMIT.tar.gz" | tar xz
curl -sL "https://github.com/cybertec-postgresql/pg_permissions/archive/$PG_PERMISSIONS_COMMIT.tar.gz" | tar xz
curl -sL "https://github.com/hughcapet/pg_tm_aux/archive/$PG_TM_AUX_COMMIT.tar.gz" | tar xz
curl -sL "https://github.com/zubkov-andrei/pg_profile/archive/$PG_PROFILE.tar.gz" | tar xz
git clone -b "$SET_USER" https://github.com/pgaudit/set_user.git
git clone https://github.com/timescale/timescaledb.git
git clone https://github.com/dimitri/pgextwlist.git
git clone --recurse-submodules https://github.com/pgq/pgqd.git

#apt-get install -y \
#    postgresql-common \
#    libevent-2.1 \
#    libevent-pthreads-2.1 \
#    brotli \
#    libbrotli1 \
#    python3.10 \
#    python3-psycopg2
#    
zypper -n -q install -r SLE_BCI \
    libevent-2_1-8 \
    libevent-devel \
    brotli \
    libbrotli-devel

zypper -n -q install python3-psycopg2

#     libpq5 libpq5-devel \

# forbid creation of a main cluster when package is installed
#sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf

for version in $PG_SUPPORTED_VERSIONS; do
    #sed -i "s/ main.*$/ main $version/g" /etc/apt/sources.list.d/pgdg.list
    #apt-get update

    if [ "$DEMO" != "true" ]; then
        #EXTRAS=(+"postgresql-pltcl-${version}"
        #        "postgresql-${version}-dirtyread"
        #       +"postgresql-${version}-extra-window-functions"
        #        "postgresql-${version}-first-last-agg"
        #        "postgresql-${version}-hll"
        #       +"postgresql-${version}-hypopg"
        #       +"postgresql-${version}-plproxy"
        #       +"postgresql-${version}-partman"
        #       +"postgresql-${version}-pgaudit"
        #       +"postgresql-${version}-pldebugger"
        #       +"postgresql-${version}-pglogical"
        #        "postgresql-${version}-pglogical-ticker"
        #       +"postgresql-${version}-plpgsql-check"
        #       +"postgresql-${version}-pg-checksums"
        #        "postgresql-${version}-pgl-ddl-deploy"
        #        "postgresql-${version}-pgq-node"
        #       +"postgresql-${version}-postgis-${POSTGIS_VERSION%.*}"
        #       +"postgresql-${version}-postgis-${POSTGIS_VERSION%.*}-scripts"
        #       +"postgresql-${version}-repack"
        #       +"postgresql-${version}-wal2json")

        # zypper se -s hll
        #S | Name   | Type    | Version       | Arch   | Repository
        #--+--------+---------+---------------+--------+---------------------------------
        #  | hll_12 | package | 2.14-1.sles15 | x86_64 | PostgreSQL 12 SLES 15.4 - x86_64
        #  | hll_14 | package | 2.16-1.sles15 | x86_64 | PostgreSQL 14 SLES 15.4 - x86_64

        # zypper in  postgis33_15
        ## Problem: nothing provides 'hdf5' needed by the to be installed postgis33_15-3.3.2-3.sles15.x86_64
        ## Problem: nothing provides 'libxerces-c-3_1' needed by the to be installed postgis33_15-3.3.2-3.sles15.x86_64

        EXTRAS=("postgresql${version}-pltcl"
                "extra_window_functions_${version}"
                "hypopg_${version}"
                "plproxy_${version}"
                "pg_partman_${version}"
                "pldebugger_${version}"
                "pglogical_${version}"
                "plpgsql_check_${version}"
                "pg_checksums_${version}"
                "pg_repack_${version}"
                "wal2json_${version}"
                )
#                "postgis32_${version}"
#                "postgis32_${version}-utils"
        
        EXTRAS+=("pgaudit$((version+2))_${version}"
                "pgauditlogtofile_${version}")

        #if [ "$version" != "15" ]; then
        #    # not yet present for pg15
        #    EXTRAS+=("postgresql-${version}-pllua")
        #fi

        if [ "$WITH_PERL" = "true" ]; then
            EXTRAS+=("postgresql${version}-plperl")
        fi

        #if [ "${version%.*}" -ge 10 ]; then
        #    EXTRAS+=("postgresql-${version}-decoderbufs")
        #fi

        #if [ "${version%.*}" -lt 11 ]; then
        #    EXTRAS+=("postgresql-${version}-amcheck")
        #fi
    fi

    # Install PostgreSQL binaries, contrib, plproxy and multiple pl's
    
    #apt-get install --allow-downgrades -y \
    #    "postgresql-${version}-cron" \
    #    "postgresql${version}-contrib" \
    #    "postgresql-${version}-pgextwlist" \
    #    "postgresql${version}-plpython3" \
    #    "postgresql-server-dev-${version}" \
    #    "postgresql-${version}-pgq3" \
    #    "postgresql-${version}-pg-stat-kcache" \
    #    "${EXTRAS[@]}"

    zypper -n install \
        "pgdg-${version}:postgresql${version}" \
        "pgdg-${version}:postgresql${version}-server" \
        "pgdg-${version}:postgresql${version}-contrib" \
        "pgdg-${version}:postgresql${version}-devel" \
        "pgdg-${version}:postgresql${version}-plpython3" \
        "pgdg-${version}:pg_cron_${version}" \
        "pgdg-${version}:pg_stat_kcache_${version}" \
        "pgdg-${version}:pgq_${version}" \
        "${EXTRAS[@]}"
    
    # Install 3rd party stuff

    # don't try to build   for pg15. Remove, when it is officially supported.
    #>if [ "$version" != "15" ]; then
    #>    # use subshell to avoid having to cd back (SC2103)
    #>    (
    #>        cd timescaledb
    #>        for v in $TIMESCALEDB; do
    #>            git checkout "$v"
    #>            sed -i "s/VERSION 3.11/VERSION 3.10/" CMakeLists.txt
    #>            if BUILD_FORCE_REMOVE=true ./bootstrap -DREGRESS_CHECKS=OFF -DWARNINGS_AS_ERRORS=OFF \
    #>                    -DTAP_CHECKS=OFF -DPG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config" \
    #>                    -DAPACHE_ONLY="$TIMESCALEDB_APACHE_ONLY" -DSEND_TELEMETRY_DEFAULT=NO; then
    #>                make -C build install
    #>                strip /usr/lib/postgresql/"$version"/lib/timescaledb*.so
    #>            fi
    #>            git reset --hard
    #>            git clean -f -d
    #>        done
    #>    )
    #>fi
    zypper -n install \
            "pgdg-${version}:timescaledb_${version}" \

    # https://github.com/timescale/timescaledb-toolkit
    #if [ "${TIMESCALEDB_APACHE_ONLY}" != "true" ] && [ "${TIMESCALEDB_TOOLKIT}" = "true" ]; then
    #    __versionCodename=$(sed </etc/os-release -ne 's/^VERSION_CODENAME=//p')
    #    echo "deb [signed-by=/usr/share/keyrings/timescale_E7391C94080429FF.gpg] https://packagecloud.io/timescale/timescaledb/ubuntu/ ${__versionCodename} main" | tee /etc/apt/sources.list.d/timescaledb.list
    #    curl -L https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor > /usr/share/keyrings/timescale_E7391C94080429FF.gpg
#
    #    apt-get update
    #    if [ "$(apt-cache search --names-only "^timescaledb-toolkit-postgresql-${version}$" | wc -l)" -eq 1 ]; then
    #        apt-get install "timescaledb-toolkit-postgresql-$version"
    #    else
    #        echo "Skipping timescaledb-toolkit-postgresql-$version as it's not found in the repository"
    #    fi
#
    #    rm /etc/apt/sources.list.d/timescaledb.list
    #    rm /usr/share/keyrings/timescale_E7391C94080429FF.gpg
    #fi

    if [ "$DEMO" != "true" ]; then
        #EXTRA_EXTENSIONS=("plantuner-${PLANTUNER_COMMIT}" plprofiler)
        if [ "${version%.*}" -ge 10 ]; then
            EXTRA_EXTENSIONS+=("pg_mon-${PG_MON_COMMIT}")
        fi
    else
        EXTRA_EXTENSIONS=()
    fi
    
    #zypper -n in -r pgdg-${version} -f libpq5-devel-15.2-42.1PGDG.sles15.x86_64 libpq5-15.2-42.1PGDG.sles15
    zypper -n in -r pgdg-${version} -f libpq5-devel libpq5

    for n in bg_mon-${BG_MON_COMMIT} \
            pg_auth_mon-${PG_AUTH_MON_COMMIT} \
            set_user \
            pg_permissions-${PG_PERMISSIONS_COMMIT} \
            pg_tm_aux-${PG_TM_AUX_COMMIT} \
            pg_profile-${PG_PROFILE} \
            pgextwlist \
            "${EXTRA_EXTENSIONS[@]}"; do
        #make -C "$n" USE_PGXS=1 clean install-strip
        make PG_CONFIG=/usr/pgsql-${version}/bin/pg_config -C "$n" USE_PGXS=1 clean install-strip
    done
done

# pgqd
make -C ./pgqd configure
(cd ./pgqd && ./configure -q --prefix=/usr)
make -C ./pgqd PG_CONFIG=/usr/pgsql-$PGVERSION/bin/pg_config install

#apt-get install -y skytools3-ticker pgbouncer

#zypper -n in pgbouncer
##Checking for file conflicts: [....done]
##(1/2) Installing: systemd-sysvinit-249.15-150400.8.22.1.x86_64 [..........done]
##(2/2) Installing: pgbouncer-1.18.0-11.sles15.x86_64 [............
##System has not been booted with systemd as init system (PID 1). Can't operate.
##Failed to connect to bus: Host is down
##done]

#sed -i "s/ main.*$/ main/g" /etc/apt/sources.list.d/pgdg.list
#apt-get update
#apt-get install -y postgresql postgresql-server-dev-all postgresql-all libpq-dev
#for version in $PG_SUPPORTED_VERSIONS; do
#    apt-get install -y "postgresql-server-dev-${version}"
#done

#if [ "$DEMO" != "true" ]; then
#    for version in $PG_SUPPORTED_VERSIONS; do
#        # create postgis symlinks to make it possible to perform update
#        ln -s "postgis-${POSTGIS_VERSION%.*}.so" "/usr/lib/pgsql-${version}/lib/postgis-2.5.so"
#    done
#fi

# make it possible for cron to work without root
gcc -s -shared -fPIC -o /usr/local/lib/cron_unprivileged.so cron_unprivileged.c

#apt-get purge -y "${BUILD_PACKAGES[@]}"
zypper -q -n remove --clean-deps "${BUILD_PACKAGES[@]}"
#apt-get autoremove -y

#if [ "$WITH_PERL" != "true" ] || [ "$DEMO" != "true" ]; then
#    dpkg -i ./*.deb || apt-get -y -f install
#fi

# Remove unnecessary packages
#apt-get purge -y \
#                libdpkg-perl \
#                libperl5.* \
#                perl-modules-5.* \
#                postgresql \
#                postgresql-all \
#                postgresql-server-dev-* \
#                libpq-dev=* \
#                libmagic1 \
#                bsdmainutils

#zypper -n remove libmagic1 
#(8/9) Removing rpm-config-SUSE-1-150400.14.3.1.noarch [..error]                                                                                                                               
#Abort, retry, ignore? [a/r/i] (a): a                                                                                                                                                          
#Removal of (224)rpm-config-SUSE-1-150400.14.3.1.noarch(@System) failed:                                                                                                                       
#Error: Subprocess failed. Error: RPM failed: Command exited with status 129.                                                                                                                  
#Problem occurred during or after installation or removal of packages:                                                                                                                         
#Installation has been aborted as directed.                                                                                                                                                    
#Please see the above error message for a hint.

zypper -q -n remove -r pgdg-${version} libpq5-devel libpq5
#apt-get autoremove -y
#apt-get clean
zypper -q clean -a

#dpkg -l | grep '^rc' | awk '{print $2}' | xargs apt-get purge -y

## Try to minimize size by creating symlinks instead of duplicate files
#if [ "$DEMO" != "true" ]; then
#    cd "/usr/lib/postgresql/$PGVERSION/bin"
#    for u in clusterdb \
#            pg_archivecleanup \
#            pg_basebackup \
#            pg_isready \
#            pg_recvlogical \
#            pg_test_fsync \
#            pg_test_timing \
#            pgbench \
#            reindexdb \
#            vacuumlo *.py; do
#        for v in /usr/lib/postgresql/*; do
#            if [ "$v" != "/usr/lib/postgresql/$PGVERSION" ] && [ -f "$v/bin/$u" ]; then
#                rm "$v/bin/$u"
#                ln -s "../../$PGVERSION/bin/$u" "$v/bin/$u"
#            fi
#        done
#    done
#
#    set +x
#
#    for v1 in $(find /usr/share/postgresql -type d -mindepth 1 -maxdepth 1 | sort -Vr); do
#        # relink files with the same content
#        cd "$v1/extension"
#        while IFS= read -r -d '' orig
#        do
#            for f in "${orig%.sql}"--*.sql; do
#                if [ ! -L "$f" ] && diff "$orig" "$f" > /dev/null; then
#                    echo "creating symlink $f -> $orig"
#                    rm "$f" && ln -s "$orig" "$f"
#                fi
#            done
#        done <  <(find . -type f -maxdepth 1 -name '*.sql' -not -name '*--*')
#
#        for e in pgq pgq_node plproxy address_standardizer address_standardizer_data_us; do
#            orig=$(basename "$(find . -maxdepth 1 -type f -name "$e--*--*.sql" | head -n1)")
#            if [ "x$orig" != "x" ]; then
#                for f in "$e"--*--*.sql; do
#                    if [ "$f" != "$orig" ] && [ ! -L "$f" ] && diff "$f" "$orig" > /dev/null; then
#                        echo "creating symlink $f -> $orig"
#                        rm "$f" && ln -s "$orig" "$f"
#                    fi
#                done
#            fi
#        done
#
#        # relink files with the same name and content across different major versions
#        started=0
#        for v2 in $(find /usr/share/postgresql -type d -mindepth 1 -maxdepth 1 | sort -Vr); do
#            if [ "${v2##*/}" = "15" ]; then
#                continue
#            fi
#            if [ "$v1" = "$v2" ]; then
#                started=1
#            elif [ $started = 1 ]; then
#                for d1 in extension contrib contrib/postgis-$POSTGIS_VERSION; do
#                    cd "$v1/$d1"
#                    d2="$d1"
#                    d1="../../${v1##*/}/$d1"
#                    if [ "${d2%-*}" = "contrib/postgis" ]; then
#                        if [ "${v2##*/}" = "10" ]; then d2="${d2%-*}-$POSTGIS_LEGACY"; fi
#                        d1="../$d1"
#                    fi
#                    d2="$v2/$d2"
#                    for f in *.html *.sql *.control *.pl; do
#                        if [ -f "$d2/$f" ] && [ ! -L "$d2/$f" ] && diff "$d2/$f" "$f" > /dev/null; then
#                            echo "creating symlink $d2/$f -> $d1/$f"
#                            rm "$d2/$f" && ln -s "$d1/$f" "$d2/$f"
#                        fi
#                    done
#                done
#            fi
#        done
#    done
#    set -x
#fi

## Clean up
#rm -rf /var/lib/apt/lists/* \
#        /var/cache/debconf/* \
#        /builddeps \
#        /usr/share/doc \
#        /usr/share/man \
#        /usr/share/info \
#        /usr/share/locale/?? \
#        /usr/share/locale/??_?? \
#        /usr/share/postgresql/*/man \
#        /etc/pgbouncer/* \
#        /usr/lib/postgresql/*/bin/createdb \
#        /usr/lib/postgresql/*/bin/createlang \
#        /usr/lib/postgresql/*/bin/createuser \
#        /usr/lib/postgresql/*/bin/dropdb \
#        /usr/lib/postgresql/*/bin/droplang \
#        /usr/lib/postgresql/*/bin/dropuser \
#        /usr/lib/postgresql/*/bin/pg_standby \
#        /usr/lib/postgresql/*/bin/pltcl_*
rm -rf /var/cache/zypp/ \
    /builddeps \
    /usr/share/doc \
    /usr/share/man \
    /usr/share/info \
    /usr/share/locale/?? \
    /usr/share/locale/??_?? 

find /var/log -type f -exec truncate --size 0 {} \;
