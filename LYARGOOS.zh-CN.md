# LyargoOS 构建系统文档

LyargoOS 是一个有态度的（opinionated）基于 Void Linux 的发行版，名称来源于作者的昵称"李二狗"。它提供预配置的桌面环境和精选的预装应用。

## 概述

LyargoOS 是一个与 void-mklive **完全独立的项目**。它使用 void-mklive 作为构建依赖，但所有自定义内容都保存在自己的仓库中。这意味着：

- 无需 fork 或修改 void-mklive
- 可以轻松独立更新 void-mklive（只需拉取新更改）
- 上游工具与你的自定义内容完全分离
- 你的 LyargoOS 仓库可以托管在任何地方，独立版本控制

## 目录结构

```
lyargoos/                      # 本仓库
├── mkiso.sh                   # 主构建脚本
├── lyargoos.conf              # 中央配置（品牌、软件源、额外软件包）
├── flavors/
│   ├── kde/
│   │   ├── flavor.sh          # KDE Plasma 5 软件包和服务
│   │   └── overlay/           # KDE 特定的 rootfs 覆盖
│   ├── xfce/
│   │   ├── flavor.sh          # XFCE 软件包和服务
│   │   └── overlay/           # XFCE 特定的 rootfs 覆盖
│   └── gnome/
│       ├── flavor.sh          # GNOME 软件包和服务
│       └── overlay/           # GNOME 特定的 rootfs 覆盖
├── overlay/
│   └── common/                # 共享 rootfs 覆盖（所有变体）
│       └── etc/
│           └── issue          # 登录提示信息
├── postsetup.sh               # 安装后脚本（构建时运行一次）
├── void-mklive/               # Git 子模块（上游，未修改）
├── .github/workflows/
│   └── build.yml              # GitHub Actions CI
├── LYARGOOS.md                # 本文档（English）
└── LYARGOOS.zh-CN.md          # 本文档（中文）
```

美术资源和主题通过自定义 `lyargoos-repo` 和 `lyargoos-artwork` 仓库的 XBPS 软件包安装，不存储在本仓库中。

## 设置

### 本地开发

```bash
# 克隆你的 LyargoOS 仓库
git clone https://github.com/Meniny/LyargoOS.git
cd lyargoos

# 克隆 void-mklive（或添加为子模块）
git clone https://github.com/void-linux/void-mklive.git

# 或使用子模块（推荐）
git submodule add https://github.com/void-linux/void-mklive.git
git submodule update --init --recursive
```

### 首次设置（新仓库）

如果你从头开始：

```bash
# 创建项目目录
mkdir lyargoos && cd lyargoos
git init

# 将 LyargoOS 文件复制到此目录（mkiso.sh、flavors/、overlay/ 等）

# 添加 void-mklive 作为子模块
git submodule add https://github.com/void-linux/void-mklive.git

# 提交并推送
git add .
git commit -m "Initial LyargoOS setup"
git remote add origin https://github.com/Meniny/LyargoOS.git
git push -u origin main
```

推送后，GitHub Actions 将在 Actions 选项卡中可用。

### GitHub Actions

包含的工作流在推送/PR 时自动构建 ISO，并支持手动触发，可选择变体（flavor）、架构和日期代码。

设置步骤：
1. 将此仓库推送到 GitHub（包含 void-mklive 子模块）
2. 转到 Actions 选项卡 — 工作流自动运行
3. 手动构建：Actions > Build LyargoOS ISO > Run workflow（选择 flavor、arch、datecode）

## 构建

### 基本构建

```bash
sudo ./mkiso.sh ./void-mklive
```

这将使用默认配置构建 x86_64 KDE ISO。

### 构建选项

```bash
# 指定桌面变体（kde、xfce、gnome）
sudo ./mkiso.sh ./void-mklive -f kde             # 默认
sudo ./mkiso.sh ./void-mklive -f xfce
sudo ./mkiso.sh ./void-mklive -f gnome

# 指定架构
sudo ./mkiso.sh ./void-mklive -a x86_64          # 默认
sudo ./mkiso.sh ./void-mklive -a i686            # 32位 x86
sudo ./mkiso.sh ./void-mklive -a aarch64         # ARM 64位
sudo ./mkiso.sh ./void-mklive -a asahi           # Apple Silicon

# 覆盖日期代码（默认：YYYYMMDD 格式的当天日期）
sudo ./mkiso.sh ./void-mklive -d 20240101

# 添加额外的 XBPS 软件源
sudo ./mkiso.sh ./void-mklive -r https://my-repo.example.com/current

# 组合使用选项
sudo ./mkiso.sh ./void-mklive -f xfce -a x86_64 -d 20240101 -r https://...
```

### 输出

构建的 ISO 文件名为：`void-live-<arch>-<date>-<flavor>.iso`

## 自定义指南

### 中央配置（lyargoos.conf）

`lyargoos.conf` 文件控制品牌标识、美术资源、软件源和额外软件包。编辑此文件而不是修改脚本。

```bash
# 品牌标识
BRAND_NAME="LyargoOS"
BRAND_VERSION="2024.1"
BRAND_ID="lyargo"
BRAND_PRETTY_NAME="LyargoOS (Void Linux)"
BRAND_HOME_URL="https://github.com/Meniny/LyargoOS"

# 自定义 XBPS 软件源
REPOS=(
    "https://repo.lyargo.example.com/current"
)

# 额外软件包（添加到所有变体）
EXTRA_PACKAGES=(
    "flatpak"
    "brave"
    "lyargoos-artwork"
)

# 额外服务（添加到所有变体）
EXTRA_SERVICES=(
    "cupsd"
)

# 启动菜单标题
BOOT_TITLE="LyargoOS"
```

### 桌面变体（Flavors）

每个变体定义要安装的桌面环境和显示管理器。变体配置文件位于 `flavors/` 目录。

**可用变体：**

| 变体 | 桌面环境 | 显示管理器 | 文件 |
|------|---------|-----------|------|
| `kde` | KDE Plasma 5 | sddm | `flavors/kde/flavor.sh` |
| `xfce` | XFCE 4 | lightdm | `flavors/xfce/flavor.sh` |
| `gnome` | GNOME | gdm | `flavors/gnome/flavor.sh` |

**编辑变体**（例如 `flavors/kde/flavor.sh`）：

```bash
FLAVOR_PKGS="$XORG_PKGS kde5 konsole firefox dolphin NetworkManager"
FLAVOR_PKGS="$FLAVOR_PKGS flatpak my-custom-package"

FLAVOR_SERVICES="dbus NetworkManager sddm polkitd"

POSTSETUP_SCRIPT="postsetup.sh"
```

**可用的软件包组**（由 mkiso.sh 在加载变体配置之前定义）：
- `$XORG_PKGS` — X11 图形栈 + 字体
- `$WAYLAND_PKGS` — Wayland 图形栈 + 字体（GNOME 使用）
- `$FONTS` — 基础字体（terminus、dejavu）
- `$A11Y_PKGS` — 无障碍软件包（espeakup、brltty）
- `$GRUB_PKGS` — 架构特定的引导加载程序软件包
- `$GFX_PKGS` — 当前架构的显卡驱动
- `$GFX_WL_PKGS` — 当前架构的 Wayland 显卡驱动

**基础软件包**（在 `lyargoos.conf` 中定义，所有变体均安装）：
- 核心：dialog、cryptsetup、lvm2、mdadm、chrony、elogind
- Shell 和编辑器：zsh、nano、neovim
- CLI 工具：ranger、mc、tmux、git、curl、wget、rsync、openssl、htop、eza、tree、fzf、ncdu、fastfetch、progress、glow、newt、zip、unzip、unrar、gzip、xz、p7zip
- 服务：cronie、nss-mdns、avahi
- 字体和图标：fontconfig、wqy-microhei、papirus-icon-theme
- 图形应用：alacritty、copyq、gparted、gnome-disk-utility、zathura、zathura-pdf-mupdf、grim、gwenview、celluloid
- 输入法：fcitx5、fcitx5-qt、fcitx5-gtk4、fcitx5-rime、fcitx5-lua、fcitx5-chinese-addons、fcitx5-configtool
- Flatpak
- 音频：pipewire、alsa-pipewire
- 虚拟机工具：qemu-guest-agent、spice-vdagent（仅 x86_64/i686）
- 安装器：calamares、lyargoos-calamares-config

**可选软件**（Calamares 安装时可选）：
- 浏览器：chromium、brave
- 网络：flclash
- 媒体：vlc（默认）、smplayer、audacious、audacity、kdenlive、obs-studio、guvcview、celluloid
- 图形：gimp、inkscape、krita、flameshot（默认）
- 生产力：peazip、okular、kate

**基础服务**（开机自启）：
- sshd、chronyd、elogind、spice-vdagentd（仅 x86_64）

**软件源**：Void nonfree 源默认在 x86_64 和 aarch64 上启用。提供 nvidia 驱动、wifi 固件（linux-firmware）和 CPU 微码。

### 添加/删除服务

编辑变体文件（例如 `flavors/kde/flavor.sh`）：

```bash
FLAVOR_SERVICES="dbus NetworkManager sddm polkitd"
FLAVOR_SERVICES="$FLAVOR_SERVICES my-custom-service"
```

服务必须有对应的 `/etc/sv/<service-name>` 目录（由安装该服务的软件包提供）。

### 覆盖文件（Overlay）

构建系统支持两个覆盖目录，文件会被复制到 ISO rootfs 中：

1. **共享覆盖**（`overlay/common/`）— 所有变体共用
2. **变体特定覆盖**（`flavors/<flavor>/overlay/`）— 仅适用于一个变体

目录结构镜像目标文件系统。

**示例：**

```bash
# 添加默认的 neovim 配置（所有变体）
mkdir -p overlay/common/etc/xdg/nvim
cp my-init.vim overlay/common/etc/xdg/nvim/init.vim

# 添加 KDE 特定的 Dolphin 配置
mkdir -p flavors/kde/overlay/etc/xdg/dolphinrc
cp dolphinrc flavors/kde/overlay/etc/xdg/

# 为新用户添加默认的 zsh 配置
cp my-zshrc overlay/common/etc/skel/.zshrc

# 添加自定义 X11 配置
mkdir -p overlay/common/etc/X11/xorg.conf.d
cp my-monitor.conf overlay/common/etc/X11/xorg.conf.d/90-monitor.conf
```

覆盖目录中的所有文件都会被复制到 ISO rootfs 中，覆盖同路径的现有文件。共享覆盖先应用，然后是变体覆盖（因此变体文件可以覆盖共享文件）。

**注意：** `os-release` 是从 `lyargoos.conf` 自动生成的 — 不要在 `overlay/` 中放置静态文件。

### 登录提示信息

编辑 `overlay/common/etc/issue`。这会在文本登录提示处显示。

### 安装后脚本

安装后脚本（`postsetup.sh`）在 ISO 构建过程中运行一次，在所有软件包安装之后执行。它接收 rootfs 路径作为 `$1`。

适用场景：
- 设置 flatpak 远程源
- 生成缓存（图标缓存、字体缓存等）
- 任何需要在目标环境中运行的一次性配置

示例：

```bash
#!/bin/sh
ROOTFS="$1"

# 添加 Flathub 远程源
mkdir -p "$ROOTFS/etc/flatpak/remotes.d"
cat > "$ROOTFS/etc/flatpak/remotes.d/flathub.conf" << 'EOF'
[remote "flathub"]
url=https://dl.flathub.org/repo/flathub.flatpakrepo
gpg-verify=true
EOF

# 生成字体缓存
xbps-uchroot "$ROOTFS" fc-cache -f
```

### 添加新的变体（Flavor）

1. **创建变体目录：**

```bash
mkdir -p flavors/my-desktop/overlay
touch flavors/my-desktop/overlay/.gitkeep
```

2. **创建变体配置：**

```bash
# flavors/my-desktop/flavor.sh
FLAVOR_PKGS="$XORG_PKGS my-desktop-environment my-terminal"
FLAVOR_PKGS="$FLAVOR_PKGS flatpak"
FLAVOR_SERVICES="dbus NetworkManager my-display-manager polkitd"
POSTSETUP_SCRIPT="postsetup.sh"
```

3. **使用新变体构建：**

```bash
sudo ./mkiso.sh ./void-mklive -f my-desktop
```

## 架构支持

构建系统支持多种架构，每个架构有特定的软件包：

| 架构 | GRUB 软件包 | 显卡驱动 | 内核 | 安装器 |
|------|------------|---------|------|--------|
| x86_64 | grub-i386-efi, grub-x86_64-efi | xorg-video-drivers, xf86-video-intel | linux（默认） | 支持 |
| i686 | grub-i386-efi, grub-x86_64-efi | xorg-video-drivers, xf86-video-intel | linux（默认） | 支持 |
| aarch64 | grub-arm64-efi | xorg-video-drivers | linux（默认） | 仅存根 |
| asahi | asahi-base, asahi-scripts, grub-arm64-efi | mesa-asahi-dri | linux-asahi | 仅存根 |

对于 Asahi 构建，会自动添加额外的软件包：
- `asahi-audio` — Apple Silicon 音频支持
- `speakersafetyd` 服务 — 扬声器保护守护进程

## 与上游同步

由于 LyargoOS 使用 void-mklive 作为子模块，更新非常直接：

```bash
# 更新 void-mklive 子模块
cd void-mklive
git pull

# 返回 LyargoOS 根目录并提交更新后的子模块引用
cd ..
git add void-mklive
git commit -m "Update void-mklive submodule"

# 使用更新后的代码库构建
sudo ./mkiso.sh ./void-mklive
```

不会产生合并冲突 — 你的文件和上游文件永远不会混合。

## 故障排除

### 构建失败，提示 "void-mklive directory not found"

确保将正确的 void-mklive 路径作为第一个参数传递：

```bash
sudo ./mkiso.sh /path/to/void-mklive
```

### 构建失败，提示 "flavor 'xyz' not found"

检查 `flavors/xyz/flavor.sh` 是否存在。列出可用变体：

```bash
ls flavors/
```

### 软件包未安装

检查软件包名称是否正确。你可以在以下位置搜索软件包：
- https://voidlinux.org/packages/

### 服务启用失败

服务必须有对应的 `/etc/sv/<service-name>` 目录。检查提供该服务的软件包是否已安装。

### 自定义源不工作

1. 检查 `lyargoos.conf` 中的 URL（`REPOS` 数组）
2. 确保软件源已签名且密钥受信任
3. 测试命令：`xbps-install -S`（同步软件源）然后 `xbps-query -R <package>`

## 高级主题

### 多个自定义软件源

在 `lyargoos.conf` 中添加多个软件源：

```bash
REPOS=(
    "https://repo.lyargo.example.com/current"
    "https://repo.lyargo.example.com/extra"
    "https://repo.lyargo.example.com/testing"
)
```

每个软件源将作为单独的配置文件添加到 `/etc/xbps.d/` 中。

### 预配置 Flatpak 远程源

编辑 `postsetup.sh`：

```bash
# 添加 Flathub
cat > "$ROOTFS/etc/flatpak/remotes.d/flathub.conf" << 'EOF'
[remote "flathub"]
url=https://dl.flathub.org/repo/flathub.flatpakrepo
gpg-verify=true
EOF

# 添加自定义远程源
cat > "$ROOTFS/etc/flatpak/remotes.d/my-remote.conf" << 'EOF'
[remote "my-remote"]
url=https://my-flatpak-repo.example.com
gpg-verify=false
EOF
```

### 自定义默认用户配置

`overlay/common/etc/skel/` 中的文件会被复制到新用户的主目录：

```bash
overlay/common/etc/skel/
├── .bashrc
├── .zshrc
├── .config/
│   └── nvim/
│       └── init.vim
└── .local/
    └── share/
        └── applications/
            └── my-app.desktop
```

## 文件参考

| 文件 | 用途 |
|------|------|
| `mkiso.sh` | 主构建脚本 — 处理变体选择、架构检测、软件包组装、ISO 生成 |
| `lyargoos.conf` | 中央配置 — 品牌标识、软件源、额外软件包/服务、启动标题 |
| `flavors/kde/flavor.sh` | KDE Plasma 5 软件包和服务 |
| `flavors/xfce/flavor.sh` | XFCE 软件包和服务 |
| `flavors/gnome/flavor.sh` | GNOME 软件包和服务 |
| `overlay/common/` | 共享覆盖文件（所有变体） |
| `flavors/<flavor>/overlay/` | 变体特定的覆盖文件 |
| `overlay/common/etc/issue` | 登录提示信息 |
| `postsetup.sh` | 安装后脚本（flatpak 设置、缓存生成等） |

## 相关链接

- [Void Linux 手册](https://docs.voidlinux.org/)
- [xbps 文档](https://github.com/void-linux/xbps)
- [void-mklive 上游项目](https://github.com/void-linux/void-mklive)
