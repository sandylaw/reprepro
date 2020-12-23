#!/usr/bin/bash
#v1.1 by sandylaw <freelxs@gmail.com> 2020-09-04
#This script is clean packages of update/dist_repo_codename_clean.list from the apt repos.
#Eg. unstable_device_mars-sp1_clean.list
function help() {
    # Display Help
    echo
    echo "Clean packages of update/dist_repo_codename_clean.list from the apt repos."
    echo
    echo "Syntax: bash cleanpackages.sh dist"
    echo "options:"
    echo "just one dist:stable unstable and so on"

}
TUSER=$(whoami)
MYDIR=$(
    cd "$(dirname "$0")" || exit
    pwd
)
comps=(main contrib non-free)
cd "$MYDIR" || exit
CACHEDIR=/home/$TUSER/.cache/apt-repo
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
# for dist in "${dists[@]}"; do
# APTURL=/var/www/repos/$dist
pushd "$APTURL" > /dev/null || exit
read -ra repos <<< "$(find . -maxdepth 1 -type d | awk -F "/" '{ print $2 }' | tr '\n' ' ')"
popd > /dev/null || exit
for repo in "${repos[@]}"; do
    REPO=$repo
    REPOSDIR="$APTURL"/"$REPO"
    read -ra codenames <<< "$(grep Codename < "$REPOSDIR"/conf/distributions | awk '{ print $2 }' | tr '\n' ' ')"
    for codename in "${codenames[@]}"; do
        listname=$(echo "$dist"_"$repo"_"$codename"_clean | tr "/" "-")
        if [ -f list/"$listname".list ]; then
            for line in $(< list/"$listname".list); do
                sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro --morguedir +b/morguedir/"$codename" --ask-passphrase -Vb "$REPOSDIR" remove "$codename" "$line"
                sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro --morguedir +b/morguedir/"$codename" --ask-passphrase -Vb "$REPOSDIR" removesrc "$codename" "$line"
                sudo rm -rf "$CACHEDIR"/"$dist"_"$repo"_"$codename"*"$line"*
                # sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro --morguedir +b/morguedir/"$codename" --ask-passphrase -Vb "$REPOSDIR" clearvanished "$codename"
            done

        else
            echo "$listname".list is not exist.
        fi
    done
done
# done
