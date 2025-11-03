# mdcourse - Marp + SSML Video Generation Tool

Generate educational videos from Marp markdown presentations with text-to-speech narration.

## Installation

### Prerequisites

1. **System Tools**:
   ```bash
   # macOS
   brew install ffmpeg poppler

   # Ubuntu/Debian
   sudo apt install ffmpeg poppler-utils

   # Windows
   # Install ffmpeg from https://ffmpeg.org/download.html
   # Install poppler from https://blog.alivate.com.au/poppler-windows/
   ```

2. **Node.js & Marp CLI**:
   ```bash
   npm install -g @marp-team/marp-cli
   ```

3. **MoonBit Toolchain**:
   ```bash
   # Install MoonBit from https://www.moonbitlang.com/
   curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
   ```

### Build mdcourse

```bash
cd mdcourse
moon install  # Install dependencies
moon build    # Build the binary
```

### Install System-Wide (Recommended)

Run the installer script to install mdcourse to `~/.local/bin`:

```bash
./install.sh
```

This will:
- Build the native binary
- Install to `~/.mdcourse/` with all resources (engine.mjs, custom.css, etc.)
- Create a wrapper script in `~/.local/bin/mdcourse`
- Make the `mdcourse` command available system-wide

After installation, you can run:

```bash
mdcourse input.mbt.md
```

**Uninstall:**
```bash
rm -rf ~/.mdcourse
rm ~/.local/bin/mdcourse
```

### Development Usage (Without Installation)

If you're developing mdcourse, you can run it directly without installation:

```bash
cd mdcourse
moon run cmd/main -- ../course7/lec7-1.mbt.md
```

Make sure `engine.mjs` and `custom.css` are in the parent directory (`../`).

### Azure TTS Setup

Set up environment variables for text-to-speech:

```bash
export TTS_KEY="your-azure-subscription-key"
export TTS_REGION="eastus"  # or your preferred region
```

Get your Azure credentials from [Azure Cognitive Services](https://azure.microsoft.com/en-us/services/cognitive-services/text-to-speech/).

## Usage

### Basic Usage

```bash
# Generate complete video with audio
moon run cmd/main -- input.mbt.md

# Specify output file
moon run cmd/main -- -o output.mp4 input.mbt.md
```

### Partial Generation

```bash
# Only parse markdown and extract SSML
moon run cmd/main -- --parse-only input.mbt.md

# Only generate slide images
moon run cmd/main -- --slides-only input.mbt.md

# Only generate audio (requires previous parse)
moon run cmd/main -- --audio-only input.mbt.md

# Only compose video (requires slides + audio)
moon run cmd/main -- --compose-only input.mbt.md
```

### Options

```bash
-o, --output FILE          Output video file (default: ./output.mp4)
-v, --voice NAME           TTS voice (default: zh-CN-YunyiMultilingualNeural)
-p, --resolution PRESET    Video resolution: 4k, 1440p, 1080p, 720p, 480p (default: 1080p)
-f, --fps N                Frame rate (default: 30)
-r, --retry N              TTS retry count (default: 3)
-d, --default-duration S   Default slide duration in seconds (default: 3.0)
-F, --force-audio          Regenerate all audio files
-K, --keep-temp            Keep temporary video segments
```

### Example

```bash
# Generate 4K video with custom voice
moon run cmd/main -- \
  -p 4k \
  -v zh-CN-XiaoxiaoNeural \
  -o course7-video.mp4 \
  ../course7/lec7-1.mbt.md
```

## Writing Course Content

### Basic Structure

Create a Marp markdown file with `.mbt.md` extension:

```markdown
---
marp: true
theme: custom
headingDivider: 1
---

# Slide Title

Slide content here.

<!-- ssml
这是第一页的旁白文字。
-->

# Another Slide

More content.

<!-- ssml
这是第二页的旁白文字。
-->
```

### SSML Narration

Add narration using HTML comments with `ssml` keyword:

```markdown
<!-- ssml
普通文字会被朗读。
<break time="500ms"/>
可以使用 SSML 标签来控制语音。
-->
```

### Inserting Videos

Insert video clips between slides:

```markdown
# Slide Before Video

Content here.

<!-- video path/to/video.mp4 -->

# Slide After Video

More content.
```

Add narration to videos (optional):

```markdown
<!-- video path/to/video.mp4 -->
<!-- ssml
这是视频的配音。
-->
```

### Slide Splitting

**Option 1: Manual dividers** - Use `---` to separate slides:

```markdown
---
marp: true
---

# First Slide

Content.

---

# Second Slide

More content.
```

**Option 2: Automatic splitting** - Use `headingDivider: 1` to split on `#` headings:

```markdown
---
marp: true
headingDivider: 1
---

# First Slide

Content.

# Second Slide

More content.
```

### SSML Features

Common SSML tags supported by Azure TTS:

```xml
<!-- ssml
这是<emphasis>强调</emphasis>的文字。
<break time="1s"/>
暂停一秒。
<prosody rate="slow">慢速朗读。</prosody>
<prosody pitch="+10%">提高音调。</prosody>
-->
```

See [Azure SSML documentation](https://learn.microsoft.com/en-us/azure/cognitive-services/speech-service/speech-synthesis-markup) for full reference.

## Output Structure

After running mdcourse, you'll get:

```
mdcoursetarget/
└── course-name/
    ├── manifest.json           # Slide and video metadata
    ├── audio/
    │   ├── slide-001.ssml     # Original SSML content
    │   ├── slide-001.wav      # Generated audio
    │   ├── slide-001.meta.json # Audio duration metadata
    │   └── ...
    ├── slides/
    │   ├── slide-001.png      # Slide images (300 DPI)
    │   └── ...
    ├── segments/              # Temporary video segments (if --keep-temp)
    │   ├── segment-001.mp4
    │   └── ...
    └── output.mp4             # Final video
```

## Tips

1. **Audio Caching**: Audio files are cached by content hash. Only modified slides will regenerate audio.
2. **Incremental Builds**: Use stage flags (`--parse-only`, `--slides-only`, etc.) for faster iteration.
3. **Custom Themes**: Place your Marp theme CSS in the project root as `custom.css`.
4. **Custom Engine**: Customize Marp behavior by editing `engine.mjs`.
5. **Large Videos**: Use `--keep-temp` to debug if video composition fails.
6. **Output Directory**: All generated files go to `./mdcoursetarget/` to keep them separate from build artifacts.

## Troubleshooting

**Problem**: Audio generation fails with TTS_KEY error
- **Solution**: Make sure `TTS_KEY` and `TTS_REGION` environment variables are set

**Problem**: Marp CLI not found
- **Solution**: Install with `npm install -g @marp-team/marp-cli`

**Problem**: pdftoppm not found
- **Solution**: Install poppler-utils (contains pdftoppm)

**Problem**: ffmpeg not found
- **Solution**: Install ffmpeg via your package manager

**Problem**: Video has wrong slide numbering
- **Solution**: Check `headingDivider` setting in frontmatter matches your slide structure

## License

Same as parent repository (see top-level LICENSE).
