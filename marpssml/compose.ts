#!/usr/bin/env -S deno run -A

import { join } from "@std/path";

interface Manifest {
  slides: Array<{
    id: string;
    ssmlHash: string;
    hasAudio: boolean;
  }>;
  videos: Array<{
    afterSlide: string;
    videoPath: string;
    ssmlHash: string;
    hasAudio: boolean;
  }>;
}

interface AudioMeta {
  duration: number;
  hash: string;
}

interface CompositionSegment {
  type: "slide" | "video";
  slideId?: string;
  imagePath?: string;
  audioPath?: string;
  videoPath?: string;
  duration: number;
}

/**
 * 合成视频
 */
export async function composeVideo(
  targetDir: string,
  options: {
    defaultDuration?: number;
    fps?: number;
    keepTemp?: boolean;
    resolution?: string;
  } = {}
) {
  const { defaultDuration = 3.0, fps = 30, keepTemp = false, resolution = "1080p" } = options;

  // 解析分辨率预设
  const resolutionMap: Record<string, { width: number; height: number }> = {
    "4k": { width: 3840, height: 2160 },
    "1440p": { width: 2560, height: 1440 },
    "1080p": { width: 1920, height: 1080 },
    "720p": { width: 1280, height: 720 },
    "480p": { width: 854, height: 480 },
  };

  const res = resolutionMap[resolution.toLowerCase()] || resolutionMap["1080p"];
  console.log(`🎬 合成视频: ${targetDir} (${res.width}x${res.height})`);

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

  // 收集所有合成片段（幻灯片 + 视频）
  const segments: CompositionSegment[] = [];

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
      type: "slide",
      slideId,
      imagePath,
      audioPath,
      duration,
    });

    console.log(
      `   ✓ slide-${slideId}: ${duration.toFixed(2)}s ${audioPath ? "(有音频)" : "(静音)"}`
    );

    // 检查是否有视频要在这一页后插入
    const videoAfterSlide = manifest.videos.find((v) => v.afterSlide === slideId);
    if (videoAfterSlide) {
      // 获取视频时长
      const videoDuration = await getVideoDuration(videoAfterSlide.videoPath);

      // 检查是否有视频配音
      const videoAudioPath = videoAfterSlide.hasAudio
        ? join(targetDir, "audio", `video-after-${slideId}.wav`)
        : undefined;
      const videoMetaPath = videoAfterSlide.hasAudio
        ? join(targetDir, "audio", `video-after-${slideId}.meta.json`)
        : undefined;

      // 获取音频时长
      let audioDuration = 0;
      if (videoMetaPath) {
        try {
          const meta: AudioMeta = JSON.parse(await Deno.readTextFile(videoMetaPath));
          audioDuration = meta.duration;
        } catch {
          console.warn(`   ⚠️  无法读取视频配音元数据`);
        }
      }

      // 使用更长的时长
      const finalDuration = Math.max(videoDuration, audioDuration);

      segments.push({
        type: "video",
        videoPath: videoAfterSlide.videoPath,
        audioPath: videoAudioPath,
        duration: finalDuration,
      });

      if (videoAudioPath) {
        console.log(
          `   📹 插入视频: ${videoAfterSlide.videoPath} (${videoDuration.toFixed(2)}s 视频 + ${audioDuration.toFixed(2)}s 音频 = ${finalDuration.toFixed(2)}s)`
        );
      } else {
        console.log(
          `   📹 插入视频: ${videoAfterSlide.videoPath} (${videoDuration.toFixed(2)}s)`
        );
      }
    }
  }

  // 生成 ffmpeg 命令
  const outputFile = join(targetDir, "output.mp4");
  await generateVideo(segments, outputFile, fps, keepTemp, res);

  console.log(`✅ 视频已生成: ${outputFile}`);
}

/**
 * 使用 ffmpeg 生成视频
 */
async function generateVideo(
  segments: CompositionSegment[],
  outputFile: string,
  fps: number,
  keepTemp: boolean,
  resolution: { width: number; height: number }
) {
  console.log(`   🔧 正在使用 ffmpeg 合成视频...`);

  // 策略：为每个片段创建临时视频，然后 concat
  const tempFiles: string[] = [];

  for (let i = 0; i < segments.length; i++) {
    const segment = segments[i];
    const tempFile = outputFile.replace(".mp4", `.temp-${i}.mp4`);
    tempFiles.push(tempFile);

    if (segment.type === "slide") {
      // 处理幻灯片片段
      console.log(`   🎬 片段 ${i}: 幻灯片 ${segment.slideId}, 时长=${segment.duration.toFixed(2)}s, 音频=${segment.audioPath ? 'yes' : 'no'}`);
      await generateSlideVideo(segment, tempFile, fps, resolution);
    } else {
      // 处理视频片段
      console.log(`   🎬 片段 ${i}: 视频 ${segment.videoPath}, 时长=${segment.duration.toFixed(2)}s, 配音=${segment.audioPath ? 'yes' : 'no'}`);
      await processVideoSegment(segment, tempFile, fps, resolution);
    }

    console.log(`   ✓ 已生成片段 ${i + 1}/${segments.length}: ${tempFile}`);
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

  // 根据 keepTemp 选项决定是否清理临时文件
  if (keepTemp) {
    console.log(`   ℹ️  保留了 ${tempFiles.length} 个临时片段文件用于检查`);
    for (let i = 0; i < tempFiles.length; i++) {
      console.log(`      片段 ${i}: ${tempFiles[i]}`);
    }
  } else {
    // 清理临时文件
    for (const tempFile of tempFiles) {
      await Deno.remove(tempFile);
    }
    await Deno.remove(concatListFile);
  }
}

/**
 * 生成幻灯片视频片段
 */
async function generateSlideVideo(
  segment: CompositionSegment,
  outputFile: string,
  fps: number,
  resolution: { width: number; height: number }
) {
  const ffmpegArgs = [
    "-loop",
    "1",
    "-framerate",
    fps.toString(),
    "-t",
    segment.duration.toString(),
    "-i",
    segment.imagePath!,
  ];

  // 如果有音频，添加音频输入
  if (segment.audioPath) {
    ffmpegArgs.push("-i", segment.audioPath);
  }

  const scaleFilter = `scale=${resolution.width}:${resolution.height}:force_original_aspect_ratio=decrease,pad=${resolution.width}:${resolution.height}:(ow-iw)/2:(oh-ih)/2`;

  ffmpegArgs.push(
    "-c:v",
    "libx264",
    "-pix_fmt",
    "yuv420p",
    "-vf",
    scaleFilter
  );

  // 如果有音频，添加音频编码
  if (segment.audioPath) {
    ffmpegArgs.push(
      "-c:a",
      "aac",
      "-ar",
      "44100",  // 统一音频采样率
      "-shortest"
    );
  } else {
    ffmpegArgs.push("-an"); // 无音频
  }

  ffmpegArgs.push("-y", outputFile);

  const command = new Deno.Command("ffmpeg", {
    args: ffmpegArgs,
    stdout: "piped",
    stderr: "piped",
  });

  const { success, stderr } = await command.output();
  if (!success) {
    const errorOutput = new TextDecoder().decode(stderr);
    console.error(`\n❌ ffmpeg 错误输出:\n${errorOutput}`);
    throw new Error(`生成幻灯片视频失败: ${outputFile}`);
  }
}

/**
 * 处理视频片段 - 转码以确保格式兼容，可选添加音频
 */
async function processVideoSegment(
  segment: CompositionSegment,
  outputFile: string,
  fps: number,
  resolution: { width: number; height: number }
) {
  const ffmpegArgs = ["-i", segment.videoPath!];

  // 检查视频是否有音频轨道
  const videoHasAudio = await hasAudioStream(segment.videoPath!);

  // 如果有配音音频，添加音频输入
  if (segment.audioPath) {
    ffmpegArgs.push("-i", segment.audioPath);
  }

  // 获取原始视频时长
  const originalVideoDuration = await getVideoDuration(segment.videoPath!);

  // 视频滤镜：循环播放视频直到达到目标时长
  let videoFilter = `scale=${resolution.width}:${resolution.height}:force_original_aspect_ratio=decrease,pad=${resolution.width}:${resolution.height}:(ow-iw)/2:(oh-ih)/2`;

  if (segment.duration > originalVideoDuration) {
    // 如果目标时长大于视频时长，循环播放视频
    const loopCount = Math.ceil(segment.duration / originalVideoDuration);
    videoFilter = `loop=loop=${loopCount}:size=1:start=0,${videoFilter}`;
  }

  ffmpegArgs.push(
    "-t",
    segment.duration.toString(),
    "-r",
    fps.toString(),  // 强制设置输出帧率
    "-c:v",
    "libx264",
    "-pix_fmt",
    "yuv420p",
    "-vf",
    videoFilter
  );

  // 音频处理策略
  if (segment.audioPath && videoHasAudio) {
    // 情况1: 视频有音频 + 有配音 -> 混合两个音频
    ffmpegArgs.push(
      "-filter_complex",
      "[0:a][1:a]amix=inputs=2:duration=longest[aout]",
      "-map",
      "0:v",
      "-map",
      "[aout]",
      "-c:a",
      "aac",
      "-ar",
      "44100"  // 统一音频采样率
    );
  } else if (segment.audioPath && !videoHasAudio) {
    // 情况2: 视频无音频 + 有配音 -> 使用配音作为音频
    ffmpegArgs.push(
      "-map",
      "0:v",
      "-map",
      "1:a",
      "-c:a",
      "aac",
      "-ar",
      "44100"  // 统一音频采样率
    );
  } else if (!segment.audioPath && videoHasAudio) {
    // 情况3: 视频有音频 + 无配音 -> 保持原音频
    ffmpegArgs.push(
      "-c:a",
      "aac",
      "-ar",
      "44100"  // 统一音频采样率
    );
  } else {
    // 情况4: 视频无音频 + 无配音 -> 无音频输出
    ffmpegArgs.push("-an");
  }

  ffmpegArgs.push("-y", outputFile);

  const command = new Deno.Command("ffmpeg", {
    args: ffmpegArgs,
    stdout: "piped",
    stderr: "piped",
  });

  const { success, stderr } = await command.output();
  if (!success) {
    const errorOutput = new TextDecoder().decode(stderr);
    console.error(`\n❌ ffmpeg 错误输出:\n${errorOutput}`);
    throw new Error(`处理视频片段失败: ${segment.videoPath}`);
  }
}

/**
 * 获取视频时长（秒）
 */
async function getVideoDuration(videoPath: string): Promise<number> {
  const command = new Deno.Command("ffprobe", {
    args: [
      "-v",
      "error",
      "-show_entries",
      "format=duration",
      "-of",
      "default=noprint_wrappers=1:nokey=1",
      videoPath,
    ],
    stdout: "piped",
    stderr: "piped",
  });

  const { success, stdout, stderr } = await command.output();
  if (!success) {
    const errorOutput = new TextDecoder().decode(stderr);
    throw new Error(`无法获取视频时长: ${videoPath}\n${errorOutput}`);
  }

  const durationStr = new TextDecoder().decode(stdout).trim();
  const duration = parseFloat(durationStr);

  if (isNaN(duration)) {
    throw new Error(`无效的视频时长: ${videoPath}`);
  }

  return duration;
}

/**
 * 检查视频是否有音频流
 */
async function hasAudioStream(videoPath: string): Promise<boolean> {
  const command = new Deno.Command("ffprobe", {
    args: [
      "-v",
      "error",
      "-select_streams",
      "a:0",
      "-show_entries",
      "stream=codec_type",
      "-of",
      "default=noprint_wrappers=1:nokey=1",
      videoPath,
    ],
    stdout: "piped",
    stderr: "piped",
  });

  const { success, stdout } = await command.output();
  if (!success) {
    // 如果失败，假设没有音频
    return false;
  }

  const output = new TextDecoder().decode(stdout).trim();
  return output === "audio";
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
