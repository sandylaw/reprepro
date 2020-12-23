#!/usr/bin/bash
#v1.0 by sandylaw <freelxs@gmail.com> 2020-08-17
#This script is add list of packages to the list.
#Eg. bash addtolist $URL unstable_device_mars-sp1_comps.list
#mars/sp1 replaced by mars-sp1.
# shellcheck disable=SC1091
source ../common
function help() {
    # Display Help
    echo
    echo "Add list of packages to the list file."
    echo
    echo "Syntax: bash addtolist URL unstable_device_mars-sp1_comps.list"
    echo "options:"
    echo "dist:stable unstable and so on"
    echo "repo: device and so on"
    echo "codename: mars mars/sp1 venus venus/sp1 and so on"
    echo "Please Notice:Eg. mars/sp1 replaced by mars-sp1"
    echo "components:main contrib non-free"
}
# common function
loadhelpall "$*"
URL=$1
if [ -z "$2" ]; then
    echo "Please input list name,E.g: unstable_device_mars-sp1_main.list"
fi
LIST=$2
if [ "${URL: -1}" == "/" ]; then
    :
else
    URL=$URL"/"
fi

isurl=$(check_url "$URL")
if [ "$isurl" == 0 ]; then
    :
else
    echo "Please check the URL: $URL"
    exit 1
fi

function getwebdir() {
    URL=$1
    i=0
    read -ra WEBDIR <<< "$(wget -O - "$URL" 2> /dev/null | grep -o -P  '(href=.*?>)' | grep -o -P '(?<=href=").*(?=">)' | grep -v "^\?" | grep -v "^\\/" | grep -v "^Name</a>" | grep -v "^Parent Directory$" | sort | uniq | tr "\\n" " ")"

    for d in ${WEBDIR[*]}; do
        if [ "${d: -2}" == "./" ]; then
            unset "WEBDIR[$i]"
        fi
        if [ "${d:0:2}" == "./" ]; then
            WEBDIR[$i]="${d:2}"
        fi
        if [ "${d:0:3}" == "../" ]; then
            WEBDIR[$i]="${d:3}"
        fi
        i=$((i + 1))
    done
    for d in ${WEBDIR[*]}; do
        URL=$1
        if [ "${d: -1}" == "/" ]; then
            URL=$URL"$d"
            # 调用自身
            getwebdir "$URL"
        elif [ "${d##*.}" == "deb" ]; then
            RESULT_WEBDIR+=("$URL")
        else
            :
        fi
    done
}

getwebdir "$URL"

read -ra RESULT_WEBDIR <<< "$(echo "${RESULT_WEBDIR[@]}" | sed 's/ /\n/g' | sort | uniq | tr "\\n" " ")"
echo "${RESULT_WEBDIR[@]}" | sed 's/ /\n/g' | sort | uniq | tee -a "$LIST" &> /dev/null
sort < "$LIST" | uniq | tee tmplist && mv tmplist "$LIST"
rm -rf wget-log
