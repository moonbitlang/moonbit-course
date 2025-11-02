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
  keepTemp?: boolean;
  help?: boolean;
  voice?: string;
  fps?: number;
  defaultDuration?: number;
  resolution?: string;
  retry?: number;
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
  --keep-temp               保留临时视频片段文件用于调试
  --voice <name>            指定 TTS 语音 (默认: zh-CN-YunyiMultilingualNeural)
  --fps <number>            视频帧率 (默认: 30)
  --resolution <preset>     视频分辨率 (默认: 1080p)
                            可选: 4k, 1440p, 1080p, 720p, 480p
  --retry <number>          TTS API 失败时的重试次数 (默认: 3)
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
      "keep-temp",
      "help",
      "h",
    ],
    string: ["output", "o", "voice", "fps", "default-duration", "resolution", "retry"],
    alias: { h: "help", o: "output" },
  });

  const options: Options = {
    output: args.output || args.o,
    parseOnly: args["parse-only"],
    audioOnly: args["audio-only"],
    composeOnly: args["compose-only"],
    slidesOnly: args["slides-only"],
    forceAudio: args["force-audio"],
    keepTemp: args["keep-temp"],
    help: args.help,
    voice: args.voice,
    fps: args.fps ? parseInt(args.fps) : undefined,
    resolution: args.resolution,
    retry: args.retry ? parseInt(args.retry) : undefined,
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
      await generateSlides(inputFile, targetDir);
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
        retry: options.retry,
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
        keepTemp: options.keepTemp,
        resolution: options.resolution,
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
async function generateSlides(inputFile: string, targetDir: string) {
  console.log(`🖼️  生成幻灯片图片`);

  const slidesDir = join(targetDir, "slides");

  // 确保输出目录存在
  await Deno.mkdir(slidesDir, { recursive: true });

  // 查找自定义主题和引擎文件
  // 优先从当前工作目录查找，如果不存在则从 npm 包目录查找
  const customCSS = await findAsset("custom.css");
  const engineJS = await findAsset("engine.mjs");

  // 生成 PDF 文件路径
  const pdfFile = join(targetDir, "slides.pdf");

  // 步骤 1: 使用 Marp 生成 PDF
  console.log(`   生成 PDF...`);
  const marpCommand = new Deno.Command("npx", {
    args: [
      "@marp-team/marp-cli",
      "--theme",
      customCSS,
      "--engine",
      engineJS,
      inputFile,
      "--pdf",
      "--allow-local-files",
      "--html",
      "-o",
      pdfFile,
    ],
    cwd: Deno.cwd(),
    stdout: "inherit",
    stderr: "inherit",
  });

  const { success: marpSuccess } = await marpCommand.output();

  if (!marpSuccess) {
    throw new Error("Marp 生成 PDF 失败");
  }

  // 步骤 2: 使用 pdftoppm 将 PDF 转换为 PNG
  console.log(`   转换 PDF 到 PNG...`);
  const pdftoppmCommand = new Deno.Command("pdftoppm", {
    args: [
      "-png",
      "-r", "300",  // 300 DPI 分辨率
      pdfFile,
      join(slidesDir, "slide"),
    ],
    stdout: "inherit",
    stderr: "inherit",
  });

  const { success: pdfSuccess } = await pdftoppmCommand.output();

  if (!pdfSuccess) {
    throw new Error("pdftoppm 转换失败");
  }

  // 步骤 3: 重命名文件（pdftoppm 生成的格式是 slide-1.png, slide-2.png）
  await renameSlides(slidesDir);

  console.log(`   ✓ 幻灯片已生成`);
}

/**
 * 重命名幻灯片文件为统一格式 slide-NNN.png
 * pdftoppm 生成的格式是 slide-1.png, slide-2.png, ..., slide-10.png（无前导零）
 */
async function renameSlides(slidesDir: string) {
  const newEntries = [];  // pdftoppm 生成的文件（无前导零）
  const oldEntries = [];  // 之前已有的文件（有前导零）

  // 分类文件
  for await (const entry of Deno.readDir(slidesDir)) {
    if (!entry.isFile || !entry.name.endsWith('.png')) continue;

    // pdftoppm 格式：slide-1.png (数字部分无前导零)
    const newMatch = entry.name.match(/^slide-(\d{1,2})\.png$/);
    if (newMatch) {
      newEntries.push({ name: entry.name, num: parseInt(newMatch[1]) });
      continue;
    }

    // 旧格式：slide-001.png (数字部分有前导零)
    const oldMatch = entry.name.match(/^slide-(\d{3,})\.png$/);
    if (oldMatch) {
      oldEntries.push(entry.name);
    }
  }

  if (newEntries.length === 0) {
    console.warn("   ⚠️  警告: 没有找到 pdftoppm 生成的幻灯片图片");
    return;
  }

  // 按数字排序
  newEntries.sort((a, b) => a.num - b.num);

  // 第一步：删除所有旧文件，避免冲突
  for (const oldFile of oldEntries) {
    await Deno.remove(join(slidesDir, oldFile));
  }

  // 第二步：重命名新文件为标准格式
  for (let i = 0; i < newEntries.length; i++) {
    const oldName = newEntries[i].name;
    const slideId = (i + 1).toString().padStart(3, "0");
    const newName = `slide-${slideId}.png`;

    await Deno.rename(
      join(slidesDir, oldName),
      join(slidesDir, newName)
    );
  }

  console.log(`   ✓ 已转换 ${newEntries.length} 张幻灯片图片`);
}

/**
 * 查找资源文件（优先当前目录，其次 npm 包目录）
 */
async function findAsset(filename: string): Promise<string> {
  // 1. 尝试当前工作目录
  const cwdPath = join(Deno.cwd(), filename);
  try {
    await Deno.stat(cwdPath);
    return cwdPath;
  } catch {
    // 文件不存在，继续尝试其他位置
  }

  // 2. 尝试可执行文件所在目录（适用于开发环境）
  try {
    const execPath = Deno.execPath();
    const execDir = dirname(execPath);
    const execDirPath = join(execDir, filename);
    await Deno.stat(execDirPath);
    return execDirPath;
  } catch {
    // 文件不存在，继续尝试其他位置
  }

  // 3. 尝试 npm 全局包目录
  // 通过 npm root -g 获取全局包根目录
  try {
    const command = new Deno.Command("npm", {
      args: ["root", "-g"],
      stdout: "piped",
      stderr: "piped",
    });
    const { success, stdout } = await command.output();
    if (success) {
      const npmRoot = new TextDecoder().decode(stdout).trim();
      const npmPath = join(npmRoot, "mdcourse", filename);
      await Deno.stat(npmPath);
      return npmPath;
    }
  } catch {
    // 无法获取 npm root 或文件不存在
  }

  // 4. 如果都找不到，返回当前目录的相对路径（让 marp 报错）
  throw new Error(
    `无法找到 ${filename}。请确保文件在当前目录，或 mdcourse 已通过 npm 正确安装。`
  );
}

if (import.meta.main) {
  main();
}
