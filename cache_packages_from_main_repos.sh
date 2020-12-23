#!/usr/bin/bash
#v1.0 by sandylaw <freelxs@gmail.com> 2020-09-04
#本脚本根据list/fou-sp2|eagle-sp2等文件夹下的source.list和deb.list，利用chroot环境获取deb包和源码包
#添加到本地软件源仓库，默认作为不同分支共有环境，执行copy操作。
function help() {
    # Display Help
    echo "Get deb and source from upstream."
    echo
    echo "Syntax: bash cache_packages_from_main_repos.sh"
    echo "Setting:list/fou-sp2|eagle-sp2/*.list"

}
function loadhelp() {
    if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "-help" ]; then
        help
        exit 0
    fi
}
loadhelp "$1"
sudo apt install -y \
    debootstrap \
    dosfstools \
    isolinux \
    mtools \
    psmisc \
    python \
    qemu-user-static \
    reprepro \
    squashfs-tools \
    syslinux \
    unionfs-fuse \
    xorriso
# shellcheck disable=SC1091
source chrootsh
TUSER=$(whoami)
DEBDIR=/home/"$TUSER"/tmp/debs
if [ "$1" == justdown ]; then
    justdown=yes
else
    justdown=no
fi
#ARCHS=(amd64 arm64 mips64el)
case $(arch) in
    x86_64)
        ARCH=amd64
        ;;
    aarch64)
        ARCH=arm64
        ;;
    mips64)
        ARCH=mips64el
        ;;
    sw_64)
        ARCH=sw_64
        ;;
    *)
        echo "The $(arch) is not supported."
        exit 1
        ;;
esac
include_packages="dbus,wget,deepin-keyring,uos-device-keyring,git,apt-src,rsync"
#mars mars/sp1 mars/sp2 and so on
CODENAMES=(mars)
for code in ${CODENAMES[*]}; do
    if [ "$code" == "mars" ]; then
        dists=(fou-sp2 eagle-sp2)
        #        dists=(eagle-sp2)
        DEBOOT_BASE=/usr/share/debootstrap/scripts
        [ -L "${DEBOOT_BASE}/$code" ] || sudo ln -s "${DEBOOT_BASE}/sid" "${DEBOOT_BASE}/$code"
        #debootstrap_mirror='http://pools.uniontech.com/server-enterprise fou/sp2'
        debootstrap_mirror="http://10.8.0.113/stable/device $code"
        sudo debootstrap --no-check-gpg --arch="$ARCH" --include="$include_packages" "$code" "${DEBDIR}"/"$code"/ "${debootstrap_mirror}"
    fi

    for dist in ${dists[*]}; do
        prechroot "$DEBDIR"/"$code" || true
        SOURCELIST=$(realpath list/"$dist"/unstable_device_"$code"_"$dist"_source.list)
        sudo cp "$SOURCELIST" "$DEBDIR"/"$code"/etc/apt/sources.list
        chroot_do "$DEBDIR"/"$code" apt-get -y --allow-unauthenticated --allow-downgrades update || postchroot "$DEBDIR"/"$code" || exit 1

        #for ARCH in ${ARCHS[*]}; do
        DEBLIST=$(realpath list/"$dist"/unstable_device_mars_deb_"$dist"_"$ARCH".list)

        while IFS= read -r line; do
            chroot_do "$DEBDIR"/"$code" mkdir -p ./"$ARCH"
            if [ $justdown == yes ]; then
                chroot_do "$DEBDIR"/"$code" sh -c "cd $ARCH && apt-get download ${line}" || true
            else
                chroot_do "$DEBDIR"/"$code" apt-get -y --allow-unauthenticated --allow-downgrades -o Dir::Cache::Archives=./"$ARCH" --download-only install "${line}"
            fi
        done < "$DEBLIST"
        sudo rm -rf "$DEBDIR"/"$code"/"$ARCH"/*base-files*
        sudo rm -rf "$DEBDIR"/"$code"/"$ARCH"/*deepin-desktop-base*
        sudo rm -rf "$DEBDIR"/"$code"/"$ARCH"/*deepin-desktop-server*
        sudo rm -rf "$DEBDIR"/"$code"/"$ARCH"/*deepin-desktop-device*
        read -ra debs <<< "$(sudo find "$DEBDIR"/"$code"/"$ARCH" -name "*.deb" | tr "\n" " ")"

        for deb in ${debs[*]}; do
            basedebname=$(basename "$deb")
            debname=${basedebname%%_*}
            debnames+=("$debname")
        done
        # if [[ "$dists" =~ eagle ]];then
        #     bash Man_APT_Repository.sh unstable device "$code" list|awk -F ":" '{print $2}'|awk '{print $1}' > /home/"$TUSER"/tmp/old_"$code"_soft.list
        #     for debname in ${debnames[*]}; do
        #         if grep -q "$debname" /home/"$TUSER"/tmp/old_"$code"_soft.list;then
        #             sudo rm -rf "$DEBDIR"/"$code"/"$ARCH"/*"$debname"*
        #         fi
        #     done
        #     read -ra debs <<< "$(sudo find "$DEBDIR"/"$code"/"$ARCH" -name "*.deb" | tr "\n" " ")"
        #     for deb in ${debs[*]}; do
        #         basedebname=$(basename "$deb")
        #         debname=${basedebname%%_*}
        #         debnames+=("$debname")
        #     done
        # fi

        for debname in ${debnames[*]}; do
            chroot_do "$DEBDIR"/"$code" sh -c "cd $ARCH && apt-get source --download-only ${debname} " || true
        done
        #done
        postchroot "$DEBDIR"/"$code" || true
    done
    DEST_CODE="${code//mars/venus}"
    if [ "$ARCH" == amd64 ]; then
        bash Man_APT_Repository.sh unstable device "$code" list > /home/"$TUSER"/tmp/old_"$code".list

        #for ARCH in ${ARCHS[*]}; do
        bash Add_to_APT_Repository.sh unstable device "$code" main "$DEBDIR"/"$code"/"$ARCH"/ copy "$DEST_CODE"
        #done
        bash Man_APT_Repository.sh unstable device "$code" list > /home/"$TUSER"/tmp/new_"$code".list
        diff /home/"$TUSER"/tmp/new_"$code".list /home/"$TUSER"/tmp/old_"$code".list > /home/"$TUSER"/tmp/add_unstable_"$code"_"$(date +%F_%H%M%S)".list
    else
        SSHPASS="123456"
        rsync -av --progress --rsh="/usr/bin/sshpass -p $SSHPASS ssh -o StrictHostKeyChecking=no" "$DEBDIR"/"$code"/"$ARCH" uos@10.8.0.113:/home/uos/tmp/
        #sshpass -p '123456' ssh uos@10.8.0.113 -t 'cd /home/uos/sysdev-docs/reprepro;bash --login'
        #bash Man_APT_Repository.sh unstable device "$code" list > /home/uos/tmp/old_"$code".list
        #bash Add_to_APT_Repository.sh unstable device "$code" main /home/uos/tmp/"$ARCH"/ copy "$DEST_CODE"
        #bash Man_APT_Repository.sh unstable device "$code" list > /home/uos/tmp/new_"$code".list
        #diff /home/uos/tmp/new_"$code".list /home/uos/tmp/old_"$code".list > /home/uos/tmp/add_unstable_"$code"_`date +%F_%H%M%S`.list
    fi
    sudo rm -rf "$DEBDIR"/"$code"/
done
