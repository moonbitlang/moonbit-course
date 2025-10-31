# 快速开始

## 1. 安装系统依赖

### macOS
```bash
# 安装 Homebrew (如果未安装)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装依赖
brew install deno node ffmpeg
```

### Ubuntu/Debian
```bash
# 安装 Deno
curl -fsSL https://deno.land/install.sh | sh

# 安装 Node.js 和 ffmpeg
sudo apt update
sudo apt install nodejs npm ffmpeg
```

### Windows
1. 安装 [Deno](https://deno.land/#installation)
2. 安装 [Node.js](https://nodejs.org/)
3. 安装 [ffmpeg](https://ffmpeg.org/download.html)

## 2. 安装项目依赖

```bash
cd marpssml
npm install
```

## 3. 设置环境变量

```bash
# Azure TTS 配置（用于音频生成）
export TTS_KEY="your-azure-tts-subscription-key"
export TTS_REGION="your-azure-region"  # 例如: eastus
```

## 4. 创建输入文件

创建 `my-slides.mbt.md`:

```markdown
---
marp: true
---

# 第一页标题

<!-- ssml
欢迎来到我的演示<break time="500ms"/>
-->

这是第一页的内容

---

# 第二页

<!-- ssml
这是第二页的讲解
-->

- 要点 1
- 要点 2
```

## 5. 生成视频

```bash
# 完整流程
deno run -A cli.ts my-slides.mbt.md

# 或分步执行
deno run -A cli.ts my-slides.mbt.md --parse-only
deno run -A cli.ts my-slides.mbt.md --slides-only
deno run -A cli.ts my-slides.mbt.md --audio-only
deno run -A cli.ts my-slides.mbt.md --compose-only
```

## 6. 查看结果

生成的文件位于 `target/my-slides/`:
- `slides/` - 幻灯片图片
- `audio/` - 音频文件
- `output.mp4` - 最终视频

## 常见问题

### Q: 如何跳过某些步骤？
A: 使用分步执行选项，例如只生成幻灯片而不生成音频和视频：
```bash
deno run -A cli.ts my-slides.mbt.md --slides-only
```

### Q: 如何强制重新生成所有音频？
A: 使用 `--force-audio` 选项：
```bash
deno run -A cli.ts my-slides.mbt.md --force-audio
```

### Q: 某页不需要音频怎么办？
A: 直接不添加 `<!-- ssml -->` 注释即可，该页将使用默认时长（3秒）。

### Q: 如何调整无音频页面的显示时长？
A: 使用 `--default-duration` 选项：
```bash
deno run -A cli.ts my-slides.mbt.md --default-duration 5
```

### Q: 修改了某页的 SSML，需要重新生成全部音频吗？
A: 不需要！工具会自动检测修改，只重新生成变化的页面。

## 下一步

- 查看 [README.md](./README.md) 了解详细使用方法
- 查看 [DESIGN.md](./DESIGN.md) 了解架构设计
