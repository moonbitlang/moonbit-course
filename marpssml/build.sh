#!/bin/bash

# 编译脚本 - 为不同平台生成二进制文件

set -e

echo "🔨 编译 mdcourse 二进制文件..."

# 创建 bin 目录
mkdir -p bin

# 编译 Linux x64
echo "📦 编译 Linux x64..."
deno compile --allow-all \
  --output bin/mdcourse-linux-x64 \
  mdcourse.ts

# 编译 macOS x64
echo "📦 编译 macOS x64..."
deno compile --allow-all \
  --target x86_64-apple-darwin \
  --output bin/mdcourse-macos-x64 \
  mdcourse.ts

# 编译 macOS ARM64
echo "📦 编译 macOS ARM64..."
deno compile --allow-all \
  --target aarch64-apple-darwin \
  --output bin/mdcourse-macos-arm64 \
  mdcourse.ts

# 编译 Windows x64
echo "📦 编译 Windows x64..."
deno compile --allow-all \
  --target x86_64-pc-windows-msvc \
  --output bin/mdcourse-win-x64.exe \
  mdcourse.ts

echo "✅ 编译完成！"
echo "📁 二进制文件位于 bin/ 目录"
ls -lh bin/
