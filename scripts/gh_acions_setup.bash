#!/usr/bin/env bash

# 设置定量 | Quantities
## 当前脚本所在目录 | Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
## 仓库目录 | Repository directory
REPO_DIR="$(dirname "$SCRIPT_DIR")"
## 当前语言 | Current language
CURRENT_LANG=0 # 0: en-US, 1: zh-Hans-CN

# 本地化 | Localization
recho() {
  if [ "$CURRENT_LANG" == "1" ]; then
    ## zh-Hans-CN
    echo "$1";
  else
    ## en-US
    echo "$2";
  fi
}

# 语言检测 | Language detection
if [ $(echo ${LANG/_/-} | grep -Ei "\\b(zh|cn)\\b") ]; then CURRENT_LANG=1;  fi

# 显示脚本信息 | Display script info
recho "开始执行 GitHub Actions 环境设置..." "Starting GitHub Actions environment setup..."
recho "脚本目录: $SCRIPT_DIR" "Script directory: $SCRIPT_DIR"
recho "仓库目录: $REPO_DIR" "Repository directory: $REPO_DIR"

# 安装 sudo | Install sudo
recho "正在安装 sudo..." "Installing sudo..."
pacman -Syu --noconfirm --needed sudo

# 初始化 pacman | Initialize pacman
recho "正在初始化 pacman 密钥..." "Initializing pacman keys..."
pacman-key --init
pacman-key --populate archlinux

# 创建 builder 用户和组 | Create builder user and group
recho "正在创建 builder 用户和组..." "Creating builder user and group..."
useradd -m -s /bin/bash builder
echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
groupadd -f alpm
usermod -aG alpm builder

# 修复文件权限 | Fix file permissions
recho "正在修复文件权限..." "Fixing file permissions..."
chown -R builder:builder $REPO_DIR

# 启用 multilib 仓库 | Enable multilib
recho "正在启用 multilib 仓库..." "Enabling multilib repository..."
printf '\n%s\n%s\n' '[multilib]' 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf
grep -A1 "\[multilib\]" /etc/pacman.conf
pacman -Syy --noconfirm --needed zellij|| true

# 安装基础依赖 | Install base dependencies
recho "正在安装基础依赖..." "Installing base dependencies..."
pacman -Sy --noconfirm archiso reflector git base-devel sudo

# 安装 aurutils | Install aurutils
recho "正在安装 aurutils..." "Installing aurutils..."
sudo -u builder git clone https://aur.archlinux.org/aurutils.git aurutils
sudo -u builder makepkg -si --noconfirm -D aurutils

# 完成提示 | Completion message
recho "环境设置完成！" "Environment setup completed!"
recho "然后需手动执行 sudo -u builder $REPO_DIR/build.bash --noconfirm" "Next, manually execute: sudo -u builder $REPO_DIR/build.bash --noconfirm"
