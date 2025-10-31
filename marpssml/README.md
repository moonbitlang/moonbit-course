# mdcourse

从包含 Marp 幻灯片和 SSML 音频脚本的统一文档生成配音视频，支持增量更新。

## 安装

### 通过 npm 安装（推荐）

```bash
npm install -g mdcourse
```

### 通过源码安装

```bash
git clone <repository-url>
cd marpssml
./build-local.sh
# 二进制文件位于 bin/mdcourse
```

## 系统依赖

### 必需
- **Deno** >= 2.0
- **Node.js** >= 20.0 (用于 npm 包)
- **ffmpeg** (用于视频合成)

### 安装 ffmpeg

```bash
# macOS
brew install ffmpeg

# Ubuntu/Debian
sudo apt install ffmpeg

# Windows
# 下载并安装: https://ffmpeg.org/download.html
```

## 安装

```bash
# 安装 npm 依赖
npm install
```

## 环境变量

```bash
export TTS_KEY="your-azure-tts-key"
export TTS_REGION="your-azure-region"
```

## 使用方法

### 基本用法

```bash
# 生成视频
mdcourse my-slides.mbt.md -o video.mp4

# 使用默认输出位置 (target/<course>/output.mp4)
mdcourse course7/lec7.mbt.md
```

### 分步执行

```bash
# 仅解析
mdcourse input.mbt.md --parse-only

# 仅生成幻灯片
mdcourse input.mbt.md --slides-only

# 仅生成音频（增量）
mdcourse input.mbt.md --audio-only

# 仅合成视频
mdcourse input.mbt.md --compose-only

# 强制重新生成所有音频
mdcourse input.mbt.md --force-audio -o video.mp4
```

### 选项

```
  -o, --output <file>       输出视频文件路径
  --parse-only              仅解析文件
  --slides-only             仅生成幻灯片图片
  --audio-only              仅生成音频
  --compose-only            仅合成视频
  --force-audio             强制重新生成所有音频
  --voice <name>            指定 TTS 语音 (默认: zh-CN-YunyiMultilingualNeural)
  --fps <number>            视频帧率 (默认: 30)
  --default-duration <sec>  无音频幻灯片的默认时长 (默认: 3.0)
  -h, --help                显示帮助信息
```

## 输入格式

```markdown
---
marp: true
---

# 第一页标题

<!-- ssml
这是第一页的配音文本<break time="500ms"/>
-->

内容...

---

# 第二页

<!-- ssml
这是第二页的配音
-->
```

## 输出结构

```
target/
└── courseX/
    ├── slides/
    │   ├── slide-001.png
    │   └── ...
    ├── audio/
    │   ├── slide-001.wav
    │   ├── slide-001.ssml
    │   ├── slide-001.meta.json
    │   └── ...
    ├── slides.md
    ├── manifest.json
    └── output.mp4
```

## 详细设计

参见 [DESIGN.md](./DESIGN.md)
