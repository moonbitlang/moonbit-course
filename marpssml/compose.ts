#!/usr/bin/env -S deno run -A

import { join } from "@std/path";

interface Manifest {
  slides: Array<{
    id: string;
    ssmlHash: string;
    hasAudio: boolean;
  }>;
}

interface AudioMeta {
  duration: number;
  hash: string;
}

interface VideoSegment {
  slideId: string;
  imagePath: string;
  audioPath?: string;
  duration: number;
}

/**
 * 合成视频
 */
export async function composeVideo(
  targetDir: string,
  options: { defaultDuration?: number; fps?: number } = {}
) {
  const { defaultDuration = 3.0, fps = 30 } = options;

  console.log(`🎬 合成视频: ${targetDir}`);

  // 检查 ffmpeg 是否安装
  try {
    const checkCommand = new Deno.Command("ffmpeg", {
      args: ["-version"],
      stdout: "null",
      stderr: "null",
    });
    const { success } = await checkCommand.output();
    if (!success) {
      throw new Error("ffmpeg 未正确安装");
    }
  } catch {
    throw new Error(
      "未找到 ffmpeg。请安装 ffmpeg：\n" +
      "  macOS: brew install ffmpeg\n" +
      "  Ubuntu: sudo apt install ffmpeg\n" +
      "  Windows: https://ffmpeg.org/download.html"
    );
  }

  // 读取 manifest
  const manifestFile = join(targetDir, "manifest.json");
  const manifest: Manifest = JSON.parse(await Deno.readTextFile(manifestFile));

  // 收集所有视频片段信息
  const segments: VideoSegment[] = [];

  for (const slide of manifest.slides) {
    const slideId = slide.id;
    const imagePath = join(targetDir, "slides", `slide-${slideId}.png`);
    const audioPath = slide.hasAudio
      ? join(targetDir, "audio", `slide-${slideId}.wav`)
      : undefined;
    const metaPath = slide.hasAudio
      ? join(targetDir, "audio", `slide-${slideId}.meta.json`)
      : undefined;

    // 检查图片是否存在
    try {
      await Deno.stat(imagePath);
    } catch {
      throw new Error(`图片不存在: ${imagePath}`);
    }

    // 获取时长
    let duration = defaultDuration;
    if (metaPath) {
      try {
        const meta: AudioMeta = JSON.parse(await Deno.readTextFile(metaPath));
        duration = meta.duration;
      } catch {
        console.warn(`   ⚠️  无法读取 ${slideId} 的元数据，使用默认时长`);
      }
    }

    segments.push({
      slideId,
      imagePath,
      audioPath,
      duration,
    });

    console.log(
      `   ✓ slide-${slideId}: ${duration.toFixed(2)}s ${audioPath ? "(有音频)" : "(静音)"}`
    );
  }

  // 生成 ffmpeg 命令
  const outputFile = join(targetDir, "output.mp4");
  await generateVideo(segments, outputFile, fps);

  console.log(`✅ 视频已生成: ${outputFile}`);
}

/**
 * 使用 ffmpeg 生成视频
 */
async function generateVideo(
  segments: VideoSegment[],
  outputFile: string,
  fps: number
) {
  console.log(`   🔧 正在使用 ffmpeg 合成视频...`);

  // 构建 ffmpeg concat 文件
  const concatFile = outputFile.replace(".mp4", ".concat.txt");
  const concatContent = await buildConcatFile(segments);
  await Deno.writeTextFile(concatFile, concatContent);

  // 构建 ffmpeg 命令
  // 策略：为每个片段创建临时视频，然后 concat
  const tempFiles: string[] = [];

  for (let i = 0; i < segments.length; i++) {
    const segment = segments[i];
    const tempFile = outputFile.replace(".mp4", `.temp-${i}.mp4`);
    tempFiles.push(tempFile);

    const ffmpegArgs = [
      "-loop",
      "1",
      "-framerate",
      fps.toString(),
      "-t",
      segment.duration.toString(),
      "-i",
      segment.imagePath,
    ];

    // 如果有音频，添加音频输入
    if (segment.audioPath) {
      ffmpegArgs.push("-i", segment.audioPath);
    }

    ffmpegArgs.push(
      "-c:v",
      "libx264",
      "-pix_fmt",
      "yuv420p",
      "-vf",
      "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2"
    );

    // 如果有音频，添加音频编码
    if (segment.audioPath) {
      ffmpegArgs.push("-c:a", "aac", "-shortest");
    } else {
      ffmpegArgs.push("-an"); // 无音频
    }

    ffmpegArgs.push("-y", tempFile);

    const command = new Deno.Command("ffmpeg", {
      args: ffmpegArgs,
      stdout: "piped",
      stderr: "piped",
    });

    const { success, stdout, stderr } = await command.output();
    if (!success) {
      const errorOutput = new TextDecoder().decode(stderr);
      console.error(`\n❌ ffmpeg 错误输出:\n${errorOutput}`);
      throw new Error(`生成临时视频失败: ${tempFile}`);
    }

    console.log(`   ✓ 已生成片段 ${i + 1}/${segments.length}`);
  }

  // 使用 concat 合并所有片段
  // 使用绝对路径以避免路径问题
  const absoluteTempFiles = tempFiles.map((f) => {
    if (f.startsWith("/")) {
      return f; // 已经是绝对路径
    }
    return join(Deno.cwd(), f);
  });
  const concatListContent = absoluteTempFiles.map((f) => `file '${f}'`).join("\n");
  const concatListFile = outputFile.replace(".mp4", ".list.txt");
  await Deno.writeTextFile(concatListFile, concatListContent);

  const concatCommand = new Deno.Command("ffmpeg", {
    args: [
      "-f",
      "concat",
      "-safe",
      "0",
      "-i",
      concatListFile,
      "-c",
      "copy",
      "-y",
      outputFile,
    ],
    stdout: "piped",
    stderr: "piped",
  });

  const { success, stderr } = await concatCommand.output();
  if (!success) {
    const errorOutput = new TextDecoder().decode(stderr);
    console.error(`\n❌ ffmpeg concat 错误输出:\n${errorOutput}`);
    throw new Error("合并视频失败");
  }

  // 清理临时文件
  for (const tempFile of tempFiles) {
    await Deno.remove(tempFile);
  }
  await Deno.remove(concatFile);
  await Deno.remove(concatListFile);
}

/**
 * 构建 ffmpeg concat 文件内容
 */
function buildConcatFile(segments: VideoSegment[]): string {
  const lines: string[] = [];
  for (const segment of segments) {
    lines.push(`file '${segment.imagePath}'`);
    lines.push(`duration ${segment.duration}`);
  }
  return lines.join("\n");
}

// 如果直接运行此文件
if (import.meta.main) {
  const args = Deno.args;

  if (args.length === 0) {
    console.error("用法: deno run -A compose.ts <target-dir>");
    Deno.exit(1);
  }

  const targetDir = args[0];

  try {
    await composeVideo(targetDir);
  } catch (error) {
    const err = error as Error;
    console.error("❌ 错误:", err.message);
    Deno.exit(1);
  }
}
