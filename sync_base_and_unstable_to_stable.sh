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
	echo "Syntax: bash syncupstream.sh codename syncbase|syncdevice|syncall|checkbase|checkdevice|checkall [force]"
	echo "options:"
	echo "codename: mars mars/sp2 venus venus/sp1 and so on"
	echo "[sync|check]base:http://pools.uniontech.com/ppa/uos-base/"
	echo "[sync|check]device:http://127.0.0.1/unstable/device/"
	echo "[sync|check]all:base+device"
	echo "force:force update, force | f | --force | -f"
}

loadhelpall "$*"

case $3 in
force | f | --force | -f)
	FORCE="--noskipold"
	;;
*) ;;

esac
read -ra codenames <<<"$(grep Codename </var/www/repos/stable/device/conf/distributions | awk '{ print $2 }' | tr '\n' ' ')"
# common function
CODENAME=$(check_word_in_array "$1" "${codenames[*]}")
if [ -z "$CODENAME" ]; then
	echo "Pleaase check the codename."
	echo "The system has codename list:${codenames[*]}"
	exit 0
fi

TUSER=$(whoami)
# MYDIR=$(
#     cd "$(dirname "$0")" || exit
#     pwd
# )
## updates文件中Suite: stable ，这里的stable是要更新的仓库（比如base仓库）的codename或分支名称。
function updateconf() {
	if [[ -d /var/www/repos/stable/device/ ]]; then
		pushd /var/www/repos/stable/device/ >/dev/null || exit

    	cat <<EOF | sudo tee conf/updates
Name: 1000
#Suite: stable
Suite: eagle/sp2
Architectures: i386 amd64 arm64 mips64el sw_64 source
Components: main contrib non-free
#Method: http://pools.uniontech.com/ppa/uos-base/
#Method: file:///data/apt-mirror/mirror/pools.uniontech.com/ppa/uos-base/
Method: file:///data/apt-mirror-desktop/mirror/pools.uniontech.com/desktop-professional/
VerifyRelease: blindtrust

Name: 1010
#Suite: stable
Suite: eagle/sp3
Architectures: i386 amd64 arm64 mips64el sw_64 source
Components: main contrib non-free
#Method: http://pools.uniontech.com/ppa/uos-base/
#Method: file:///data/apt-mirror/mirror/pools.uniontech.com/ppa/uos-base/
Method: file:///data/apt-mirror-desktop/mirror/pools.uniontech.com/desktop-professional/
VerifyRelease: blindtrust

Name: mars
Suite: mars
Architectures: i386 amd64 arm64 mips64el sw_64 source
Components: main contrib non-free
Method: http://127.0.0.1/unstable/device/
#Method: file:///data/repo-dev-wh/ppa/dde-apricot
VerifyRelease: blindtrust

Name: venus
Suite: venus
Architectures: i386 amd64 arm64 mips64el sw_64 source
Components: main contrib non-free
Method: http://127.0.0.1/unstable/device/
#Method: file:///data/repo-dev-wh/ppa/dde-apricot
VerifyRelease: blindtrust

Name: mars/1010
Suite: mars/1010
Architectures: i386 amd64 arm64 mips64el sw_64 source
Components: main contrib non-free
Method: http://127.0.0.1/unstable/device/
#Method: file:///data/repo-dev-wh/ppa/dde-apricot
VerifyRelease: blindtrust

Name: venus/1010
Suite: venus/1010
Architectures: i386 amd64 arm64 mips64el sw_64 source
Components: main contrib non-free
Method: http://127.0.0.1/unstable/device/
#Method: file:///data/repo-dev-wh/ppa/dde-apricot
VerifyRelease: blindtrust
EOF
		popd >/dev/null || exit
	fi
}
function syncbase() {
	TUSER=$(whoami)
	CODENAME="$1"
	if [[ -d /var/www/repos/stable/device/ ]]; then
		pushd /var/www/repos/stable/device/ >/dev/null || exit
        [ -z "${2}" ] && sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro -V update "$CODENAME"
        [ -n "${2}" ] && sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro -V "${2}" update "$CODENAME"
		popd >/dev/null || exit
	fi
}
function syncdevice() {
	TUSER=$(whoami)
	CODENAME="$1"
	updatecode="${CODENAME##*/}"
	if [ mars == "$updatecode" ] || [ venus == "$updatecode" ]; then
        updatecodename="$updatecode"
		updatecode=1000
    else
        updatecodename="${CODENAME%%/*}"'\/'"${CODENAME##*/}"
	fi
	if [[ -d /var/www/repos/stable/device/ ]]; then
		pushd /var/www/repos/stable/device/ >/dev/null || exit
		sudo cp conf/distributions{,.bak}
		sudo sed -ri "s/^Update:[ ]*${updatecode}[ ]*/Update: ${updatecodename}/g" conf/distributions
        [ -z "${2}" ] && sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro -V update "$CODENAME"
        [ -n "${2}" ] && sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro -V "${2}" update "$CODENAME"
		sudo cp conf/distributions{.bak,}
		popd >/dev/null || exit
	fi
}
function check_base() {
	TUSER=$(whoami)
	CODENAME="$1"
	if [[ -d /var/www/repos/stable/device/ ]]; then
		pushd /var/www/repos/stable/device/ >/dev/null || exit
		sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro -V --noskipold checkupdate "$CODENAME" | grep -v kept
		popd >/dev/null || exit
	fi
}

function check_device() {
	TUSER=$(whoami)
	CODENAME="$1"
	updatecode="${CODENAME##*/}"
	if [ mars == "$updatecode" ] || [ venus == "$updatecode" ]; then
        updatecodename="$updatecode"
		updatecode=1000
    else
        updatecodename="${CODENAME%%/*}"'\/'"${CODENAME##*/}"
	fi
	if [[ -d /var/www/repos/stable/device/ ]]; then
		pushd /var/www/repos/stable/device/ >/dev/null || exit
		sudo cp conf/distributions{,.bak}
		sudo sed -ri "s/^Update:[ ]*${updatecode}[ ]*/Update: ${updatecodename}/g" conf/distributions
		sudo GNUPGHOME=/home/"$TUSER"/.gnupg reprepro -V --noskipold checkupdate "$CODENAME" | grep -v kept
		sudo cp conf/distributions{.bak,}
		popd >/dev/null || exit
	fi
}

updateconf

case $2 in
syncbase)
	syncbase "$CODENAME" "$FORCE"
	;;
syncdevice)
	syncdevice "$CODENAME" "$FORCE"
	;;
syncall)
	syncbase "$CODENAME" "$FORCE"
	syncdevice "$CODENAME" "$FORCE"
	;;
checkbase)
	check_base "$CODENAME"
	;;
checkdevice)
	check_device "$CODENAME"
	;;
checkall)
	check_base "$CODENAME"
	check_device "$CODENAME"
	;;
*) ;;

esac
