#!/bin/bash

## export-provider.sh
#
#  Export the DPLA search index to files, per-provider or for all items, and
#  upload these files to an Amazon S3 bucket.
#
#  These files are known as Bulk Download files:
#  http://dp.la/info/developers/download/

SCRIPT=`basename ${BASH_SOURCE[0]}`

which aws > /dev/null && which elasticdump > /dev/null && which jq > /dev/null
if [ $? -ne 0 ]; then
    >&2 echo "\`aws', \`elasticdump', and \`jq' must be available in \$PATH."
    exit 1
fi

# Figure out `sed' options for extended regexes
sed -r 2>/dev/null
if [ $? -eq 0 ]; then
    sed_opts="-r"  # GNU
else
    sed_opts="-E"  # OS X
fi


usage() {
    cat <<END

Usage:  $SCRIPT -u <url> -o <directory> -s <s3 bucket> -p <provider>...

    -u    Elasticsearch URL (including index)
    -o    Output directory
    -s    S3 destination bucket
    -h    Help (this message)
    -p    The name of one provider, or "all" for all of them, or "each"
          for each one (queried from the search index).  "all" and
          "each" can be used together.  Multiple providers may be specified.
          The provider name corresponds to provider.@id in our schema.

END
}

# Generate the Elasticsearch Query API syntax that is used to select which
# records to export
searchbody() {
    if [ "$@" == "all" ]; then
        echo '{"query": {"match_all": {}}}'
    else
        cat <<END
{
    "query": {
        "query_string": {
            "default_field": "provider.@id",
            "query": "*$1"
        }
    }
}
END
    fi
}

# Generate the Elasticsearch Query API syntax that is used to get a list of
# all providers by provider.@id
providers_list_search_body() {
    cat <<END
{
    "query": {
        "match_all": {}
    },
    "facets": {
        "providers": {
            "terms": {
                "field": "provider.@id",
                "size": 500
            }
        }
    },
    "size": 0
}
END
}


providers_list_response() {
    curl -s -X POST "$ES_URL/_search" \
        -d "`providers_list_search_body`"
    if [ $? -ne 0 ]; then
        >&2 echo "Could not query provider listing"
        exit 1
    fi
}

# Given JSON produced by `providers_list_search_body`, return a list of tokens
# that represent the substrings at the end of provider.@id.
# For example, "nypl" for "http://dp.la/api/contributor/nypl"
providers_list() {
    json=`providers_list_response`
    echo $json | jq '.facets.providers.terms[].term' \
        | sed $sed_opts 's/^.*\/([^\/]+)"$/\1/'
}

# Return basename of the output file, which is gzipped JSON
outfile() {
    base=`echo $1 | sed $sed_opts 's/[^A-Za-z]+/_/g;'`
    echo ${base}.json.gz
}

# Export a provider (or "all" providers) and upload the file
export_and_upload() {
    sbody=`searchbody "$@"`
    ofile=`outfile "$@"`
    output="${OUTDIR}/${ofile}"
    elasticdump --searchBody "$sbody" \
        --input=$ES_URL --output=$ | gzip > $output  \
        || exit 1
    bn=`basename $output`
    dir=`date +"%Y/%m"`
    aws s3 cp --quiet  \
        --content-type "application/gzip" --content-encoding "identity" \
        $output s3://$BUCKET/$dir/$bn \
        || exit 1
    rm $output || exit 1
}

declare -a providers
provider_idx=0
# Get options
while getopts :f:u:o:s:p:h flag; do
    case $flag in
        u)
            ES_URL=$OPTARG
            ;;
        o)
            OUTDIR=$OPTARG
            ;;
        s)
            BUCKET=$OPTARG
            ;;
        p)
            providers[$provider_idx]="$OPTARG"
            provider_idx=$(( $provider_idx + 1 ))
            ;;
        h)
            usage
            exit 0
            ;;
        \?)
            usage
            exit 1
            ;;
    esac
    i=$(( $i + 1 ))
done
shift $((OPTIND-1))  # Move to next argument

# Check various arguments
#
if [ "x$ES_URL" == "x" ]; then
    >&2 echo "Unknown Elasticsearch URL"
    usage
    exit 1
fi

if [ "x$OUTDIR" == "x" ]; then
    >&2 echo "Unknown output directory"
    usage
    exit 1
fi
OUTDIR=`echo $OUTDIR | sed 's/\/$//'`

if [ "x$BUCKET" == "x" ]; then
    >&2 echo "Unknown S3 bucket"
    usage
    exit 1
fi

## Export each provider
#
for (( j=0; $j < $provider_idx ; j=$(( j + 1 )) )); do
    if [ "${providers[$j]}" == "each" ]; then
        for provider in `providers_list`; do
            export_and_upload "$provider"
        done
    else
        export_and_upload "${providers[$j]}"
    fi
done

exit 0
