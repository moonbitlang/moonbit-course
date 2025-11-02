# Marp+SSML 视频生成工具设计文档

## 概述

从包含 Marp 幻灯片和 SSML 音频脚本的统一文档生成配音视频,支持增量更新、视频插入、自定义分辨率和自动重试。

## 核心特性

- ✅ **Marp 幻灯片转视频**: 自动将 Markdown 幻灯片转换为 PNG，生成视频
- ✅ **Azure TTS 配音**: 使用 SSML 为每页幻灯片添加语音
- ✅ **视频插入**: 在幻灯片之间插入视频片段，支持为视频添加配音
- ✅ **增量更新**: 基于 SSML 哈希值，只重新生成修改过的音频
- ✅ **自动重试**: TTS API 失败时自动重试，支持指数退避
- ✅ **多分辨率**: 支持 4K、1440p、1080p、720p、480p
- ✅ **代码高亮**: 自定义 Shiki 语法高亮，支持 MoonBit、ABNF、WASM 等
- ✅ **音频混合**: 视频配音与原视频音频自动混合
- ✅ **统一编码**: 所有片段使用相同的编码参数，确保无缝拼接

## 输入格式

### 基本幻灯片

```markdown
---
marp: true
---

# 第一页标题

<!-- ssml
这是第一页的配音文本<break time="500ms"/>
-->

- 内容1
- 内容2

---

# 第二页

<!-- ssml
这是第二页的配音<break time="1s"/>
-->
```

### 使用 headingDivider

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

```markdown
# 第二页

内容...

<!-- video my-video.mp4 -->

# 第三页
```

### 为视频添加配音

```markdown
# 第二页

内容...

<!-- video demo.mp4 -->
<!-- ssml
这是对这段视频的讲解
-->

# 第三页
```

**说明**:
- 每页的 SSML 内容会被自动包装到 `<speak>` 和 `<voice>` 标签中
- 不需要手动添加 `<p>` 标签（工具会自动添加）
- 视频配音会与原视频音频自动混合
- 最终时长为 `max(视频时长, 配音时长)`

## Target 目录结构

```
target/
└── course7/
    ├── slides/
    │   ├── slide-001.png
    │   ├── slide-002.png
    │   └── ...
    ├── audio/
    │   ├── slide-001.wav              # 单页音频
    │   ├── slide-001.ssml             # 对应的 SSML
    │   ├── slide-001.meta.json        # {duration: 5.2, hash: "abc123"}
    │   ├── slide-002.wav
    │   ├── video-after-002.wav        # 视频配音
    │   ├── video-after-002.ssml
    │   ├── video-after-002.meta.json
    │   └── ...
    ├── slides.md                      # 纯 Marp 内容
    ├── manifest.json                  # 页面元数据列表（包含视频信息）
    ├── output.mp4                     # 最终视频
    └── output.temp-*.mp4              # 临时片段（使用 --keep-temp 时保留）
```

## 工作流程

### 1. 解析 (`parse.ts`)

- 读取 `.mbt.md` 文件
- 解析 Marp frontmatter (检测 `headingDivider`)
- 按分隔符分割页面:
  - 如果指定 `headingDivider: N`，按 N 级标题分页
  - 否则按 `---` 分割
- 提取视频插入标记 (`<!-- video path.mp4 -->`)
- 对每页:
  - 提取 Marp 内容
  - 提取 SSML 片段
  - 计算 SSML 内容的 SHA-256 哈希
- 生成:
  - `target/courseX/slides.md` (完整幻灯片)
  - `target/courseX/audio/slide-NNN.ssml` (每页单独的 SSML)
  - `target/courseX/audio/video-after-NNN.ssml` (视频配音的 SSML)
  - `target/courseX/manifest.json`:
    ```json
    {
      "slides": [
        {"id": "001", "ssmlHash": "abc123", "hasAudio": true},
        {"id": "002", "ssmlHash": "def456", "hasAudio": false}
      ],
      "videos": [
        {
          "afterSlide": "002",
          "videoPath": "path/to/video.mp4",
          "ssmlHash": "xyz789",
          "hasAudio": true
        }
      ]
    }
    ```

### 2. 生成幻灯片图片 (`mdcourse.ts`)

- 使用自定义主题和引擎调用 Marp CLI:
  ```bash
  npx @marp-team/marp-cli \
    --theme custom.css \
    --engine engine.mjs \
    slides.md \
    --images png \
    --allow-local-files \
    --html
  ```
- 输出: `slides.001.png`, `slides.002.png`, ...
- 重命名为: `slide-001.png`, `slide-002.png`, ...
- **自定义引擎** (`engine.mjs`):
  - 使用 Shiki 语法高亮
  - 支持 MoonBit、ABNF、WASM 等自定义语法 (通过 `.tmLanguage.json`)
  - GitHub Light 主题配色

### 3. 增量生成音频 (`tts.ts`)

**幻灯片音频:**

对每个 slide:
- 读取 `slide-NNN.ssml`
- 检查 `slide-NNN.meta.json`:
  - 如果不存在或哈希不匹配 → 调用 TTS API 生成音频
  - 如果哈希匹配 → 跳过,复用已有音频
- 生成完整 SSML 文档:
  ```xml
  <speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN">
    <voice name="zh-CN-YunyiMultilingualNeural">
      <p>
        <!-- 这里是 slide-NNN.ssml 的内容 -->
      </p>
    </voice>
  </speak>
  ```
- **重试机制**: 调用 Azure TTS SDK 时使用指数退避重试
  - 默认重试 3 次（可配置 `--retry N`）
  - 延迟: 1秒 → 2秒 → 4秒 → 8秒 (最多 10秒)
- 生成 `slide-NNN.wav`
- 从 TTS 结果获取音频时长
- 保存 `slide-NNN.meta.json`: `{duration: 5.2, hash: "abc123"}`

**视频配音:**

对每个视频:
- 读取 `video-after-NNN.ssml`
- 使用相同的增量逻辑和重试机制
- 生成 `video-after-NNN.wav` 和元数据

### 4. 合成视频 (`compose.ts`)

**片段生成:**

根据 manifest，按顺序生成视频片段:

1. **幻灯片片段** (`generateSlideVideo`):
   - 输入: `slide-NNN.png` + `slide-NNN.wav` (可选)
   - 使用 ffmpeg 生成固定编码参数的视频片段
   - 输出: `output.temp-N.mp4`

2. **视频片段** (`processVideoSegment`):
   - 输入: 原视频 + `video-after-NNN.wav` (可选)
   - 使用 ffprobe 检测原视频是否有音频轨
   - 根据 4 种情况处理:
     - 有原音频 + 有配音 → 使用 `amix` 混合两路音频
     - 无原音频 + 有配音 → 使用配音
     - 有原音频 + 无配音 → 保留原音频
     - 无原音频 + 无配音 → 静音
   - 标准化分辨率 (letterbox padding)
   - 输出: `output.temp-N.mp4`

**统一编码参数:**

所有片段使用相同参数确保无缝拼接:
- 视频编码: H.264 (`libx264`)
- 像素格式: `yuv420p`
- 帧率: 30fps (可配置 `--fps N`)
- 音频编码: AAC (`aac`)
- 音频采样率: 44100Hz (`-ar 44100`)
- 分辨率: 1920×1080 (可配置 `--resolution preset`)
  - 支持: 4k, 1440p, 1080p, 720p, 480p

**最终合成:**

- 使用 ffmpeg concat demuxer 合并所有片段
- 生成 concat 列表文件 (使用绝对路径)
- 输出: `output.mp4`

**调试模式:**

- 使用 `--keep-temp` 保留所有 `output.temp-*.mp4` 片段
- 失败时显示完整 ffmpeg 错误输出

## 技术栈

- **Deno** >= 2.0: TypeScript 运行时，主应用逻辑
- **Node.js** >= 20.0: npm 包管理和 Marp CLI
- **Marp CLI** (^3.4.0): Markdown 幻灯片渲染
- **Shiki** (^1.0.0): 语法高亮库
- **Azure TTS SDK**: 微软认知服务 Speech SDK (通过 npm: 导入)
- **ffmpeg/ffprobe**: 视频处理和元数据提取 (系统安装)

## 系统依赖

| 依赖 | 用途 | 安装方式 |
|------|------|----------|
| Deno >= 2.0 | 运行时环境 | [deno.land](https://deno.land) |
| Node.js >= 20.0 | npm 包管理 | [nodejs.org](https://nodejs.org) |
| ffmpeg | 视频合成 | macOS: `brew install ffmpeg`<br>Ubuntu: `sudo apt install ffmpeg`<br>Windows: [ffmpeg.org](https://ffmpeg.org) |

## 命令行接口

```bash
# 完整流程（使用 npm 全局安装）
mdcourse course7/lec7.mbt.md -o output.mp4

# 指定分辨率和重试次数
mdcourse slides.mbt.md --resolution 720p --retry 5

# 仅解析
mdcourse slides.mbt.md --parse-only

# 仅生成幻灯片
mdcourse slides.mbt.md --slides-only

# 仅生成音频（增量）
mdcourse slides.mbt.md --audio-only

# 仅合成视频
mdcourse slides.mbt.md --compose-only

# 强制重新生成所有音频
mdcourse slides.mbt.md --force-audio

# 调试模式：保留临时片段
mdcourse slides.mbt.md --keep-temp

# 使用自定义 TTS 语音
mdcourse slides.mbt.md --voice zh-CN-XiaoxiaoNeural

# 自定义帧率和默认时长
mdcourse slides.mbt.md --fps 60 --default-duration 5.0
```

## 完整选项列表

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `-o, --output <file>` | 输出视频文件路径 | `target/<course>/output.mp4` |
| `--parse-only` | 仅解析文件 | - |
| `--slides-only` | 仅生成幻灯片图片 | - |
| `--audio-only` | 仅生成音频 | - |
| `--compose-only` | 仅合成视频 | - |
| `--force-audio` | 强制重新生成所有音频 | - |
| `--keep-temp` | 保留临时视频片段文件用于调试 | - |
| `--voice <name>` | 指定 TTS 语音 | `zh-CN-YunyiMultilingualNeural` |
| `--fps <number>` | 视频帧率 | `30` |
| `--resolution <preset>` | 视频分辨率 (4k, 1440p, 1080p, 720p, 480p) | `1080p` |
| `--retry <number>` | TTS API 失败时的重试次数 | `3` |
| `--default-duration <sec>` | 无音频幻灯片的默认时长（秒） | `3.0` |
| `-h, --help` | 显示帮助信息 | - |

## 环境变量

- `TTS_KEY`: Azure TTS 订阅密钥
- `TTS_REGION`: Azure TTS 区域

## 增量更新逻辑

mdcourse 使用 SHA-256 哈希值跟踪 SSML 内容变化：

1. **首次运行**: 生成所有音频文件和元数据
2. **修改 SSML**: 用户修改某页的 SSML 内容
3. **解析阶段**: 计算新的 SHA-256 哈希值
4. **音频生成阶段**:
   - 对比 `meta.json` 中的哈希值
   - 仅重新生成哈希不匹配的音频
   - 跳过未修改的音频（复用已有文件）
5. **合成阶段**: 使用新旧混合的音频文件

**优势**:
- 大大加快迭代速度
- 减少 TTS API 调用次数
- 节省时间和成本

**强制更新**:
- 使用 `--force-audio` 忽略哈希值，重新生成所有音频

## 关键技术细节

### headingDivider 支持

Marp 的 `headingDivider` 功能允许通过标题级别自动分页：

```typescript
// 检测 headingDivider 配置
const headingDividerMatch = frontmatter.match(/headingDivider:\s*(\d+)/);
if (headingDividerMatch) {
  headingLevel = parseInt(headingDividerMatch[1]);
}

// 动态生成正则表达式匹配对应级别的标题
const headingPattern = new RegExp(`^${"#".repeat(headingLevel)}\\s+`, "gm");
```

### 视频音频检测

使用 ffprobe 检测视频是否包含音频轨：

```typescript
async function hasAudioStream(videoPath: string): Promise<boolean> {
  const command = new Deno.Command("ffprobe", {
    args: [
      "-v", "error",
      "-select_streams", "a:0",
      "-show_entries", "stream=codec_type",
      "-of", "default=noprint_wrappers=1:nokey=1",
      videoPath
    ],
    stdout: "piped",
    stderr: "piped",
  });

  const { stdout } = await command.output();
  const output = new TextDecoder().decode(stdout).trim();
  return output === "audio";
}
```

### 音频混合策略

根据原视频和配音的存在情况，使用不同的 ffmpeg 参数：

| 原视频音频 | TTS 配音 | ffmpeg 处理 |
|-----------|---------|------------|
| ✅ | ✅ | `amix=inputs=2:duration=longest` |
| ❌ | ✅ | 直接使用配音轨 |
| ✅ | ❌ | 保留原音频 |
| ❌ | ❌ | 静音视频 |

### 编码参数统一

确保所有片段使用相同参数以支持 concat demuxer:

```bash
# 幻灯片片段
ffmpeg -loop 1 -t <duration> -i slide.png \
  -i audio.wav \
  -c:v libx264 -pix_fmt yuv420p -r <fps> \
  -c:a aac -ar 44100 \
  -vf "scale=..." \
  output.temp-N.mp4

# 视频片段
ffmpeg -i video.mp4 -i voiceover.wav \
  -filter_complex "[0:a][1:a]amix=inputs=2:duration=longest[aout]" \
  -map 0:v -map "[aout]" \
  -c:v libx264 -pix_fmt yuv420p -r <fps> \
  -c:a aac -ar 44100 \
  -vf "scale=..." \
  output.temp-N.mp4
```

### 指数退避重试

TTS API 调用失败时的重试策略：

```typescript
for (let attempt = 1; attempt <= maxRetries; attempt++) {
  try {
    return await synthesizeSpeech(...);
  } catch (error) {
    if (attempt < maxRetries) {
      const delay = Math.min(1000 * Math.pow(2, attempt - 1), 10000);
      console.log(`⚠️ 尝试 ${attempt}/${maxRetries} 失败`);
      console.log(`⏳ ${delay}ms 后重试...`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}
```

延迟序列: 1000ms → 2000ms → 4000ms → 8000ms (最多 10000ms)

## 故障排除

### 常见问题

1. **Marp 生成失败**
   - 检查 Node.js 和 npm 依赖是否安装
   - 运行 `npm install`

2. **TTS 失败**
   - 检查环境变量: `echo $TTS_KEY`
   - 增加重试次数: `--retry 5`
   - 检查网络连接

3. **视频合成失败**
   - 确保 ffmpeg 已安装: `ffmpeg -version`
   - 使用 `--keep-temp` 检查临时片段
   - 查看 ffmpeg 错误输出（自动显示）

4. **代码高亮不正确**
   - 确保 `engine.mjs` 和 `custom.css` 存在
   - 检查 `.tmLanguage.json` 语法文件

5. **片段编码不兼容**
   - 所有片段会自动使用统一编码参数
   - 如仍有问题，检查 ffmpeg 版本

## 相关文档

- [README.md](./README.md) - 用户使用指南
- [NPM_PACKAGE.md](./NPM_PACKAGE.md) - npm 包发布流程
- [LOCAL_TEST.md](./LOCAL_TEST.md) - 本地开发测试

## License

MIT
