#!/usr/bin/env bash
#v1.0 by sandylaw <freelxs@gmail.com> 2020-08-17
set -e
# shellcheck disable=SC1091
source common
function help() {
    # Display Help
    echo "List or remove packages from the  apt repository."
    echo
    echo "Syntax: bash Man_APT_Repository.sh dist repo codename action packagename"
    echo "options:"
    echo "just one dist:stable unstable and so on"
    echo "just one repo: device and so on"
    echo "just one codename: mars mars/sp2 venus venus/sp1 and so on"
    echo "just one action: list remove"
    echo "one or more packagename:will be removed package name."
    echo "remove will delte the deb and source."

}
# common function
loadhelpall "$*"

#set dist dir
pushd /var/www/repos > /dev/null || exit
read -ra dists <<< "$(find . -maxdepth 1 -type d | awk -F "/" '{ print $2 }' | tr '\n' ' ')"
popd > /dev/null || exit
for dist in "${dists[@]}"; do
    if [ "$1" == "$dist" ]; then
        APTURL=/var/www/repos/$1
    fi
done
if [ -z "$APTURL" ]; then
    help
    echo "Pleaase check the dist name."
    echo "The system has dists list:${dists[*]}"
    exit 0
fi

# set REPO
pushd "$APTURL" > /dev/null || exit
read -ra repos <<< "$(find . -maxdepth 1 -type d | awk -F "/" '{ print $2 }' | tr '\n' ' ')"
popd > /dev/null || exit
for repo in "${repos[@]}"; do
    if [ "$2" == "$repo" ]; then
        REPO=$2
    fi
done
if [ -z "$REPO" ]; then
    help
    echo "Pleaase check the repos."
    echo "The system has repos list:${repos[*]}"
    exit 0
fi

REPOSDIR="$APTURL"/"$REPO"
# check codename
#codenames=($(grep Codename < "$REPOSDIR"/conf/distributions | awk '{ print $2 }' | tr '\n' ' '))
read -ra codenames <<< "$(grep Codename < "$REPOSDIR"/conf/distributions | awk '{ print $2 }' | tr '\n' ' ')"
# common function
CODENAME=$(check_word_in_array "$3" "${codenames[*]}")
if [ -z "$CODENAME" ]; then
    echo "Pleaase check the codename."
    echo "The system has codename list:${codenames[*]}"
    exit 0
fi

TUSER=$(whoami)
ACTION=$4
shift 4
PACKAGE=("$@")

if [ "list" == "$ACTION" ]; then
    list_packages "$TUSER" "$REPOSDIR" "$CODENAME"
elif [ "remove" == "$ACTION" ]; then
    remove_packages "$TUSER" "$REPOSDIR" "$CODENAME" "${PACKAGE[*]}"
else
    echo "Please check the action is list or remove?"
    exit 0
fi
