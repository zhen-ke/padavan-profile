# Panavan newifi mini profile

## 配置文件说明

- 机型适配文件位于`rt-56u/trunk/configs/boards`目录下；
- 配置文件位于`rt-n56u/trunk/` `.config`目录下；
- 新版`aria2`与配置文件位于`rt-n56u/trunk/user/aria2`目录下；
- 新版`transmission`与配置文件位于`rt-n56u/trunk/user/transmission/transmission-control/web`目录下；
- LAN地址与WIFI默认名称密码等位于`rt-n56u/trunk/user/shared/defaults.h`里；
- 汉化文件位于`rt-n56u/trunk/user/www`目录下。




## 升级高版本 aria2 说明

源码默认的 arai2 是 1.5.1 ，如果需要使用新版或者高于 1.5.1 版本的 arai2 ，请升级 toolchain 里的 gcc（源码默认的 gcc 是4.7.7）。

### 升级 GCC 方法（gcc >= 4.8.3）

1. 修改`rt-56u/toolchain-mipsel/versions.inc`文件，并修改里面的`GCCVER=X.X.X`，`X.X.X`代表你想要升级到的版本号。（比如我下载的 GCC 名是 gcc-5.4.0.tar.bz2，则GCCVER=X.X.X把修改成GCCVER=5.4.0）
2. 删除`rt-56u/toolchain-mipsel/src/mipsel-linux-uclibc-toolchain`下的`gcc-4.7.7.tar.bz2`，然后把下载到的高版本放到里面。
3. 然后重新编译一个交叉编译的工具链。

```bash
cd /opt/rt-n56u/toolchain-mipsel
sudo ./clean_sources
sudo ./build_toolchain
```

