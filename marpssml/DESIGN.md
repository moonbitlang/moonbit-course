# Marp+SSML 视频生成工具设计文档

## 概述

从包含 Marp 幻灯片和 SSML 音频脚本的统一文档生成配音视频,支持增量更新。

## 输入格式

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

**说明**:
- 每页的 SSML 内容会被自动包装到 `<speak>` 和 `<voice>` 标签中
- 不需要手动添加 `<p>` 标签（工具会自动添加）

## Target 目录结构

```
target/
└── course7/
    ├── slides/
    │   ├── slide-001.png
    │   ├── slide-002.png
    │   └── ...
    ├── audio/
    │   ├── slide-001.wav      # 单页音频
    │   ├── slide-001.ssml     # 对应的 SSML
    │   ├── slide-001.meta.json # {duration: 5.2, hash: "abc123"}
    │   ├── slide-002.wav
    │   └── ...
    ├── slides.md              # 纯 Marp 内容
    ├── manifest.json          # 页面元数据列表
    └── output.mp4             # 最终视频
```

## 工作流程

### 1. 解析 (`parse.ts`)

- 读取 `.marp.md` 文件
- 按 `---` 分割页面
- 对每页:
  - 提取 Marp 内容
  - 提取 SSML 片段
  - 计算 SSML 内容哈希
- 生成:
  - `target/courseX/slides.md` (完整幻灯片)
  - `target/courseX/audio/slide-NNN.ssml` (每页单独的 SSML)
  - `target/courseX/manifest.json`:
    ```json
    {
      "slides": [
        {"id": "001", "ssmlHash": "abc123", "hasAudio": true},
        {"id": "002", "ssmlHash": "def456", "hasAudio": false}
      ]
    }
    ```

### 2. 生成幻灯片图片

- 使用 Marp CLI: `marp slides.md --images png -o target/courseX/slides/`
- 输出: `slide-001.png`, `slide-002.png`, ...

### 3. 增量生成音频 (`tts.ts`)

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
- 调用 Azure TTS SDK 生成 `slide-NNN.wav`
- 使用 ffprobe 获取音频时长
- 保存 `slide-NNN.meta.json`: `{duration: 5.2, hash: "abc123"}`

### 4. 合成视频 (`compose.ts`)

- 读取 `manifest.json` 和所有 `*.meta.json`
- 为每页创建 ffmpeg 输入:
  - 图片: `slide-NNN.png`
  - 音频: `slide-NNN.wav` (如有)
  - 时长: 从 `meta.json` 获取,无音频则默认 3 秒
- 使用 ffmpeg 合成:
  ```bash
  ffmpeg -loop 1 -t 5.2 -i slide-001.png \
         -loop 1 -t 3.8 -i slide-002.png \
         -i slide-001.wav -i slide-002.wav \
         -filter_complex "[0:v][1:v]concat=n=2:v=1[outv]; \
                          [2:a][3:a]concat=n=2:v=0:a=1[outa]" \
         -map "[outv]" -map "[outa]" output.mp4
  ```

## 技术栈

- **Deno**: 所有脚本（>= 2.0）
- **Node.js**: npm 包管理（>= 20.0）
- **Marp CLI**: 幻灯片渲染 (通过 `Deno.Command` 调用)
- **Azure TTS SDK**: 通过 npm: 方式导入到 Deno
- **ffmpeg**: 视频合成 (通过 `Deno.Command` 调用，需系统安装)

## 系统依赖

| 依赖 | 用途 | 安装方式 |
|------|------|----------|
| Deno >= 2.0 | 运行时环境 | [deno.land](https://deno.land) |
| Node.js >= 20.0 | npm 包管理 | [nodejs.org](https://nodejs.org) |
| ffmpeg | 视频合成 | macOS: `brew install ffmpeg`<br>Ubuntu: `sudo apt install ffmpeg`<br>Windows: [ffmpeg.org](https://ffmpeg.org) |

## 命令行接口

```bash
# 完整流程
deno run -A cli.ts course7/lec7.mbt.md

# 仅解析
deno run -A cli.ts course7/lec7.mbt.md --parse-only

# 仅生成音频(增量)
deno run -A cli.ts course7/lec7.mbt.md --audio-only

# 仅合成视频
deno run -A cli.ts course7/lec7.mbt.md --compose-only

# 强制重新生成所有音频
deno run -A cli.ts course7/lec7.mbt.md --force-audio
```

## 环境变量

- `TTS_KEY`: Azure TTS 订阅密钥
- `TTS_REGION`: Azure TTS 区域

## 增量更新逻辑

1. 用户修改某页的 SSML
2. 运行 `cli.ts`
3. 解析阶段计算新哈希
4. 音频生成阶段对比哈希,仅重新生成修改的页面
5. 合成阶段使用新旧混合的音频文件
