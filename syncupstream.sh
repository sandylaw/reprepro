#!/usr/bin/bash
#v1.0 by sandylaw <freelxs@gmail.com> 2020-08-26
#sync apt repos form Upstream
# shellcheck disable=SC1091
source common
function help() {
    # Display Help
    echo
    echo "Sync apt Repositoryform Upstream."
    echo
    echo "Syntax: bash syncupstream.sh codename [syncbase|syncdevice|syncall|checkbase|checkdevice|checkall]"
    echo "options:"
    echo "codename: mars mars/sp2 venus venus/sp1 and so on"
    echo "[sync|check]base:http://pools.uniontech.com/ppa/uos-base/"
    echo "[sync|check]device:http://10.8.0.113/unstable/device/"
    echo "[sync|check]all:base+device"
}

loadhelpall "$*"

case $3 in
    force | f | --force | -f)
        FORCE="--noskipold"
        ;;
    *) ;;

esac
read -ra codenames <<< "$(grep Codename < /var/www/repos/stable/device/conf/distributions | awk '{ print $2 }' | tr '\n' ' ')"
# common function
CODENAME=$(check_word_in_array "$1" "${codenames[*]}")
if [ -z "$CODENAME" ]; then
    echo "Pleaase check the codename."
    echo "The system has codename list:${codenames[*]}"
    exit 0
fi

TUSER=$( whoami)
# MYDIR=$(
#     cd "$(dirname "$0")" || exit
#     pwd
# )

function syncbase() {
    TUSER=$( whoami)
    CODENAME="$1"
    if [[ -d /var/www/repos/stable/device/ ]]; then
        pushd /var/www/repos/stable/device/ > /dev/null || exit
        sudo sed -ri 's/^Update.*?/Update: uos/g' conf/distributions
        cat << EOF | sudo tee conf/updates
Name: uos
Suite: stable
Architectures: amd64 arm64 mips64el sw_64 source
Components: main contrib non-free
Method: http://pools.uniontech.com/ppa/uos-base/
#Method: file:///data/repo-dev-wh/ppa/dde-apricot
VerifyRelease: blindtrust
EOF
        if [[ -z "$2" ]]; then
            sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro -V update "$CODENAME"
        else
            sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro -V "$2" update "$CODENAME"
        fi
        popd > /dev/null || exit
    fi
}
function syncdevice() {
    TUSER=$( whoami)
    CODENAME="$1"
    if [[ -z "$2" ]]; then
        shift 1
    else
        shift 2
    fi
    codenames=("$@")
    if [[ -d /var/www/repos/stable/device/ ]]; then
        pushd /var/www/repos/stable/device/ > /dev/null || exit
        sudo rm -f conf/updates
        for codename in ${codenames[*]}; do
            sudo sed -ri "s/^Update:[ ]*uos[ ]*$codename/Update: $codename/g" conf/distributions
            cat << EOF | sudo tee -a conf/updates
Name: $codename
Suite: $codename
Architectures: amd64 arm64 mips64el sw_64 source
Components: main contrib non-free
Method: http://127.0.0.1/unstable/device/
#Method: file:///data/repo-dev-wh/ppa/dde-apricot
VerifyRelease: blindtrust

EOF
        done
        if [[ -z "$2" ]]; then
            sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro -V update "$CODENAME"
        else
            sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro -V "$2" update "$CODENAME"
        fi
        popd > /dev/null || exit
    fi
}
function check_base() {
    TUSER=$( whoami)
    CODENAME="$1"
    if [[ -d /var/www/repos/stable/device/ ]]; then
        pushd /var/www/repos/stable/device/ > /dev/null || exit
        sudo sed -ri 's/^Update.*?/Update: uos/g' conf/distributions
        cat << EOF | sudo tee conf/updates
Name: uos
Suite: stable
Architectures: amd64 arm64 mips64el sw_64 source
Components: main contrib non-free
Method: http://pools.uniontech.com/ppa/uos-base/
#Method: file:///data/repo-dev-wh/ppa/dde-apricot
VerifyRelease: blindtrust
EOF
        sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro -V --noskipold checkupdate "$CODENAME" | grep -v kept
        popd > /dev/null || exit
    fi
}

function check_device() {
    TUSER=$( whoami)
    CODENAME="$1"
    shift 1
    codenames=("$@")
    if [[ -d /var/www/repos/stable/device/ ]]; then
        pushd /var/www/repos/stable/device/ > /dev/null || exit
        sudo rm -f conf/updates
        for codename in ${codenames[*]}; do
            sudo sed -ri "s/^Update:[ ]*uos[ ]*$codename/Update: $codename/g" conf/distributions
            cat << EOF | sudo tee -a conf/updates
Name: $codename
Suite: $codename
Architectures: amd64 arm64 mips64el sw_64 source
Components: main contrib non-free
Method: http://127.0.0.1/unstable/device/
#Method: file:///data/repo-dev-wh/ppa/dde-apricot
VerifyRelease: blindtrust

EOF
        done
        sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro -V --noskipold checkupdate "$CODENAME" | grep -v kept
        popd > /dev/null || exit
    fi
}
case $2 in
    syncbase)
        syncbase "$CODENAME" "$FORCE"
        ;;
    syncdevice)
        syncdevice "$CODENAME" "$FORCE" "${codenames[*]}"
        ;;
    syncall)
        syncbase "$CODENAME" "$FORCE"
        syncdevice "$CODENAME" "$FORCE" "${codenames[*]}"
        ;;
    checkbase)
        check_base "$CODENAME"
        ;;
    checkdevice)
        check_device "$CODENAME" "${codenames[*]}"
        ;;
    checkall)
        check_base "$CODENAME"
        check_device "$CODENAME" "${codenames[*]}"
        ;;
    *) ;;

esac
