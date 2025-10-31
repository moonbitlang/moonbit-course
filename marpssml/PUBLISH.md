# 发布 mdcourse 到 npm

## 准备工作

### 1. 安装依赖
```bash
npm install
```

### 2. 编译所有平台的二进制文件
```bash
npm run build
```

这会生成以下二进制文件：
- `bin/mdcourse-linux-x64`
- `bin/mdcourse-macos-x64`
- `bin/mdcourse-macos-arm64`
- `bin/mdcourse-win-x64.exe`

### 3. 测试本地安装
```bash
# 快速编译当前平台
./build-local.sh

# 测试运行
./bin/mdcourse --help
./bin/mdcourse test.mbt.md -o test.mp4 --slides-only
```

## 发布到 npm

### 1. 登录 npm
```bash
npm login
```

### 2. 更新版本号
编辑 `package.json` 中的 `version` 字段。

### 3. 发布
```bash
npm publish
```

## 用户安装和使用

### 全局安装
```bash
npm install -g mdcourse
```

### 使用
```bash
# 基本用法
mdcourse my-slides.mbt.md -o video.mp4

# 设置环境变量
export TTS_KEY="your-azure-key"
export TTS_REGION="your-region"

# 生成视频
mdcourse course.mbt.md -o output.mp4

# 仅生成幻灯片
mdcourse slides.mbt.md --slides-only

# 查看帮助
mdcourse --help
```

## 目录结构

```
mdcourse/
├── bin/                          # 编译后的二进制文件
│   ├── mdcourse-linux-x64
│   ├── mdcourse-macos-x64
│   ├── mdcourse-macos-arm64
│   └── mdcourse-win-x64.exe
├── mdcourse.ts                   # 主入口（新 CLI）
├── parse.ts                      # 解析模块
├── tts.ts                        # TTS 模块
├── compose.ts                    # 视频合成模块
├── build.sh                      # 编译所有平台
├── build-local.sh               # 快速编译当前平台
├── install.js                    # npm postinstall 脚本
├── package.json                  # npm 包配置
├── deno.json                     # Deno 配置
└── README.md                     # 项目文档
```

## 发布清单

- [ ] 更新 `package.json` 中的 version
- [ ] 更新 `package.json` 中的 repository URL
- [ ] 更新 `package.json` 中的 author
- [ ] 运行 `npm run build` 编译所有平台
- [ ] 测试所有平台的二进制文件
- [ ] 运行 `npm publish`
- [ ] 创建 git tag: `git tag v0.1.0 && git push --tags`

## 注意事项

1. **二进制文件大小**: 由于包含了 Deno 运行时和所有依赖，二进制文件约 80-90MB
2. **平台支持**:
   - macOS (x64, ARM64)
   - Linux (x64)
   - Windows (x64)
3. **外部依赖**:
   - ffmpeg (用户需要自行安装)
   - Azure TTS (需要设置环境变量)

## 版本发布流程

```bash
# 1. 更新版本
npm version patch  # 或 minor, major

# 2. 编译
npm run build

# 3. 测试
./bin/mdcourse --help

# 4. 发布
npm publish

# 5. 推送 git
git push && git push --tags
```
