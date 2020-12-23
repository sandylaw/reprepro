# 使用 reprepro 建立 APT 软件仓库

## 专用设备软件源仓库规划

### 专用设备版软件源仓库名称

依据产品线定义仓库名称：device

### 专用设备版软件源仓库分支管理

同一个产品线不同的维护分支采用 codename 加上维护版本定义。

GUI 产品：mars mars/sp1 mars/sp2

CLI 产品：venus venus/sp1 venus/sp2

### 专用设备版软件源仓库分类

- 内网 ppa 开发仓库
  `deb http://10.8.0.113/unstable/device/ CODENAME main contrib non-free`

- 内网主仓库
  `deb deb http://10.8.0.113/stable/device/ CODENAME main contrib non-free`
- 外网发布仓库
  `deb https://device-packages.chinauos.com/device/ CODENAME main contrib non-free`

## 自建 APT 仓库脚本

### Setup_Reprepro.sh

目标：在`/var/www/repos/apt`目录下自建指定创建多个 dist,例如`stable、unstable`，可以指定创建多个`repos`,例如`device`；可以指定多个 codename，例如`mars mars/sp1 venus venus/sp1`。

用法：普通用户执行命令 `bash Setup_Reprepro.sh`

其中已设定：

```bash
GPGNAME=devicepackages
GPGEMAIL=devicepackages@uniontech.com
```

根据提示以此输入：

- dist:stable unstable and so on
- repos:device and so on
- codename: mars mars/sp1 venus venus/sp1 and so on

项目目录的.gnupg 会复制到主目录，如果项目目录没有会创建新的 gpg key。

如果没有/var/www/repos文件夹，将提示是否创建链接到/var/www/repos。

### Add_to_APT_Repository.sh

目标：添加 crp 仓库软件包和源码到自建软件仓库。

用法：在 gitlab 更新软件代码后，在 crp 构建软件包之后，以普通用户执行命令

`bash Add_to_APT_Repository.sh dist repo codename crp_rep_url`

其中已设定：

```bash
dist: stable unstable
repo: device and so on
codename: mars mars/sp1 venus venus/sp1 and so on
crp_rep_url:crp_rep_url or local dir path
```

需要说明的是，输入或粘贴`crp_rep_url`后要跟上`/`以明确表示是目录，也可以跟本地目录。
**注意此地址要和 repos 保持一致，不要将 device-cli 的 crp 仓库地址加到 device-gui 仓库，反之亦然。**
**专用设备 codename 有变化，device-gui 版本对应的 codename 为 mars，device-cli 版本对应的 codename 为 venus，故仓库 repos 统一为 device，只在 codename 中区分**

从更新 gitlab 不同分支，到 crp 对应不同仓库构建软件包，到添加到 apt 仓库，需要人工分辨对应的是什么分支、什么版本、什么仓库，此部分操作需谨慎进行。

### Man_APT_Repository.sh

目标：列出仓库软件包或者删除仓库中的软件包

用法：普通用户执行命令 `bash Man_APT_Repository.sh dist repo codename action packagename`

其中已设定：

```bash
dist: stable unstable
repo: device and so on
codename: mars mars/sp1 venus venus/sp1 and so on
action: list remove
#list后不跟packagename
#remove支持一次性删除多个软件包,以空格间隔
```

删除软件包将同时删除源码包。

### list/addtolist.sh

目标：增加软件仓库地址，比如 crp 地址，上游软件源地址，将末级目录添加到对应的软件更新清单。
用法：普通用户执行命令 `bash addtolist.sh dist_repo_codename_comps.list`
其中已设定：

```bash
dist: unstable
repo: device and so on
codename: mars mars/sp1 venus venus/sp1 and so on
# codename中的“/”请转为"-"
comps：main contrib non-free
```

### updatepackages.sh

目标：将 list/dist_repo_codename_comps.list 中定义的软件包添加到对应的仓库
用法：普通用户执行命令 `bash updatepackages.sh`

**默认已设置定时任务，配置在/etc/crontab 已定义，3 个小时检查一次更新。**
**检测对比文件及日志在~/.cache/apt-repos/目录，如需强制更新，可删除此目录。**

### sync_base_and_unstable_to_stable.sh

目标：同步上游仓库。主要用途为主仓库，也就是 stable 仓库更新 base 仓库以及推送测试无误的 unstable 仓库到 stable 仓库。
用法：普通用户执行命令 `bash syncupstream.sh codename syncbase|syncdevice|syncall|checkbase|checkdevice|checkall [force]`

其中已设定：

```bash
codename: mars mars/sp1 venus venus/sp1 and so on
checkbase|checkdevice|checkall:检查更新base仓库、检查unstable仓库、检查全部
syncbase|syncdevice|syncall：更新base仓库、更新unstable仓库、更新全部
force：可选参数，强制更新

```

### cache_packages_from_main_repos.sh

目标：通过chroot方式，与运行代码主机架构相同，从桌面版仓库抓包到本地，并添加到仓库。
用法：普通用户执行命令 `bash cache_packages_from_main_repos.sh`

设定：
```
非Amd架构，将download包后同步到服务器，同步后请到服务器添加包到仓库。

cache_packages_from_main_repos.sh 代码本身已设定为添加包时用copy方式，同时添加到mars和venus仓库。

list/fou-sp2/ list/eagle-sp2两个文件夹下有相应的抓包源和软件包列表。

按照规划，后期不再用抓包的方式，而是通过crp构建，故代码只设计了sp2仓库抓包。

```

---

---

## 手动自建 APT 仓库步骤

### 生成签名用的 GPG KEY

运行命令: `gpg --full-gen-key`

按照提示输入姓名、邮箱，确认，有效期，输入密码，`~/.gnupg/openpgp-revocs.d/`目录下生成`.rev`的 key 文件，有效期两年。

随机 16 位密码： `openssl rand -base64 16`

### 生成 ASCII 格式的 Public Key 文件

`gpg --output devicepackages@uniontech.com.gpg.key --armor --export devicepackages@uniontech.com`

实际测试，`--output选项须在前`

### 手动构建软件包

进入源码仓库文件夹：

```bash
dpkg-buildpackage -us -uc
```

### 对 deb 包进行签名

`apt-get install dpkg-sig`

如果在打包 deb 之前已经做好了签名 key，且软件包的 changelog 中的姓名、邮箱与生成 GPG KEY 所用一样，在执行`dpkg-buildpackage`打包时自动签名。

否则，手动签名：`dpkg-sig --sign builder mypackage_0.1.2_amd64.deb`

### Web 服务器

- 安装 apache2 服务器

`sudo apt install apache2`

`sudo mkdir -p /var/www/repos/apt/`

在`*/etc/apache2/apache2.conf*` 添加 `ServerName localhost`

- 添加 apt 仓库配置文件

`sudo vi /etc/apache2/conf.d/repos`

```bashbash
# /etc/apache2/conf.d/repos
# Apache HTTP Server 2.4

<Directory /var/www/repos/ >
        # We want the user to be able to browse the directory manually
        Options Indexes FollowSymLinks Multiviews
        Require all granted
</Directory>

# This syntax supports several repositories, e.g. one for Debian, one for Ubuntu.
# Replace * with debian, if you intend to support one distribution only.
<Directory "/var/www/repos/*/*/db/">
        Require all denied
</Directory>

<Directory "/var/www/repos/*/*/conf/">
        Require all denied
</Directory>

<Directory "/var/www/repos/*/*/incoming/">
        Require all denied
</Directory>
```

- 修改 80 端口主页指向 apt 仓库地址：

`sudo vi /etc/apache2/sites-available/000-default.conf`

`DocumentRoot /var/www/repos/apt`

### 创建 APT 仓库

首先创建一个仓库用的文件夹，名字没有特定要求。在其中创建一个文件夹`conf`,

- 在`conf`文件夹中创建一个`distributions`文本文件，如下格式：

```bash
Origin: Linux Deepin
Label: Deepin
Codename: fou
Version: 2019
Update: fou
Architectures: amd64 arm64 mips64el sw_64 source
Components: main
UDebComponents: main
Contents: percomponent nocompatsymlink .bz2
SignWith: devicepackages@uniontech.com
Description: Deepin debian packages

Origin: Linux Deepin
Label: Deepin
Codename: fou/sp1
Version: 2019
Update: sp1
Architectures: amd64 arm64 mips64el sw_64 source
Components: main
UDebComponents: main
Contents: percomponent nocompatsymlink .bz2
SignWith: devicepackages@uniontech.com
Description: Deepin debian packages

Origin: Linux Deepin
Label: Deepin
Codename: fou/sp2
Version: 2019
Update: sp2
Architectures: amd64 arm64 mips64el sw_64 source
Components: main
UDebComponents: main
Contents: percomponent nocompatsymlink .bz2
SignWith: devicepackages@uniontech.com
Description: Deepin debian packages
```

- `apt-get install reprepro`

`reprepro`会自动创建仓库所需要的结构。

- 创建或更新`distributions`后，执行：`reprepro export`刷新仓库。

- 添加软件包到仓库：

```bash
reprepro --ask-passphrase -Vb . includedeb codename packages.deb
# --aks-passphrase 询问密码，在生成GPG KEY设置的密码
# -V verbose 详细模式，输出详细信息
# -b basedir
# .  当前目录
# includedeb 添加软件包
# codename 比如fou, fou/sp1, fou/sp2
```

- 删除软件包，指定 codename

  `reprepro remove codename packagesname`

- 删除软件代码，指定 codename

  `reprepro removedsc codename packagesname`

### 添加 key

`wget -O - http://×××/devicepackages@uniontech.com.gpg.key | sudo apt-key add -`

### 添加仓库地址到 `/etc/apt/sources.list`

测试仓库：`deb http://192.168.122.1/unstable fou main`

稳定仓库：`deb http://192.168.122.1/stable fou main`

### 修改仓库优先级

`vi /etc/apt/preferences`

```bash
Package: *
Pin: origin 192.168.122.1
Pin-Priority: 900
```

参考：

1. <https://wiki.debian.org/DebianRepository/SetupWithReprepro?action=show&redirect=SettingUpSignedAptRepositoryWithReprepro>
2. <http://blog.jonliv.es/blog/2011/04/26/creating-your-own-signed-apt-repository-and-debian-packages/>
