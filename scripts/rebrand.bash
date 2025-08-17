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
    echo -e "$1";
  else
    ## en-US
    echo -e "$2";
  fi
}

# 验证系统名称是否符合 Linux 用户名格式 | Validate system name conforms to Linux username format
validate_sys_name() {
  local name="$1"
  
  # 检查是否为空 | Check if empty
  if [ -z "$name" ]; then
    recho "错误: 系统名称不能为空" "Error: System name cannot be empty"
    return 1
  fi
  
  # 检查长度 (1-32 字符) | Check length (1-32 characters)
  if [ ${#name} -lt 1 ] || [ ${#name} -gt 32 ]; then
    recho "错误: 系统名称长度必须在 1-32 个字符之间" "Error: System name must be between 1-32 characters"
    return 1
  fi
  
  # 检查是否以字母开头 | Check if starts with a letter
  if ! [[ "$name" =~ ^[a-zA-Z] ]]; then
    recho "错误: 系统名称必须以字母开头" "Error: System name must start with a letter"
    return 1
  fi
  
  # 检查是否只包含字母、数字、下划线和连字符 | Check if contains only letters, numbers, underscores and hyphens
  if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    recho "错误: 系统名称只能包含字母、数字、下划线和连字符" "Error: System name can only contain letters, numbers, underscores and hyphens"
    return 1
  fi
  
  # 检查是否以连字符结尾 | Check if ends with a hyphen
  if [[ "$name" =~ -$ ]]; then
    recho "错误: 系统名称不能以连字符结尾" "Error: System name cannot end with a hyphen"
    return 1
  fi
  
  # 检查是否全部是数字 | Check if all numbers
  if [[ "$name" =~ ^[0-9]+$ ]]; then
    recho "错误: 系统名称不能全部是数字" "Error: System name cannot be all numbers"
    return 1
  fi
  
  # 检查是否包含大写字母，并给出建议 | Check if contains uppercase letters and give suggestion
  if [[ "$name" =~ [A-Z] ]]; then
    local lowercase_name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    recho "警告: 系统名称包含大写字母。虽然 Linux 支持大写字母用户名，但建议使用小写字母以获得更好的兼容性。" "Warning: System name contains uppercase letters. While Linux supports uppercase usernames, it's recommended to use lowercase for better compatibility."
    recho "建议: 考虑使用 '$lowercase_name' 替代 '$name'" "Suggestion: Consider using '$lowercase_name' instead of '$name'"
    # 不直接返回错误，只给出警告
  fi
  
  # 检查是否是保留的用户名 | Check if it's a reserved username
  local reserved_names=("root" "daemon" "bin" "sys" "sync" "games" "man" "lp" "mail" "news" "uucp" "proxy" "www-data" "backup" "list" "irc" "gnats" "nobody" "systemd-network" "systemd-resolve" "systemd-timesync" "messagebus" "syslog" "_apt" "tss" "uuidd" "tcpdump" "avahi-autoipd" "usbmux" "rtkit" "cups-pk-helper" "dnsmasq" "avahi" "kernoops" "saned" "pulse" "rdma" "sshd" "polkitd" "colord" "geoclue" "Debian-exim" "systemd-coredump" "lightdm" "speech-dispatcher")
  for reserved in "${reserved_names[@]}"; do
    if [ "$name" = "$reserved" ]; then
      recho "错误: '$name' 是系统保留的用户名" "Error: '$name' is a reserved system username"
      return 1
    fi
  done
  
  return 0
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
  LOGIN_PATH=" /usr/local/lib/pageos-greet/login-page.html"
fi

# 如果用户界面 ID 为空，则设为 pageos-ui | If the user interface ID is empty, set it to pageos-ui
if [ -z "$UI_ID" ]; then
  UI_ID="pageos-ui"
fi

# 如果用户界面 ID 不为 pageos-ui 或登录页面路径不为空，替换 airootfs/etc/greetd/config.toml 中 pageos-session 的参数 | If the user interface ID is not pageos-ui or the login page path is not empty, replace the parameter pageos-session in airootfs/etc/greetd/config.toml
if [ "$UI_ID" != "pageos-ui" ] || [ -n "$LOGIN_PATH" ]; then
  CONFIG_FILE="$REPO_DIR/airootfs/etc/greetd/config.toml"
  # airootfs/usr/local/bin/pageos-pkgr repo install --repo airootfs/etc/skel/.local/share/pageos $UI_ID
  if [ -n "$UI_ID" ] && [ "$UI_ID" != "pageos-ui" ]; then
    recho "正在安装用户界面: $UI_ID" "Installing user interface: $UI_ID"
    "$REPO_DIR/airootfs/usr/local/bin/pageos-pkgr" repo update --repo "$REPO_DIR/airootfs/etc/skel/.local/share/pageos"
    "$REPO_DIR/airootfs/usr/local/bin/pageos-pkgr" repo install --repo "$REPO_DIR/airootfs/etc/skel/.local/share/pageos" "$UI_ID"
    "$REPO_DIR/airootfs/usr/local/bin/pageos-pkgr" repo clean --repo "$REPO_DIR/airootfs/etc/skel/.local/share/pageos"
    if [ $? -ne 0 ]; then
      recho "错误: 无法安装用户界面 $UI_ID" "Error: Failed to install user interface $UI_ID"
      exit 1
    fi
  fi
  
  # 检查配置文件是否存在 | Check if the configuration file exists
  if [ ! -f "$CONFIG_FILE" ]; then
    recho "错误: 配置文件不存在: $CONFIG_FILE" "Error: Config file does not exist: $CONFIG_FILE"
    exit 1
  fi
  
  # 检查配置文件中是否存在要替换的行 | Check if the line to be replaced exists in the configuration file
  if ! grep -q 'command = "pageos-session .*"' "$CONFIG_FILE"; then
    recho "错误: 配置文件中未找到要替换的命令行" "Error: Command line to replace not found in config file"
    exit 1
  fi
  
  # 替换配置文件中的命令 | Replace the command in the configuration file
  sed -i "s|command = \"pageos-session .*\"|command = \"pageos-session $UI_ID$LOGIN_PATH\"|" "$CONFIG_FILE"
  if [ $? -ne 0 ]; then
    recho "错误: 无法更新配置文件" "Error: Failed to update config file"
    exit 1
  fi
  
  recho "已将用户界面 ID 设置为: $UI_ID" "User interface ID has been set to: $UI_ID"
fi

# 如果系统名称不为空且不等于 pageos，验证其格式 | If the system name is not empty and not equal to pageos, validate its format
if [ -n "$SYS_NAME" ] && [ "$SYS_NAME" != "pageos" ]; then
  # 验证系统名称格式 | Validate system name format
  if ! validate_sys_name "$SYS_NAME"; then
    exit 1
  fi
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
  if ! grep -q 'iso_name="[^"]*"' "$PROFILEDEF_FILE"; then
    recho "错误: 配置文件中未找到要替换的 iso_name 行" "Error: iso_name line to replace not found in config file"
    exit 1
  fi
  
  # 替换配置文件中的 iso_name | Replace the iso_name in the configuration file
  sed -i "s|iso_name=\"[^\"]*\"|iso_name=\"$SYS_NAME\"|" "$PROFILEDEF_FILE"
  if [ $? -ne 0 ]; then
    recho "错误: 无法更新配置文件" "Error: Failed to update config file"
    exit 1
  fi
  
  recho "已将 ISO 名称设置为: $SYS_NAME" "ISO name has been set to: $SYS_NAME"
fi

# 如果系统名称不为空，替换系统文件中的用户名 | If the system name is not empty, replace the username in system files
if [ -n "$SYS_NAME" ] && [ "$SYS_NAME" != "pageos" ]; then
  # 定义需要替换的文件列表 | Define the list of files to be replaced
  PASSWD_FILE="$REPO_DIR/airootfs/etc/passwd"
  GSHADOW_FILE="$REPO_DIR/airootfs/etc/gshadow"
  HOSTNAME_FILE="$REPO_DIR/airootfs/etc/hostname"
  SHADOW_FILE="$REPO_DIR/airootfs/etc/shadow"
  GROUP_FILE="$REPO_DIR/airootfs/etc/group"
  
  # 替换 passwd 文件中的用户名和主目录 | Replace username and home directory in passwd file
  if [ -f "$PASSWD_FILE" ]; then
    recho "正在替换 $PASSWD_FILE 中的用户名" "Replacing username in $PASSWD_FILE"
    # 替换用户名和主目录中的 pageos
    sed -i "s|^pageos:x:1000:1000::/home/pageos:|$SYS_NAME:x:1000:1000::/home/$SYS_NAME:|" "$PASSWD_FILE"
    if [ $? -eq 0 ]; then
      recho "已成功替换 $PASSWD_FILE 中的用户名" "Successfully replaced username in $PASSWD_FILE"
    else
      recho "错误: 无法替换 $PASSWD_FILE 中的用户名" "Error: Failed to replace username in $PASSWD_FILE"
    fi
  else
    recho "错误: 文件不存在: $PASSWD_FILE" "Error: File does not exist: $PASSWD_FILE"
  fi
  
  # 替换 gshadow 文件中的用户名 | Replace username in gshadow file
  if [ -f "$GSHADOW_FILE" ]; then
    recho "正在替换 $GSHADOW_FILE 中的用户名" "Replacing username in $GSHADOW_FILE"
    sed -i "s|^pageos:!*::|$SYS_NAME:!*::|" "$GSHADOW_FILE"
    if [ $? -eq 0 ]; then
      recho "已成功替换 $GSHADOW_FILE 中的用户名" "Successfully replaced username in $GSHADOW_FILE"
    else
      recho "错误: 无法替换 $GSHADOW_FILE 中的用户名" "Error: Failed to replace username in $GSHADOW_FILE"
    fi
  else
    recho "错误: 文件不存在: $GSHADOW_FILE" "Error: File does not exist: $GSHADOW_FILE"
  fi
  
  # 替换 hostname 文件中的主机名 | Replace hostname in hostname file
  if [ -f "$HOSTNAME_FILE" ]; then
    recho "正在替换 $HOSTNAME_FILE 中的主机名" "Replacing hostname in $HOSTNAME_FILE"
    sed -i "s|^pageos$|$SYS_NAME|" "$HOSTNAME_FILE"
    if [ $? -eq 0 ]; then
      recho "已成功替换 $HOSTNAME_FILE 中的主机名" "Successfully replaced hostname in $HOSTNAME_FILE"
    else
      recho "错误: 无法替换 $HOSTNAME_FILE 中的主机名" "Error: Failed to replace hostname in $HOSTNAME_FILE"
    fi
  else
    recho "错误: 文件不存在: $HOSTNAME_FILE" "Error: File does not exist: $HOSTNAME_FILE"
  fi
  
  # 替换 shadow 文件中的用户名 | Replace username in shadow file
  if [ -f "$SHADOW_FILE" ]; then
    recho "正在替换 $SHADOW_FILE 中的用户名" "Replacing username in $SHADOW_FILE"
    sed -i "s|^pageos:|$SYS_NAME:|" "$SHADOW_FILE"
    if [ $? -eq 0 ]; then
      recho "已成功替换 $SHADOW_FILE 中的用户名" "Successfully replaced username in $SHADOW_FILE"
    else
      recho "错误: 无法替换 $SHADOW_FILE 中的用户名" "Error: Failed to replace username in $SHADOW_FILE"
    fi
  else
    recho "错误: 文件不存在: $SHADOW_FILE" "Error: File does not exist: $SHADOW_FILE"
  fi
  
  # 替换 group 文件中的用户名 | Replace username in group file
  if [ -f "$GROUP_FILE" ]; then
    recho "正在替换 $GROUP_FILE 中的用户名" "Replacing username in $GROUP_FILE"
    # 替换组名和组成员中的 pageos
    sed -i "s|:pageos|:$SYS_NAME|g" "$GROUP_FILE"
    sed -i "s|^pageos:x:1000:|$SYS_NAME:x:1000:|" "$GROUP_FILE"
    if [ $? -eq 0 ]; then
      recho "已成功替换 $GROUP_FILE 中的用户名" "Successfully replaced username in $GROUP_FILE"
    else
      recho "错误: 无法替换 $GROUP_FILE 中的用户名" "Error: Failed to replace username in $GROUP_FILE"
    fi
  else
    recho "错误: 文件不存在: $GROUP_FILE" "Error: File does not exist: $GROUP_FILE"
  fi
  
  recho "已将系统文件中的用户名替换为: $SYS_NAME" "Username in system files has been replaced with: $SYS_NAME"
fi
