#!/bin/bash

# Runs as the 'postgres' user

outfile=/tmp/tunedb.output

cat /dev/null > $outfile

query() {
    echo "running $1" >> $outfile
    psql -q -c "$1" -d marmotta >> $outfile 2>&1
    if [ $? -ne 0 ]; then
        >&2 echo "Failed to run $1"
        >&2 echo "See $outfile"
        exit 1
    fi
}

set_column_statistics() {
    query "ALTER TABLE $1 ALTER COLUMN $2 SET STATISTICS $3"
}

# create_index_if_absent():
# Check if the given index exists, and create it if it does not.
# Used in lieu of "DROP INDEX IF EXISTS" and re-creating the index,
# because that could take a lot of time for some larger indices and
# should not be done by default every time someone runs this script
# from the playbook.
#
# TODO: A really large index that already exists but needs its parameters
# changed needs some other kind of treatment.  Don't bother with this until
# it becomes an issue.
#
create_index_if_absent() {
    name=$1
    table=$2
    column=$3
    method=${4:-btree}
    extra=$5  # e.g. WHERE clause
    q="SELECT count(*) FROM pg_indexes WHERE indexname = '$name'"
    echo "running $q" >> $outfile
    psql_out=`psql -t -q -c "$q" -d marmotta`  # note -t
    if [ $? -ne 0 ]; then
        >&2 echo "Failed to run $q"
        exit 1
    fi
    count=`echo "$psql_out" | awk '{$1=$1}{ print }'`
    if [ "$count" == "0" ]; then
        query "CREATE INDEX $name ON $table USING $method ($column) $extra"
    fi
}

set_column_statistics triples context 5000
set_column_statistics triples subject 5000
set_column_statistics triples predicate 300
set_column_statistics triples object 500

# FIXME:  this is not one-size-fits-all.  The tablespace names
# need to be gathered and iterated over.
query 'ALTER TABLESPACE marmotta_1 SET (seq_page_cost = 2)'

create_index_if_absent idx_triples_c triples context
