#!/bin/bash

# Runs as the 'postgres' user

outfile=/tmp/tunedb.output

cat /dev/null > $outfile

query() {
    psql -q -c "$1" -d marmotta >> $outfile 2>&1
    if [ $? -ne 0 ]; then
        >&2 echo "Failed to run $1"
        >&2 echo "See $outfile"
        exit 1
    fi
}

query 'ALTER TABLE triples ALTER COLUMN context SET STATISTICS 5000'
query 'ALTER TABLE triples ALTER COLUMN subject SET STATISTICS 300'
query 'ALTER TABLE triples ALTER COLUMN predicate SET STATISTICS 300'
query 'ALTER TABLE triples ALTER COLUMN object SET STATISTICS 300'
query 'ALTER TABLESPACE marmotta_1 SET (seq_page_cost = 2)'
