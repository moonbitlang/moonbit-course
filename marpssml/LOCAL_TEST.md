# 本地测试 mdcourse npm 包

## ✅ 推荐方法: npm link

这是最简单快速的测试方法。

### 步骤

```bash
# 1. 在项目目录编译二进制
cd marpssml
./build-local.sh

# 2. 创建全局链接
npm link

# 3. 测试使用（可以在任何目录）
mdcourse --help
cd /tmp
mdcourse ~/path/to/test.mbt.md --slides-only

# 4. 完成后清理
npm unlink -g mdcourse
```

### 验证安装
```bash
# 检查命令是否可用
which mdcourse
# 输出: /usr/local/bin/mdcourse (或类似路径)

# 查看帮助
mdcourse --help
```

## 方法 2: 本地安装

### 1. 编译并打包
```bash
# 在 marpssml 目录
./build-local.sh
npm pack
```

这会生成一个 `.tgz` 文件，例如 `mdcourse-0.1.0.tgz`

### 2. 在测试目录安装
```bash
# 创建测试目录
mkdir ~/test-mdcourse
cd ~/test-mdcourse

# 从本地安装
npm install -g /path/to/marpssml/mdcourse-0.1.0.tgz
```

### 3. 测试
```bash
mdcourse --help
```

### 4. 清理
```bash
npm uninstall -g mdcourse
```

## 方法 3: 直接运行二进制

### 1. 编译
```bash
./build-local.sh
```

### 2. 直接运行
```bash
./bin/mdcourse --help
./bin/mdcourse test.mbt.md -o test.mp4
```

## 完整测试清单

### 基本功能测试
```bash
# 1. 帮助信息
mdcourse --help

# 2. 仅解析
mdcourse test.mbt.md --parse-only

# 3. 仅生成幻灯片
mdcourse test.mbt.md --slides-only

# 4. 指定输出路径
mdcourse test.mbt.md -o ~/Desktop/video.mp4 --slides-only

# 5. 测试环境变量
export TTS_KEY="test"
export TTS_REGION="test"
mdcourse test.mbt.md --audio-only  # 会失败但可以测试参数解析
```

### 跨平台测试（如果编译了所有平台）
```bash
# macOS ARM64
./bin/mdcourse-macos-arm64 --help

# macOS x64
./bin/mdcourse-macos-x64 --help

# Linux x64
./bin/mdcourse-linux-x64 --help

# Windows x64
./bin/mdcourse-win-x64.exe --help  # 在 Windows 上测试
```

## 推荐测试流程

### 第一次测试（快速）
```bash
# 1. 编译当前平台
./build-local.sh

# 2. 直接运行
./bin/mdcourse test.mbt.md --slides-only

# 3. 检查输出
ls -la target/test/slides/
```

### 发布前测试（完整）
```bash
# 1. 编译并打包
./build-local.sh
npm pack

# 2. 全局安装
npm install -g ./mdcourse-0.1.0.tgz

# 3. 在不同目录测试
cd /tmp
mdcourse ~/path/to/test.mbt.md -o test.mp4 --slides-only

# 4. 验证输出
ls -la test.mp4  # 如果生成视频的话

# 5. 清理
npm uninstall -g mdcourse
```

## 常见问题

### Q: `npm link` 后找不到命令
A: 确保 npm 全局 bin 目录在 PATH 中：
```bash
# 查看 npm 全局路径
npm config get prefix

# 添加到 PATH (macOS/Linux)
export PATH="$PATH:$(npm config get prefix)/bin"
```

### Q: postinstall 脚本失败
A: 确保编译了当前平台的二进制：
```bash
./build-local.sh
ls -la bin/
```

### Q: 权限错误
A: 给二进制文件添加执行权限：
```bash
chmod +x bin/mdcourse*
```

## 调试技巧

### 查看 npm 包内容
```bash
npm pack
tar -tzf mdcourse-0.1.0.tgz | head -20
```

### 查看 postinstall 日志
```bash
npm install -g ./mdcourse-0.1.0.tgz --loglevel verbose
```

### 测试特定平台
```bash
# 模拟 Linux 安装
PLATFORM=linux ARCH=x64 node install.js
```
