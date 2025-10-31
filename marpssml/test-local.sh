#!/bin/bash

# 快速测试脚本 - 测试 mdcourse 所有核心功能

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "🧪 开始测试 mdcourse..."
echo ""

# 检查是否已编译
if [ ! -f "bin/mdcourse" ]; then
    echo "⚠️  未找到二进制文件，正在编译..."
    ./build-local.sh
fi

# 测试帮助信息
echo "1. 测试帮助信息..."
./bin/mdcourse --help > /dev/null
echo "   ✅ 帮助信息正常"

# 创建临时测试目录
TEST_DIR="/tmp/mdcourse-test-$$"
mkdir -p "$TEST_DIR"

echo ""
echo "2. 测试解析功能..."
cd "$TEST_DIR"
"$SCRIPT_DIR/bin/mdcourse" "$SCRIPT_DIR/test.mbt.md" --parse-only > /dev/null 2>&1
if [ -f "target/test/manifest.json" ]; then
    echo "   ✅ 解析成功"
else
    echo "   ❌ 解析失败"
    exit 1
fi

echo ""
echo "3. 测试幻灯片生成..."
rm -rf target
"$SCRIPT_DIR/bin/mdcourse" "$SCRIPT_DIR/test.mbt.md" --slides-only > /dev/null 2>&1
if [ -f "target/test/slides/slide-001.png" ]; then
    SLIDE_COUNT=$(ls target/test/slides/*.png 2>/dev/null | wc -l | tr -d ' ')
    echo "   ✅ 生成了 $SLIDE_COUNT 张幻灯片"
else
    echo "   ❌ 幻灯片生成失败"
    exit 1
fi

echo ""
echo "4. 测试输出路径选项..."
rm -rf target
"$SCRIPT_DIR/bin/mdcourse" "$SCRIPT_DIR/test.mbt.md" -o my-test.mp4 --slides-only > /dev/null 2>&1
echo "   ✅ 输出路径选项正常"

# 清理
cd /
rm -rf "$TEST_DIR"

echo ""
echo "✅ 所有测试通过！"
echo ""
echo "💡 提示: 运行 'npm link' 可以全局安装测试"
echo "   然后可以在任何目录使用: mdcourse <file> -o <output>"

