#!/usr/bin/env bash
#v1.0 by sandylaw <freelxs@gmail.com> 2020-08-17
# shellcheck disable=SC1091
source common
workdir=$(pwd)
function help() {
    # Display Help
    echo
    echo "Add deb and source to the apt repository."
    echo
    echo "Syntax: bash Add_to_APT_Repository.sh dist repo codename components crp_rep_url"
    echo "options:"
    echo "just one dist:stable unstable and so on"
    echo "just one repo: device  and so on"
    echo "just one codename: mars mars/sp2 venus venus/sp1 and so on"
    echo "components:main contrib non-free"
    echo "just one crp_rep_url or local dir path"
    #    echo "Tmp_Dir: default at ~/tmp/debs"

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
read -ra codenames <<< "$(grep Codename < "$REPOSDIR"/conf/distributions | awk '{ print $2 }' | tr '\n' ' ')"
# common function
CODENAME=$(check_word_in_array "$3" "${codenames[*]}")
if [ -z "$CODENAME" ]; then
    echo "Pleaase check the codename."
    echo "The system has codename list:${codenames[*]}"
    exit 0
fi
COMP=$4
TUSER=$(whoami)
#echo "$TUSER"
DEBDIR=/home/"$TUSER"/apt/debs
mkdir -p "$DEBDIR" && cd "$_" || exit
URL=$5
# common function
isurl=$(check_url "$URL")
#if [ "$isurl" == 0 ] && [ "${URL: -1}" == "/" ]; then
if [ "$isurl" == 0 ]; then
    # httrack -s0 -w "$URL"
    "${workdir}"/webtree -f geturl "$URL" > /tmp/filelist
    sed -ri '$d' /tmp/filelist
    sed -ri '/^$/d' /tmp/filelist
    read -ra filelist <<< "$(tr "\n" " " < /tmp/filelist)"
    for file in ${filelist[*]};do
        wget "$file"
    done
    #wget --mirror -e robots=off -r -np "$URL"
elif [ -d "$URL" ]; then
    sudo rsync -r "$URL" .
else
    help
    echo "Pleach chek the URL, dir should end with '/' "
    exit 0
fi
COPY=$6
if [ "$COPY" == "copy" ]; then
    if [[ "$7" == "all" ]]; then
        DEST_CODE="all"
    else
        DEST_CODE=$(check_word_in_array "$7" "${codenames[*]}")
        if [ -z "$DEST_CODE" ]; then
            echo "Pleaase check the codename."
            echo "The system has codename list:${codenames[*]}"
            exit 0
        fi
    fi
fi
if ! [ "$COPY" == "copy" ]; then
    add_to_repository "$TUSER" "$REPOSDIR" "$CODENAME" "$COMP" "$DEBDIR"
elif [ "$COPY" == "copy" ]; then
    add_to_repository "$TUSER" "$REPOSDIR" "$CODENAME" "$COMP" "$DEBDIR" "$COPY" "$DEST_CODE"
fi
echo "Clening:delete the $DEBDIR"
sudo rm -rf "$DEBDIR"
