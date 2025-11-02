# mdcourse

从包含 Marp 幻灯片和 SSML 音频脚本的统一文档生成配音视频，支持增量更新、视频插入和自定义分辨率。

## 特性

- ✅ **Marp 幻灯片转视频**：自动将 Markdown 幻灯片转换为 PNG，生成视频
- ✅ **Azure TTS 配音**：使用 SSML 为每页幻灯片添加语音
- ✅ **视频插入**：在幻灯片之间插入视频片段，支持为视频添加配音
- ✅ **增量更新**：基于 SSML 哈希值，只重新生成修改过的音频
- ✅ **自动重试**：TTS API 失败时自动重试，支持指数退避
- ✅ **多分辨率**：支持 4K、1440p、1080p、720p、480p
- ✅ **代码高亮**：自定义 Shiki 语法高亮，支持 MoonBit、ABNF、WASM 等
- ✅ **音频混合**：视频配音与原视频音频自动混合
- ✅ **统一编码**：所有片段使用相同的编码参数，确保无缝拼接

## 安装

### 通过 npm 安装（推荐）

```bash
npm install -g mdcourse
```

### 通过源码安装

```bash
git clone <repository-url>
cd marpssml
npm install
./build-local.sh
# 二进制文件位于 bin/mdcourse
```

## 系统依赖

### 必需
- **Deno** >= 2.0 (用于源码编译)
- **Node.js** >= 20.0 (用于 npm 包和 Marp)
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

## 环境变量

```bash
export TTS_KEY="your-azure-tts-key"
export TTS_REGION="your-azure-region"
```

获取 Azure TTS 密钥：https://azure.microsoft.com/services/cognitive-services/text-to-speech/

## 使用方法

### 基本用法

```bash
# 生成视频
mdcourse my-slides.mbt.md -o video.mp4

# 使用默认输出位置 (target/<course>/output.mp4)
mdcourse course7/lec7.mbt.md

# 使用 720p 分辨率和 5 次重试
mdcourse slides.mbt.md -o output.mp4 --resolution 720p --retry 5

# 保留临时片段文件用于调试
mdcourse test.mbt.md --keep-temp
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

### 完整选项

```
  -o, --output <file>       输出视频文件路径 (默认: target/<course>/output.mp4)
  --parse-only              仅解析文件
  --slides-only             仅生成幻灯片图片
  --audio-only              仅生成音频
  --compose-only            仅合成视频
  --force-audio             强制重新生成所有音频
  --keep-temp               保留临时视频片段文件用于调试
  --voice <name>            指定 TTS 语音 (默认: zh-CN-YunyiMultilingualNeural)
  --fps <number>            视频帧率 (默认: 30)
  --resolution <preset>     视频分辨率 (默认: 1080p)
                            可选: 4k, 1440p, 1080p, 720p, 480p
  --retry <number>          TTS API 失败时的重试次数 (默认: 3)
  --default-duration <sec>  无音频幻灯片的默认时长 (默认: 3.0)
  -h, --help                显示帮助信息
```

## 输入格式

### 基本幻灯片

```markdown
---
marp: true
headingDivider: 1
---

# 第一页标题

<!-- ssml
这是第一页的配音文本<break time="500ms"/>
-->

内容...

# 第二页

<!-- ssml
这是第二页的配音
-->
```

### 使用 headingDivider

使用 `headingDivider: 1` 可以让每个 `#` 标题自动分页，无需手动添加 `---`：

```markdown
---
marp: true
headingDivider: 1
---

# 第一页
<!-- ssml
第一页的配音
-->

# 第二页
<!-- ssml
第二页的配音
-->
```

### 插入视频

在幻灯片之间插入视频片段：

```markdown
# 第二页

内容...

<!-- video my-video.mp4 -->

# 第三页

下一页内容...
```

### 为视频添加配音

在 `<!-- video ... -->` 后紧跟 SSML 配音：

```markdown
# 第二页

内容...

<!-- video demo.mp4 -->
<!-- ssml
这是对这段视频的讲解
-->

# 第三页
```

**特性**：
- 视频配音与原视频音频会自动混合
- 最终时长为 `max(视频时长, 配音时长)`
- 如果配音更长，视频会循环播放

## 输出结构

```
target/
└── courseX/
    ├── slides/
    │   ├── slide-001.png
    │   ├── slide-002.png
    │   └── ...
    ├── audio/
    │   ├── slide-001.wav
    │   ├── slide-001.ssml
    │   ├── slide-001.meta.json
    │   ├── video-after-002.wav        # 视频配音
    │   ├── video-after-002.ssml
    │   ├── video-after-002.meta.json
    │   └── ...
    ├── slides.md
    ├── manifest.json
    ├── output.mp4
    └── output.temp-*.mp4              # 临时片段 (使用 --keep-temp 时保留)
```

## 分辨率选项

| 预设 | 分辨率 | 用途 | 相对文件大小 |
|------|--------|------|-------------|
| `4k` | 3840×2160 | 超高清，专业用途 | ~4× |
| `1440p` | 2560×1440 | 2K 高质量 | ~2× |
| `1080p` | 1920×1080 | 标准高清（默认） | 1× |
| `720p` | 1280×720 | 标清，网络传播 | ~0.5× |
| `480p` | 854×480 | 低分辨率，极小文件 | ~0.25× |

所有内容会保持原始宽高比，使用 letterbox padding 避免变形。

## 重试策略

当 TTS API 调用失败时（网络问题、API 限流等），会自动重试：

- 默认重试 3 次（可通过 `--retry` 配置）
- 使用指数退避：1秒 → 2秒 → 4秒 → 8秒（最多 10 秒）
- 每次重试会显示失败原因和等待时间
- 示例输出：
  ```
  ⚠️  尝试 1/3 失败: Connection timeout
  ⏳ 1000ms 后重试...
  ```

## 调试

### 保留临时片段

使用 `--keep-temp` 选项保留所有临时视频片段：

```bash
mdcourse test.mbt.md --keep-temp
```

输出示例：
```
ℹ️  保留了 4 个临时片段文件用于检查
   片段 0: target/test/output.temp-0.mp4
   片段 1: target/test/output.temp-1.mp4
   片段 2: target/test/output.temp-2.mp4
   片段 3: target/test/output.temp-3.mp4
```

然后可以逐个检查：
```bash
# 播放片段
open target/test/output.temp-0.mp4

# 检查编码参数
ffprobe target/test/output.temp-0.mp4
```

## 增量更新机制

mdcourse 使用 SHA-256 哈希值跟踪 SSML 内容变化：

1. 首次运行时生成所有音频
2. 再次运行时，只重新生成 SSML 内容发生变化的音频
3. 使用 `--force-audio` 强制重新生成所有音频

这大大加快了迭代速度，特别是在修改少量幻灯片时。

## 技术栈

- **Deno**: TypeScript 运行时，用于主逻辑
- **Marp CLI**: Markdown 转幻灯片图片
- **Shiki**: 代码语法高亮
- **Azure TTS SDK**: 文本转语音
- **ffmpeg**: 视频合成和转码

## 故障排除

### Marp 生成失败

确保安装了 Node.js 和 npm 依赖：
```bash
npm install
```

### TTS 失败

1. 检查环境变量是否设置：`echo $TTS_KEY`
2. 增加重试次数：`--retry 5`
3. 检查网络连接

### 视频合成失败

1. 确保安装了 ffmpeg：`ffmpeg -version`
2. 使用 `--keep-temp` 检查临时片段
3. 查看详细的 ffmpeg 错误输出

## 相关文档

- [DESIGN.md](./DESIGN.md) - 详细设计文档
- [NPM_PACKAGE.md](./NPM_PACKAGE.md) - npm 包发布指南
- [LOCAL_TEST.md](./LOCAL_TEST.md) - 本地测试指南

## License

MIT
