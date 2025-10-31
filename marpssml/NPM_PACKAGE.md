# mdcourse - npm 包发布总结

## ✅ 完成的功能

### 1. 新的 CLI 接口 (`mdcourse.ts`)
- ✅ 新的命令格式: `mdcourse <input.mbt.md> -o <output.mp4>`
- ✅ 支持 `-o` / `--output` 指定输出文件
- ✅ 保留所有原有功能（分步执行、强制更新等）
- ✅ 更简洁的帮助信息

### 2. 编译和打包
- ✅ `build.sh` - 编译所有平台（Linux, macOS x64/ARM64, Windows）
- ✅ `build-local.sh` - 快速编译当前平台
- ✅ `install.js` - npm postinstall 脚本，自动选择正确的二进制
- ✅ 二进制大小约 86MB（包含 Deno 运行时和所有依赖）

### 3. npm 包配置
- ✅ `package.json` - 配置为 npm 二进制包
- ✅ 支持平台：macOS (x64/ARM64), Linux (x64), Windows (x64)
- ✅ 包名：`mdcourse`
- ✅ 命令名：`mdcourse`

### 4. 文档
- ✅ `README.md` - 更新为 npm 包使用说明
- ✅ `PUBLISH.md` - 发布流程文档
- ✅ `QUICKSTART.md` - 快速开始指南（保留）

## 📦 安装和使用

### 用户安装
```bash
# 全局安装
npm install -g mdcourse

# 使用
mdcourse my-slides.mbt.md -o video.mp4
```

### 开发者编译
```bash
# 编译所有平台
npm run build

# 或快速编译当前平台
./build-local.sh
```

## 📁 文件结构

```
marpssml/
├── mdcourse.ts          # 新的主入口（CLI）✅
├── cli.ts               # 旧入口（保留用于开发）
├── parse.ts             # 解析模块
├── tts.ts               # TTS 模块
├── compose.ts           # 视频合成模块
├── build.sh             # 编译所有平台 ✅
├── build-local.sh       # 快速编译 ✅
├── install.js           # npm 安装脚本 ✅
├── package.json         # npm 配置 ✅
├── deno.json            # Deno 配置
├── README.md            # 主文档 ✅
├── PUBLISH.md           # 发布指南 ✅
├── DESIGN.md            # 设计文档
├── QUICKSTART.md        # 快速开始
├── SUMMARY.md           # 实现总结
└── bin/                 # 编译后的二进制 ✅
    ├── mdcourse-linux-x64
    ├── mdcourse-macos-x64
    ├── mdcourse-macos-arm64
    └── mdcourse-win-x64.exe
```

## 🎯 使用示例

### 基本用法
```bash
# 生成视频
mdcourse slides.mbt.md -o video.mp4

# 使用默认输出
mdcourse course7/lec7.mbt.md

# 仅生成幻灯片
mdcourse slides.mbt.md --slides-only

# 强制重新生成音频
mdcourse slides.mbt.md --force-audio -o output.mp4
```

### 设置环境变量
```bash
export TTS_KEY="your-azure-key"
export TTS_REGION="your-region"
mdcourse slides.mbt.md -o video.mp4
```

## 🚀 发布流程

```bash
# 1. 更新版本
npm version patch

# 2. 编译所有平台
npm run build

# 3. 测试
./bin/mdcourse-macos-arm64 --help

# 4. 发布到 npm
npm publish

# 5. 推送到 git
git push && git push --tags
```

## ⚠️  注意事项

1. **二进制大小**: 约 86MB（包含完整的 Deno 运行时）
2. **外部依赖**:
   - ffmpeg（用户需要自行安装）
   - Azure TTS API（需要密钥）
3. **首次安装**: postinstall 脚本会自动选择合适的二进制
4. **平台限制**: 仅支持 macOS, Linux, Windows (x64/ARM64)

## 🎉 优势

- ✅ **零配置**: 用户无需安装 Deno
- ✅ **独立二进制**: 包含所有依赖
- ✅ **跨平台**: 支持主流操作系统
- ✅ **简单安装**: `npm install -g mdcourse`
- ✅ **清晰接口**: `mdcourse input.mbt.md -o output.mp4`

## 下一步

要发布到 npm，需要：
1. 在 `package.json` 中设置正确的 repository URL
2. 运行 `npm run build` 编译所有平台
3. 测试每个平台的二进制
4. 运行 `npm publish`

项目已准备好发布到 npm！🎊
