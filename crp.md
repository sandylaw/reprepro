# CRP代码构建平台的使用简介

<https://crp.uniontech.com/>    用户名：姓名全拼， 密码：ut帐号的密码

Wiki教程：[CRP代码构建平台基本使用](https://wikidev.uniontech.com/index.php?title=CRP代码构建平台基本使用)

------

## 使用crp平台构建device软件包

01. 分支：选择mars 或者 venus
02. 仓库管理：与分支一致。如需要增加，找 胡登 添加。

03. 项目管理：左侧 选择 分组`device-gui`或者`device-cli`，`右侧将出现已经创建的项目：`base-files, deepin-desktop-base, iso-tailor`

   创建项目注意事项：

- 名称与仓库/软件报名保持一致
- 描述：自己写
- URL：目前只支持武汉仓库，且使用ssh的地址，需要手工做一下修改，比如`git@gitlabwh.uniontech.com：chengdu/deviceos/base-files.git`修改为“ssh://git@gitlabwh.uniontech.com/chengdu/deviceos/base-files.git”
- 分组：device
- 架构列表：amd64; arm64; mips64el; sw_64
- 其他可以不做修改

04. 测试主题：device-gui  device-cli

   左侧点击device-gui: 将出现关联的打包任务。

   mars子仓库地址：` deb  [trusted=yes] http://shuttle.corp.deepin.com/cache/repos/mars/release-candidate/bWFyczIwMjAtMDktMTE  unstable main`

  venus子仓库地址：` deb  [trusted=yes] http://shuttle.corp.deepin.com/cache/repos/venus/release-candidate/dmVudXMyMDIwLTA5LTEx  unstable main`

05. crp打包

   gitlab更新后，到项目管理，找到对应的项目，右侧，点“更新”：

   请注意：

- 主题：选择 device-gui or device-cli，你要明白要生成的deb包是给哪个仓库分支用的
  - 架构：amd64; arm64; mips64el; sw_64
  - 版本：对应上游版本号，不做变动，可以到<http://pools.corp.deepin.com/server-enterprise/pool/> 找到对应的软件包，看是多少，比如2020.07.13
  - 分支：选择与主题一致，device-gui or device-cli
  - 哈希值：选择分支后，会自动更新
- 更新日志：描述更新内容即可

      确定后，将生成多架构的软件包及源代码包，到测试主题查看，可以看进度，有问题的话看构建过程的输出日志。多架构均完成后，会上传到子仓库地址，有一个没有完成也不会上传。

06. 复制对应的子仓库地址，在后面加一个`/`，添加到自建软件仓库。

07. 当再一次更新gitlab时，**一定要升级版本号之后再构建！**
