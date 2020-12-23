#!/bin/bash
# setup vsftp for repo.
# by liuxinsong <liuxinsong@uniontech.com> 2020-11-18

if ! vsftpdwho &> /dev/null; then
    sudo apt install vsftpd
fi
sudo sed -ri '/anonymous_enable/d' /etc/vsftpd.conf &> /dev/null
sudo sed -ri '/no_anon_password/d' /etc/vsftpd.conf &> /dev/null
sudo sed -ri '/anon_root/d' /etc/vsftpd.conf &> /dev/null
sudo sed -ri "/listen_ipv6/aanonymous_enable=YES\nno_anon_password=YES\nanon_root=/srv/ftp/" /etc/vsftpd.conf &> /dev/null

sudo mkdir -p /srv/ftp/{stable,unstable}/device/{dists,pool}

sudo mount --bind /data/repos/stable/device/dists /srv/ftp/stable/device/dists
sudo mount --bind /data/repos/stable/device/pool /srv/ftp/stable/device/pool
sudo mount --bind /data/repos/unstable/device/dists /srv/ftp/unstable/device/dists
sudo mount --bind /data/repos/unstable/device/pool /srv/ftp/unstable/device/pool

sudo systemctl restart vsftpd.service
