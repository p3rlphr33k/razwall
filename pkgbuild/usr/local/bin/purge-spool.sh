#!/bin/sh

TAG=$0
TO=""
FROM=""

function options() {
    local OPT=$(getopt -o f:t: --long from:,to: -n "$TAG" -- "$@")
    if [ $? -ne 0 ]; then
        echo "Terminating..." >&2
        exit 1
    fi

    eval set -- "$OPT"
    while true; do
        case "$1" in
            -f|--from) FROM="$2"; shift 2;;
            -t|--to) TO="$2"; shift 2;;
            --) shift; break;;
            *) echo "Invalid Option! '$1'" >&2; exit 1;;
        esac
    done
}

function usage() {
    cat <<EOF
Usage: $0 [options]

  -f, --from=email        Erase all mails from <email>
  -t, --to=email          Erase all mails to <email>
  -h, --help              This small usage guide
EOF
}

options "$@"
if [ -z "$TO" -a -z "$FROM" ]; then
    echo "Specify at least one option"
    usage
    exit 1
fi


mailq | tail +2 | grep -v '^ *(' | \
    awk -v from="$FROM" -v to="$TO" '
BEGIN { RS = "" }

# $7=sender, $8=recipient1, $9=recipient2
{

if ($9 != "")
  next
if (from != "" && $7 != from)
  next
if (to != "" && $8 != to)
  next
print $1

}
' | tr -d '*!' | postsuper -d -


