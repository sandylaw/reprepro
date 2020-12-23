#!/usr/bin/env bash
#v1.0 by sandylaw <freelxs@gmail.com> 2020-08-17

# shellcheck disable=SC1091
source common
TUSER=$(whoami)
PWD=$(pwd)
function help() {
    # Display Help
    echo "List or remove packages from the  apt repository."
    echo
    echo "Syntax: bash Setup_Reprepro.sh"
    echo "Input:can set several at once"
    echo "dists:stable unstable and so on "
    echo "repos:device and so on"
    echo "gui codenames: mars mars/sp1 mars/sp2 and so on"
    echo "gui codenames: venus venus/sp1 venus/sp2 and so on"
}
loadhelp "$1"
read -ra DISTS -p "Please input the apt dist name,E.g stable unstable:"
read -ra REPOS -p "Please input the apt repos name,E.g device:"
read -ra CODES -p "Please input the codenames,E.g mars mars/sp1 venus venus/sp1:"
GPGNAME=devicepackages
GPGEMAIL=devicepackages@uniontech.com
SERVERNAME=localhost

# common function

Install_Required_Packages "$TUSER" "$PWD"
Generate_GPG_KEY "${GPGNAME}" "${GPGEMAIL}"

Configure_Apache2_with_reprepro "$SERVERNAME"

for dist in ${DISTS[*]}; do
    Configure_Reprepro /var/www/repos/"$dist" "${REPOS[*]}" "$PUBLIC_KEY_URL" "${CODES[*]}"
done
echo "The ASCII Format Public key is $PUBLIC_KEY_URL"
echo "The Passphrase saved at $PASSWD_URL"
