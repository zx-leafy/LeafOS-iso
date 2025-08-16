#!/usr/bin/env bash

# 测试脚本，用于测试 rebrand.bash 的功能

# 设置定量 | Quantities
## 仓库所在目录 | Repository directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"

# 创建临时目录用于测试
TEST_DIR=$(mktemp -d)
echo "测试目录: $TEST_DIR"

# 复制必要的文件到测试目录
cp -r $REPO_DIR/scripts "$TEST_DIR/"
cp -r $REPO_DIR/airootfs "$TEST_DIR/"
cp $REPO_DIR/profiledef.sh "$TEST_DIR/"

# 创建一个模拟的 pageos-pkgr 脚本
cat > "$TEST_DIR/airootfs/usr/local/bin/pageos-pkgr" << 'EOF'
#!/usr/bin/env bash
echo "模拟安装包: $@"
exit 0
EOF

chmod +x "$TEST_DIR/airootfs/usr/local/bin/pageos-pkgr"

# 创建一个模拟的登录页面
echo "<html><body>Test Login Page</body></html>" > "$TEST_DIR/login-page.html"

# 测试 1: 仅更改 UI ID
echo "=== 测试 1: 仅更改 UI ID ==="
cd "$TEST_DIR" && ./scripts/rebrand.bash "test-ui"
if [ $? -eq 0 ]; then
  echo "测试 1 通过"
else
  echo "测试 1 失败"
fi

# 测试 2: 更改 UI ID 和登录页面
echo "=== 测试 2: 更改 UI ID 和登录页面 ==="
cd "$TEST_DIR" && ./scripts/rebrand.bash "test-ui-2" "file://$TEST_DIR/login-page.html"
if [ $? -eq 0 ]; then
  echo "测试 2 通过"
else
  echo "测试 2 失败"
fi

# 测试 3: 更改系统名称
echo "=== 测试 3: 更改系统名称 ==="
cd "$TEST_DIR" && ./scripts/rebrand.bash "" "" "test-os"
if [ $? -eq 0 ]; then
  echo "测试 3 通过"
else
  echo "测试 3 失败"
fi

# 测试 4: 同时更改所有参数
echo "=== 测试 4: 同时更改所有参数 ==="
cd "$TEST_DIR" && ./scripts/rebrand.bash "test-ui-3" "file://$TEST_DIR/login-page.html" "test-os-2"
if [ $? -eq 0 ]; then
  echo "测试 4 通过"
else
  echo "测试 4 失败"
fi

# 清理测试目录
rm -rf "$TEST_DIR"
