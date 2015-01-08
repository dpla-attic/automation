#!/bin/bash

VERSION=$1

solrversion="solr-$VERSION"
solr_home="/opt/$solrversion"
changed=0

usage() {
    rv=$1
    echo "install_solr.sh <version>"
    exit $rv
}

err_exit() {
    msg=$1
    >&2 echo $msg
    exit 1
}

solr_home_absent() {
    test -d /opt/solr-$VERSION && return 1
    return 0
}

ensure_solr_home_exists() {
    if solr_home_absent; then
        mkdir /opt/solr-$VERSION || exit 1
    fi
}

link_logging_jars() {
    jarpat="log4j-*.jar slf4j-api-*.jar jcl-over-slf4j-*.jar"
    jars=`cd $solr_home/dpla/lib/ext; ls $jarpat`
    for jar in $jars; do
        ln -sf $solr_home/dpla/lib/ext/$jar /usr/share/tomcat7/lib/$jar \
            || err_exit "Could not symlink $jar"
    done
}

test -z "$VERSION" && usage 1

if solr_home_absent; then
    tarfile_name="$solrversion.tgz"
    dl_base="http://mirrors.ibiblio.org/apache/lucene/solr/$VERSION"
    dl_url="$dl_base/$tarfile_name"
    cd /var/tmp
    wget -q $dl_url || err_exit "Could not get $dl_url"
    tar -zxf $tarfile_name || err_exit "Could not extract $tarfile_name"
    ensure_solr_home_exists
    mkdir $solr_home/bin || exit 1
    mkdir $solr_home/lib || exit 1
    mkdir $solr_home/dpla || exit 1
    rsync -a $solrversion/example/ $solr_home/dpla || exit 1
    cp -p $solrversion/dist/$solrversion.war $solr_home/solr.war || exit 1
    link_logging_jars
    cp /var/tmp/$solrversion/contrib/analysis-extras/lucene-libs/*.jar \
        $solr_home/lib || exit 1
    cp /var/tmp/$solrversion/contrib/analysis-extras/lib/*.jar \
        $solr_home/lib || exit 1
    cp /var/tmp/$solrversion/dist/solr-analysis-extras*.jar \
        $solr_home/lib || exit 1
    # The data directory is symlinked to keep Solr happy when it first starts.
    # We'll define it explicitly in solrconfig.xml when that gets copied later.
    ln -sf /v1/solrdata $solr_home/dpla/solr/collection1/data
    rm -rf /var/tmp/solr-$VERSION*
    cd /opt
    ln -sf $solrversion solr || err_exit "Could not symlink solr directory"
    changed=1
fi

if [ $changed -eq 1 ]; then echo "changed"; fi

exit 0

