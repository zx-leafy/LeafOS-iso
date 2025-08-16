#!/usr/bin/env bash

# 设置定量 | Quantities
## 仓库所在目录 | Repository directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
## 当前语言 | Current language
CURRENT_LANG=0 ### 0: en-US, 1: zh-Hans-CN
## 用户界面 ID | User界面 ID
UI_ID=$1
## 登录页面直链 | Login page direct link
LOGIN_URL=$2
## 登录页面路径 | Login page path
LOGIN_PATH=""
## 系统名称 | System name
SYS_NAME=$3

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
if [ $(echo ${LANG/_/-} | grep -Ei "\\b(zh|cn)\\b") ]; then CURRENT_LANG=1; fi

# 检查依赖命令 | Check dependency command
if ! command -v curl &> /dev/null; then
  recho "错误: 未找到 curl 命令" "Error: curl command not found"
  exit 1
fi

if ! command -v sed &> /dev/null; then
  recho "错误: 未找到 sed 命令" "Error: sed command not found"
  exit 1
fi

# 检查参数数量 | Check number of parameters
if [ $# -gt 3 ]; then
  recho "错误: 参数过多。用法: $0 [UI_ID] [LOGIN_URL] [SYS_NAME]" "Error: Too many arguments. Usage: $0 [UI_ID] [LOGIN_URL] [SYS_NAME]"
  exit 1
fi

# 如果登录页面直链不为空，下载登录页面直链的文件至指定位置 | If the login page direct link is not empty, download the file to the specified location
if [ -n "$LOGIN_URL" ]; then
  # 创建目标目录（如果不存在）| Create the destination directory (if it does not exist)
  DEST_DIR="$REPO_DIR/airootfs/usr/local/lib/pageos-greet"
  if [ ! -d "$DEST_DIR" ]; then
    recho "正在创建目录: $DEST_DIR" "Creating directory: $DEST_DIR"
    mkdir -p "$DEST_DIR"
    if [ $? -ne 0 ]; then
      recho "错误: 无法创建目录 $DEST_DIR" "Error: Failed to create directory $DEST_DIR"
      exit 1
    fi
  fi
  
  # 下载登录页面 | Download login page
  recho "正在下载登录页面: $LOGIN_URL" "Downloading login page: $LOGIN_URL"
  curl -s -f -o "$REPO_DIR/airootfs/usr/local/lib/pageos-greet/login-page.html" "$LOGIN_URL"
  if [ $? -ne 0 ]; then
    recho "错误: 无法下载登录页面 $LOGIN_URL" "Error: Failed to download login page $LOGIN_URL"
    exit 1
  fi
  
  recho "已下载登录页面: $LOGIN_URL" "Downloaded login page: $LOGIN_URL"
  LOGIN_PATH="/usr/local/lib/pageos-greet/login-page.html"
fi

# 如果用户界面 ID 为空，则设为 pageos-ui | If the user interface ID is empty, set it to pageos-ui
if [ -z "$UI_ID" ]; then
  UI_ID="pageos-ui"
fi

# 如果用户界面 ID 不为 pageos-ui 或登录页面路径不为空，替换 airootfs/etc/greetd/config.toml 中 pageos-session 的参数 | If the user interface ID is not pageos-ui or the login page path is not empty, replace the parameter pageos-session in airootfs/etc/greetd/config.toml
if [ "$UI_ID" != "pageos-ui" ] || [ -n "$LOGIN_PATH" ]; then
  CONFIG_FILE="$REPO_DIR/airootfs/etc/greetd/config.toml"
  
  # 检查配置文件是否存在 | Check if the configuration file exists
  if [ ! -f "$CONFIG_FILE" ]; then
    recho "错误: 配置文件不存在: $CONFIG_FILE" "Error: Config file does not exist: $CONFIG_FILE"
    exit 1
  fi
  
  # 检查配置文件中是否存在要替换的行 | Check if the line to be replaced exists in the configuration file
  if ! grep -q 'command = "pageos-session pageos-ui"' "$CONFIG_FILE"; then
    recho "错误: 配置文件中未找到要替换的命令行" "Error: Command line to replace not found in config file"
    exit 1
  fi
  
  # 替换配置文件中的命令 | Replace the command in the configuration file
  sed -i "s|command = \"pageos-session pageos-ui\"|command = \"pageos-session $UI_ID $LOGIN_PATH\"|" "$CONFIG_FILE"
  if [ $? -ne 0 ]; then
    recho "错误: 无法更新配置文件" "Error: Failed to update config file"
    exit 1
  fi
  
  recho "已将用户界面 ID 设置为: $UI_ID" "User interface ID has been set to: $UI_ID"
fi

# 如果系统名称不为空，替换 profiledef.sh 中的 iso_name | If the system name is not empty, replace iso_name in profiledef.sh
if [ -n "$SYS_NAME" ] && [ "$SYS_NAME" != "pageos" ]; then
  PROFILEDEF_FILE="$REPO_DIR/profiledef.sh"
  
  # 检查配置文件是否存在 | Check if the configuration file exists
  if [ ! -f "$PROFILEDEF_FILE" ]; then
    recho "错误: 配置文件不存在: $PROFILEDEF_FILE" "Error: Config file does not exist: $PROFILEDEF_FILE"
    exit 1
  fi
  
  # 检查配置文件中是否存在要替换的行 | Check if the line to be replaced exists in the configuration file
  if ! grep -q 'iso_name="pageos"' "$PROFILEDEF_FILE"; then
    recho "错误: 配置文件中未找到要替换的 iso_name 行" "Error: iso_name line to replace not found in config file"
    exit 1
  fi
  
  # 替换配置文件中的 iso_name | Replace the iso_name in the configuration file
  sed -i "s|iso_name=\"pageos\"|iso_name=\"$SYS_NAME\"|" "$PROFILEDEF_FILE"
  if [ $? -ne 0 ]; then
    recho "错误: 无法更新配置文件" "Error: Failed to update config file"
    exit 1
  fi
  
  recho "已将 ISO 名称设置为: $SYS_NAME" "ISO name has been set to: $SYS_NAME"
fi
