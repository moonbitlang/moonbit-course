#!/bin/bash

# 快速编译脚本 - 只编译当前平台

set -e

echo "🔨 编译 mdcourse (当前平台)..."

# 创建 bin 目录
mkdir -p bin

# 编译当前平台
deno compile --allow-all \
  --output bin/mdcourse \
  mdcourse.ts

echo "✅ 编译完成！"
echo "📁 二进制文件: bin/mdcourse"

# 测试
echo ""
echo "🧪 测试运行:"
./bin/mdcourse --help
