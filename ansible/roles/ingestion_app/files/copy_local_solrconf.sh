#!/bin/bash

file_md5() {
    echo `md5sum $1 | cut -d' ' -f1`
}

file=$1
src_dir=/heidrun/solr_conf
dest_dir=/opt/solr/dpla/solr/collection1/conf
srcfile=$src_dir/$file
destfile=$dest_dir/$file

test -z "$file" && exit 1
test -e $src_dir/$file || exit 1

# Skip overwriting the file if it has not changed
if [ -e "$destfile" ]; then
    checksum_src=`file_md5 $srcfile`
    checksum_dest=`file_md5 $destfile`
    if [ $checksum_src == $checksum_dest ]; then
        exit 0
    fi
fi

cp $srcfile $destfile && chown root:root $destfile && chmod 0644 $destfile

echo "changed"
exit 0
