#!/usr/bin/bash
exec 1>>rsync.log 2>&1
rsync -avzP --delete --password-file=/etc/rsync.pass --include "dists/" --include "pool/" --include "dists" --include "pool" --exclude "/*"  /data/repos/stable/device/ "chengdu@10.0.32.52::mirrors-ChengDu-device-repo"
