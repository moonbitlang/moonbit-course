#!/usr/bin/env -S deno run -A

import { parseArgs } from "@std/cli/parse-args";
import { dirname, join } from "@std/path";
import { parse, getCourseName } from "./parse.ts";
import { generateAudio } from "./tts.ts";
import { composeVideo } from "./compose.ts";

interface Options {
  output?: string;
  parseOnly?: boolean;
  audioOnly?: boolean;
  composeOnly?: boolean;
  slidesOnly?: boolean;
  forceAudio?: boolean;
  help?: boolean;
  voice?: string;
  fps?: number;
  defaultDuration?: number;
}

const HELP_TEXT = `
mdcourse - Marp+SSML 视频生成工具

用法:
  mdcourse <input.mbt.md> [选项]

选项:
  -o, --output <file>       输出视频文件路径 (默认: target/<course>/output.mp4)
  --parse-only              仅解析文件
  --slides-only             仅生成幻灯片图片
  --audio-only              仅生成音频
  --compose-only            仅合成视频
  --force-audio             强制重新生成所有音频
  --voice <name>            指定 TTS 语音 (默认: zh-CN-YunyiMultilingualNeural)
  --fps <number>            视频帧率 (默认: 30)
  --default-duration <sec>  无音频幻灯片的默认时长 (默认: 3.0)
  -h, --help                显示帮助信息

环境变量:
  TTS_KEY                   Azure TTS 订阅密钥
  TTS_REGION                Azure TTS 区域

示例:
  # 生成视频
  mdcourse my-slides.mbt.md -o video.mp4

  # 使用默认输出位置
  mdcourse course7/lec7.mbt.md

  # 仅生成幻灯片
  mdcourse my-slides.mbt.md --slides-only

  # 强制重新生成所有音频
  mdcourse my-slides.mbt.md --force-audio
`;

async function main() {
  const args = parseArgs(Deno.args, {
    boolean: [
      "parse-only",
      "audio-only",
      "compose-only",
      "slides-only",
      "force-audio",
      "help",
      "h",
    ],
    string: ["output", "o", "voice", "fps", "default-duration"],
    alias: { h: "help", o: "output" },
  });

  const options: Options = {
    output: args.output || args.o,
    parseOnly: args["parse-only"],
    audioOnly: args["audio-only"],
    composeOnly: args["compose-only"],
    slidesOnly: args["slides-only"],
    forceAudio: args["force-audio"],
    help: args.help,
    voice: args.voice,
    fps: args.fps ? parseInt(args.fps) : undefined,
    defaultDuration: args["default-duration"]
      ? parseFloat(args["default-duration"])
      : undefined,
  };

  if (options.help || args._.length === 0) {
    console.log(HELP_TEXT);
    Deno.exit(options.help ? 0 : 1);
  }

  const inputFile = args._[0] as string;
  const courseName = getCourseName(inputFile);
  const targetDir = join("target", courseName);

  console.log(`\n📚 处理课程: ${courseName}`);
  console.log(`📁 目标目录: ${targetDir}\n`);

  try {
    // 1. 解析（除非只合成视频）
    if (!options.composeOnly) {
      await parse(inputFile, targetDir);
      if (options.parseOnly) {
        console.log("\n✅ 完成（仅解析）");
        return;
      }
    }

    // 2. 生成幻灯片图片（除非只生成音频或只合成视频）
    if (!options.audioOnly && !options.composeOnly) {
      await generateSlides(targetDir);
      if (options.slidesOnly) {
        console.log("\n✅ 完成（仅生成幻灯片）");
        return;
      }
    }

    // 3. 生成音频
    if (!options.composeOnly && !options.slidesOnly) {
      await generateAudio(targetDir, {
        force: options.forceAudio,
        voice: options.voice,
      });
      if (options.audioOnly) {
        console.log("\n✅ 完成（仅生成音频）");
        return;
      }
    }

    // 4. 合成视频
    if (!options.parseOnly && !options.audioOnly && !options.slidesOnly) {
      await composeVideo(targetDir, {
        fps: options.fps,
        defaultDuration: options.defaultDuration,
      });

      // 如果指定了输出路径，移动文件
      if (options.output) {
        const defaultOutput = join(targetDir, "output.mp4");
        const targetOutput = options.output;

        // 创建输出目录（如果不存在）
        const outputDir = dirname(targetOutput);
        if (outputDir !== ".") {
          await Deno.mkdir(outputDir, { recursive: true });
        }

        await Deno.rename(defaultOutput, targetOutput);
        console.log(`\n✅ 全部完成！`);
        console.log(`📹 视频位置: ${targetOutput}`);
      } else {
        console.log("\n✅ 全部完成！");
        console.log(`📹 视频位置: ${join(targetDir, "output.mp4")}`);
      }
    }
  } catch (error) {
    const err = error as Error;
    console.error(`\n❌ 错误: ${err.message}`);
    if (err.stack) {
      console.error(err.stack);
    }
    Deno.exit(1);
  }
}

/**
 * 使用 Marp CLI 生成幻灯片图片
 */
async function generateSlides(targetDir: string) {
  console.log(`🖼️  生成幻灯片图片`);

  const slidesFile = join(targetDir, "slides.md");
  const slidesDir = join(targetDir, "slides");

  // 确保输出目录存在
  await Deno.mkdir(slidesDir, { recursive: true });

  // 调用 marp (使用默认主题，不依赖外部文件)
  const command = new Deno.Command("npx", {
    args: [
      "@marp-team/marp-cli",
      slidesFile,
      "--images",
      "png",
      "--allow-local-files",
      "--html",
    ],
    cwd: Deno.cwd(),
    stdout: "inherit",
    stderr: "inherit",
  });

  const { success } = await command.output();

  if (!success) {
    throw new Error("Marp 生成幻灯片失败");
  }

  // 移动和重命名文件（marp 生成的格式是 slides.001.png）
  await moveAndRenameSlides(targetDir, slidesDir);

  console.log(`   ✓ 幻灯片已生成`);
}

/**
 * 移动和重命名幻灯片文件为统一格式 slide-NNN.png
 */
async function moveAndRenameSlides(targetDir: string, slidesDir: string) {
  const entries = [];

  // 查找生成的图片文件（格式：slides.001.png, slides.002.png 等）
  for await (const entry of Deno.readDir(targetDir)) {
    if (entry.isFile && entry.name.match(/^slides\.\d+\.png$/)) {
      entries.push(entry.name);
    }
  }

  if (entries.length === 0) {
    console.warn("   ⚠️  警告: 没有找到生成的幻灯片图片");
    return;
  }

  // 排序
  entries.sort();

  // 移动并重命名
  for (let i = 0; i < entries.length; i++) {
    const oldName = entries[i];
    const slideId = (i + 1).toString().padStart(3, "0");
    const newName = `slide-${slideId}.png`;

    await Deno.rename(
      join(targetDir, oldName),
      join(slidesDir, newName)
    );
  }

  console.log(`   ✓ 已移动 ${entries.length} 张幻灯片图片`);
}

if (import.meta.main) {
  main();
}
