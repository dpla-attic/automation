#!/usr/bin/env bash
#
# NAME
#   backup_couchdb_file.sh - End Point script to backup CouchDB to a file
#
# SYNOPSIS
#   backup_couchdb_file.sh
#        [ <options> ]
#        <dbName>
#
# DESCRIPTION
#    <hostName>
#      Specify target CouchDB host to connect to
#    <dbName>
#      Specify target CouchDB DB to be backed up
#    -c <httpPath>
#      HTTP call path used to connect to CouchDB to backup the DB
#      Default: '_all_docs'
#    -a <httpArguments>
#      HTTP arguments used to connect to CouchDB to backup the DB
#      Default: (none)
#    -p <httpPort>
#      Port used to connect to CouchDB to backup the DB
#      Default: '5984'
#    -o <outputFile>
#      Target file which will contain the DB dump (in JSON)
#      if not specified defaults to ./dbName_yyyy_mm_dd.json
#    -m <[curl|wget|auto]>
#      Specify which method should be used to download the DB dump
#      default to auto which checks for curl and then wget .. or fails
#    -l [<maxNumberOfResults>]
#      Specify the maximum number of results which CouchDB should give back
#      Default: (no limit)
#    -f
#      Force backup even when not needed as there are no changes from last backup
#    -q
#      Avoid printing any (non-debug) statement
#    -d
#      Enable debug statements
#    -h
#      Output this help text
#
# EXAMPLES
#    [.. TODO ..]
#


###############################################################################
# last blank line is used to determine end of documentation
###############################################################################
set -o errexit -o nounset -o pipefail

# Defaults
PATH=$PATH:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin
debug=""
quiet=""
verbose=""
force=""
cmdname="$(basename -- $0)"
directory="$(dirname -- "$0")"

httpMethod="auto"
dbName=""
hostName=""
outputFile=""
httpPath="_all_docs"
httpPort="5984"
httpArguments="include_docs=true"
couchDBlimit=""

curl_bin=""
wget_bin=""

# Standard exit error codes
EX_CRITICAL="2"
EX_WARNING="1"
EX_OK="0"
EX_UNKNOWN="$EX_CRITICAL"
# helper methods
# Exit codes from /usr/include/sysexits.h, as recommended by
# http://www.faqs.org/docs/abs/HTML/exitcodes.html
EX_USAGE="64"

error()
{
  # Output error messages with optional exit code
  # @param $1...: Messages
  # @param $N: Exit code (optional)

  local -a messages=( "$@" )

  # If the last parameter is a number, it's not part of the messages
  local -r last_parameter="${@: -1}"
  if [[ "$last_parameter" =~ ^[0-9]*$ ]]
  then
    local -r exit_code="$last_parameter"
    unset messages[$((${#messages[@]} - 1))]
  fi

  echo "${messages[@]}"

  exit "${exit_code:-$EX_UNKNOWN}"
}

outputDebug()
{
  # outputdebug statement
  # @param $1: debug statement text (mandatory)
  # @param $2: debug status value (mandatory)
  local message=("${1}")
  local debug=("${2}")
  local timestamp="$(date +%d-%m-%Y_%T_\(%z\))"

  if [[ -n "$debug" && "$debug" == 'true' ]]
  then
    echo "$timestamp : $message"
  fi
}

usage()
{
  # Print documentation until the first empty line
  # @param $1: Exit code (optional)
  local line
  while IFS= read line
  do
    if [ -z "$line" ]
    then
        exit "${1:-0}"
    elif [ "${line:0:2}" == '#!' ]
    then
        # Shebang line
        continue
    fi
    echo "${line:2}" # Remove comment characters
  done < "$0"
}

isIP()
{
  local isIPHostname="${1}"
  local isIP="$(echo $isIPHostname | awk '/^\s*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\s*$/ { print }')"
  if [[ -n "$isIP" ]]
  then
    echo "$isIP"
  else
    echo ""
  fi
}

################
#   main code  #
################
while getopts "c:p:m:o:l:a:qdvhf" params
do
  case "$params" in
    c)
      httpPath="$OPTARG"
      ;;
    p)
      httpPort="$OPTARG"
      ;;
    a)
      httpArguments="$OPTARG"
      ;;
    m)
      httpMethod="$OPTARG"
      if [[ "$httpMethod" != 'curl' && \
            "$httpMethod" != 'wget' && \
            "$httpMethod" != 'auto' ]]
      then
        error "HTTP method specified can be curl, wget or auto" "$EX_USAGE"
      fi
      ;;
    o)
      outputFile="$OPTARG"
      ;;
    l)
      couchDBlimit="$OPTARG"
      ;;
    q)
      quiet="true"
      verbose=""
      ;;
    d)
      debug="true"
      ;;
    f)
      force="true"
      ;;
    v)
      verbose="true"
      quiet=""
      ;;
    h)
      usage
      exit "$EX_OK"
      ;;
    *)
      usage
      exit "$EX_USAGE"
      ;;
  esac
done
hostName="${@:$OPTIND:1}" # used to parse positional parameter
dbName="${@:$OPTIND+1:1}" # used to parse positional parameter
if [[ -z "$outputFile" ]]
then
  outputFile="./${dbName}_$(date +%Y_%m_%d).json"
fi

outputDebug 'Debug activated' "$debug"

outputDebug "| debug -> $debug | verbose -> $verbose | quiet -> $quiet |" \
  "$debug"

if [[ -z "$hostName" ]]
then
  error "hostName mandatory, please specify the Couchhost host to backup" "$EX_USAGE"
fi
outputDebug "hostName is $hostName" "$debug"

if [[ -z "$dbName" ]]
then
  error "dbName mandatory, please specify the CouchDB DB to backup" "$EX_USAGE"
fi
outputDebug "dbName is $dbName" "$debug"

outputDebug "Specified httpMethod is $httpMethod" "$debug"
outputDebug "outputFile is $outputFile" "$debug"

if [[ -n "$couchDBlimit" ]]
then
  httpArguments="limit=${couchDBlimit}"
fi


# input sanitizing
# TODO

# dependency check
if [[ "$httpMethod" == 'curl' ]]
then
  # check for curl binary
  curl_bin = "$(type -p curl)"
  if [[ -z "$curl_bin" ]]
  then
    error "curl binary not available, check that it's installed and "\
          "in the PATH" "$EX_CRITICAL"
  fi
elif [[ "$httpMethod" == 'wget' ]]
then
  # check for wget binary
  wget_bin = "$(type -p wget)"
  if [[ -z "$wget_bin" ]]
  then
    error "wget binary not available, check that it's installed "\
          "and included in the PATH" "$EX_CRITICAL"
  fi
elif [[ "$httpMethod" == 'auto' ]]
then
  # check both for curl and wget binaries in "auto mode"
  curl_bin="$(type -p curl)"
  wget_bin="$(type -p wget)"
  if [[ -n "$curl_bin" ]]
  then
    httpMethod="curl"
  elif [[ -n "$wget_bin" ]]
  then
    httpMethod="wget"
  else
    error "curl and wget binaries not available, check that it's installed "\
          "and included in the PATH" "$EX_CRITICAL"
  fi
else
  error "httpMethod specified is not supported" "$EX_USAGE"
fi

httpFullURL="${hostName}:${httpPort}/${dbName}/${httpPath}"
if [[ -n "$httpArguments" ]]
then
  httpFullURL="${httpFullURL}?${httpArguments}"
fi
outputDebug "httpFullURL is ${httpFullURL}" "$debug"

# actual execution
callExitCode=""

backupDB_revision="0"
couchDB_revision="-1"
if [[ ! "$force" ]]
then
  backupDB_revision="$(head -n 10 $outputFile | grep -E '^Etag: ' | cut -d'"' -f 2)"
else
  outputDebug "Force option specified .. DB revision not checked" "$debug"
fi

if [[ -n "$curl_bin" ]]
then
  outputDebug "Curl will be used to make the actual HTTP call" "$debug"
  if [[ ! "$force" ]]
  then
    couchDB_revision=`bash -lc "${curl_bin} -Ikis ${httpFullURL} | grep -E '^Etag: ' | cut -d'\"' -f 2"`
    outputDebug "backup DB revision is -> ${backupDB_revision}" "$debug"
    outputDebug "live couchDB revision is -> ${couchDB_revision}" "$debug"
  else
    outputDebug "Force option specified .. DB revision not checked" "$debug"
  fi
  if [[ "$force" || "$backupDB_revision" != "$couchDB_revision" ]]
  then
    outputDebug "bash -lc \"${curl_bin} -kis ${httpFullURL} > ${outputFile}\""\
                "$debug"
    bash -lc "${curl_bin} -kis ${httpFullURL} > ${outputFile}"
    callExitCode="$?"
  else
    outputDebug "Backup not needed cause DB had no changes" "$debug"
    callExitCode="0"
  fi
elif [[ -n "$wget_bin" ]]
then
  outputDebug "WGET will be used to make the actual HTTP call" "$debug"
  couchDB_rev=`bash -lc "${wget_bin} -s --spider -nv --save-headers ${httpFullURL} | grep -E '^Etag: ' | cut -d'"' -f 2"`
  outputDebug "backup DB revision is -> ${backupDB_revision}" "$debug"
  outputDebug "live couchDB revision is -> ${couchDB_revision}" "$debug"
  if [[ "$backupDB_revision" != "$couchDB_revision" || "$force" ]]
  then
    outputDebug "bash -lc \"${wget_bin} -nv --save-headers ${httpFullURL}" \
                "-o ${outputFile}\"" "$debug"
    bash -lc "${wget_bin} -nv --save-headers ${httpFullURL} -o ${outputFile}"
    callExitCode="$?"
  else
    outputDebug "Backup not needed cause DB had no changes" "$debug"
    callExitCode="0"
  fi
fi
outputDebug "HTTP call exit code is ${callExitCode}" "$debug"
# check for errors
if [[ "$callExitCode" != "0" || -z "$callExitCode" ]]
then
  error "An error happened when executing HTTP call" "$debug"
fi
