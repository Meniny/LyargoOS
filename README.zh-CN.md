# LyargoOS

![LyargoOS Linux](banner.jpg)

[LyargoOS](https://hotodogo.com/lyargoos/) 是一个基于 Void Linux 的个性化发行版，以作者的昵称"李二狗"命名。提供预配置的桌面环境和精选应用程序。

## 特性

- 多种桌面环境：KDE Plasma 5、XFCE、GNOME
- 全面的 CLI 工具集：zsh、nano、neovim、git、tmux、htop、eza、fzf、fastfetch 等
- GUI 基础应用：alacritty、gparted、gnome-disk-utility、zathura、CopyQ、celluloid、gwenview
- 输入法：fcitx5 + Rime + 中文插件 + 配置工具
- Papirus 图标主题 + 文泉驿微米黑字体
- Calamares 图形安装器，支持可选软件选择（浏览器、媒体、图形工具等）
- void-installer 文本模式安装器（备用）
- Pipewire 音频（每用户配置，登录时自动启动）
- NetworkManager + Avahi/mDNS（开机自启）
- elogind（会话管理、休眠、电源控制）
- Flatpak + Flathub 预配置
- 默认启用 Void nonfree 仓库（NVIDIA 驱动、WiFi 固件、微码）
- x86_64 架构包含 qemu-guest-agent + spice-vdagent（用于虚拟机测试）
- 自定义 XBPS 仓库支持
- 兼容 Void Linux（使用官方 Void 仓库）

## 为什么

因为我懒。

## 下载

前往 [SourceForge](https://sourceforge.net/projects/lyargoos/files/)。

## 快速开始

```bash
# 克隆此仓库（包含 void-mklive 和 lyargoos-artwork 子模块）
git clone --recursive https://github.com/Meniny/LyargoOS.git
cd lyargoos

# 构建 KDE ISO（默认桌面）
sudo ./mkiso.sh

# 或构建 XFCE / GNOME
sudo ./mkiso.sh -f xfce
sudo ./mkiso.sh -f gnome
```

如果克隆时没有使用 `--recursive`：
```bash
git submodule update --init --recursive
```

构建的 ISO 文件名为 `void-live-<arch>-<date>-<flavor>.iso`。

## 构建选项

```bash
sudo ./mkiso.sh -f kde              # 桌面环境（默认：kde）
sudo ./mkiso.sh -a x86_64            # 架构（默认：主机架构）
sudo ./mkiso.sh -d 20240101          # 覆盖日期代码
sudo ./mkiso.sh -r https://...       # 添加额外 XBPS 仓库
sudo ./mkiso.sh -i cli               # 仅 CLI 安装器（更小的 ISO）
sudo ./mkiso.sh -i gui               # 仅图形安装器（Calamares）
sudo ./mkiso.sh -i full              # 两种安装器（默认）
```

支持的架构：`x86_64`、`i686`、`aarch64`、`asahi`（Apple Silicon）

## 项目结构

```
lyargoos/
├── mkiso.sh              # 构建脚本
├── lyargoos.conf         # 中央配置（品牌、仓库、额外包）
├── flavors/
│   ├── kde/
│   │   ├── flavor.sh     # KDE Plasma 5 包和服务
│   │   └── overlay/      # KDE 专用 rootfs 覆盖
│   ├── xfce/
│   │   ├── flavor.sh     # XFCE 包和服务
│   │   └── overlay/      # XFCE 专用 rootfs 覆盖
│   └── gnome/
│       ├── flavor.sh     # GNOME 包和服务
│       └── overlay/      # GNOME 专用 rootfs 覆盖
├── overlay/
│   └── common/           # 共享 rootfs 覆盖（所有桌面）
│       └── etc/
│           └── issue     # 登录消息
├── postsetup.sh          # 安装后脚本（Flatpak 设置等）
└── .github/workflows/    # CI 构建工作流
```

美术资源和主题通过自定义仓库的 XBPS 包安装，不存储在此仓库中。

## 自定义

| 内容 | 位置 |
|------|------|
| 品牌标识 | `lyargoos.conf`（`BRAND_NAME`、`BRAND_ID` 等） |
| Live 用户 | `lyargoos.conf`（`LIVE_USER`、`LIVE_HOSTNAME`） |
| 自定义仓库 | `lyargoos.conf`（`REPOS` 数组） |
| 基础包 | `lyargoos.conf`（`BASE_PACKAGES` 数组） |
| 基础服务 | `lyargoos.conf`（`BASE_SERVICES` 数组） |
| 桌面包 | `flavors/<flavor>/flavor.sh`（`FLAVOR_PKGS`） |
| 桌面服务 | `flavors/<flavor>/flavor.sh`（`FLAVOR_SERVICES`） |
| 共享覆盖文件 | `overlay/common/` |
| 每桌面覆盖 | `flavors/<flavor>/overlay/` |
| 登录消息 | `overlay/common/etc/issue` |
| 安装后设置 | `postsetup.sh` |

## GitHub Actions

ISO 通过 Actions 页面手动构建。点击 **Build LyargoOS ISO** → **Run workflow**，然后选择桌面环境、架构、安装器类型和日期代码。

## 与上游同步

如果你 fork 了此仓库并想拉取更新：

```bash
# 一次性：添加原始仓库为 "upstream"
git remote add upstream https://github.com/Meniny/LyargoOS.git

# 需要更新时：
git fetch upstream
git merge upstream/main
git push
```

或使用 fork 页面上的 **"Sync fork"** 按钮。

## 文档

- [LYARGOOS.md](LYARGOOS.md) — 完整文档（英文）
- [LYARGOOS.zh-CN.md](LYARGOOS.zh-CN.md) — 完整文档（中文）

## 更新 void-mklive

```bash
git submodule update --remote void-mklive
git add void-mklive
git commit -m "Update void-mklive submodule"
```

## 许可证

构建脚本和配置：MIT
Void Linux 软件包：各自的许可证
