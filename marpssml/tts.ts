#!/usr/bin/env -S deno run -A

import { join } from "@std/path";
// @deno-types="npm:@types/node"
import * as sdk from "azure-tts";

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

/**
 * 增量生成音频文件
 */
export async function generateAudio(
  targetDir: string,
  options: { force?: boolean; voice?: string; retry?: number } = {}
) {
  const { force = false, voice = "zh-CN-YunyiMultilingualNeural", retry = 3 } = options;

  console.log(`🎙️  生成音频: ${targetDir}`);

  // 检查环境变量
  const subscriptionKey = Deno.env.get("TTS_KEY");
  const serviceRegion = Deno.env.get("TTS_REGION");

  if (!subscriptionKey || !serviceRegion) {
    throw new Error(
      "缺少环境变量: TTS_KEY 和 TTS_REGION 必须设置"
    );
  }

  // 读取 manifest
  const manifestFile = join(targetDir, "manifest.json");
  const manifest: Manifest = JSON.parse(await Deno.readTextFile(manifestFile));

  let generatedCount = 0;
  let skippedCount = 0;

  for (const slide of manifest.slides) {
    if (!slide.hasAudio) {
      console.log(`   ○ slide-${slide.id}: 跳过（无音频）`);
      continue;
    }

    const audioDir = join(targetDir, "audio");
    const ssmlFile = join(audioDir, `slide-${slide.id}.ssml`);
    const audioFile = join(audioDir, `slide-${slide.id}.wav`);
    const metaFile = join(audioDir, `slide-${slide.id}.meta.json`);

    // 检查是否需要重新生成
    const needRegenerate = force || !(await shouldSkip(metaFile, slide.ssmlHash));

    if (!needRegenerate) {
      console.log(`   ✓ slide-${slide.id}: 跳过（已存在且未修改）`);
      skippedCount++;
      continue;
    }

    // 读取 SSML 内容
    const ssmlContent = await Deno.readTextFile(ssmlFile);

    // 包装成完整的 SSML 文档
    const fullSSML = wrapSSML(ssmlContent, voice);

    console.log(`   🔊 slide-${slide.id}: 正在生成音频...`);

    // 调用 TTS API（带重试）
    const duration = await synthesizeSpeechWithRetry(
      fullSSML,
      audioFile,
      subscriptionKey,
      serviceRegion,
      retry
    );

    // 保存元数据
    const meta: AudioMeta = {
      duration,
      hash: slide.ssmlHash,
    };
    await Deno.writeTextFile(metaFile, JSON.stringify(meta, null, 2));

    console.log(`   ✓ slide-${slide.id}: 已生成 (${duration.toFixed(2)}s)`);
    generatedCount++;
  }

  // 处理视频配音
  for (const video of manifest.videos) {
    if (!video.hasAudio) {
      console.log(`   ○ video-after-${video.afterSlide}: 跳过（无音频）`);
      continue;
    }

    const audioDir = join(targetDir, "audio");
    const ssmlFile = join(audioDir, `video-after-${video.afterSlide}.ssml`);
    const audioFile = join(audioDir, `video-after-${video.afterSlide}.wav`);
    const metaFile = join(audioDir, `video-after-${video.afterSlide}.meta.json`);

    // 检查是否需要重新生成
    const needRegenerate = force || !(await shouldSkip(metaFile, video.ssmlHash));

    if (!needRegenerate) {
      console.log(`   ○ video-after-${video.afterSlide}: 跳过（未修改）`);
      skippedCount++;
      continue;
    }

    // 读取 SSML 内容
    const ssmlContent = await Deno.readTextFile(ssmlFile);

    // 包装成完整的 SSML 文档
    const fullSSML = wrapSSML(ssmlContent, voice);

    console.log(`   🔊 video-after-${video.afterSlide}: 正在生成音频...`);

    // 调用 TTS API（带重试）
    const duration = await synthesizeSpeechWithRetry(
      fullSSML,
      audioFile,
      subscriptionKey,
      serviceRegion,
      retry
    );

    // 保存元数据
    const meta: AudioMeta = {
      duration,
      hash: video.ssmlHash,
    };
    await Deno.writeTextFile(metaFile, JSON.stringify(meta, null, 2));

    console.log(`   ✓ video-after-${video.afterSlide}: 已生成 (${duration.toFixed(2)}s)`);
    generatedCount++;
  }

  console.log(
    `✅ 音频生成完成: ${generatedCount} 个新生成, ${skippedCount} 个跳过`
  );
}

/**
 * 检查是否应该跳过生成（已存在且哈希匹配）
 */
async function shouldSkip(metaFile: string, currentHash: string): Promise<boolean> {
  try {
    const content = await Deno.readTextFile(metaFile);
    const meta: AudioMeta = JSON.parse(content);
    return meta.hash === currentHash;
  } catch {
    return false; // 文件不存在或读取失败，需要生成
  }
}

/**
 * 包装 SSML 内容为完整文档
 */
function wrapSSML(content: string, voice: string): string {
  return `<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN">
  <voice name="${voice}">
    <p>
      ${content}
    </p>
  </voice>
</speak>`;
}

/**
 * 带重试的语音合成函数
 */
async function synthesizeSpeechWithRetry(
  ssml: string,
  outputFile: string,
  subscriptionKey: string,
  serviceRegion: string,
  maxRetries: number
): Promise<number> {
  let lastError: Error | null = null;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const duration = await synthesizeSpeech(
        ssml,
        outputFile,
        subscriptionKey,
        serviceRegion
      );
      return duration;
    } catch (error) {
      lastError = error as Error;
      if (attempt < maxRetries) {
        const delay = Math.min(1000 * Math.pow(2, attempt - 1), 10000); // 指数退避，最多10秒
        console.log(`   ⚠️  尝试 ${attempt}/${maxRetries} 失败: ${lastError.message}`);
        console.log(`   ⏳ ${delay}ms 后重试...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }

  throw new Error(`${maxRetries} 次尝试后仍失败: ${lastError?.message}`);
}

/**
 * 调用 Azure TTS API 合成语音
 */
function synthesizeSpeech(
  ssml: string,
  outputFile: string,
  subscriptionKey: string,
  serviceRegion: string
): Promise<number> {
  const audioConfig = sdk.AudioConfig.fromAudioFileOutput(outputFile);
  const speechConfig = sdk.SpeechConfig.fromSubscription(
    subscriptionKey,
    serviceRegion
  );

  const synthesizer = new sdk.SpeechSynthesizer(speechConfig, audioConfig);

  return new Promise((resolve, reject) => {
    synthesizer.speakSsmlAsync(
      ssml,
      // deno-lint-ignore no-explicit-any
      (result: any) => {
        if (result.reason === sdk.ResultReason.SynthesizingAudioCompleted) {
          // 获取音频时长（从音频数据）
          const duration = result.audioDuration / 10000000; // 转换为秒
          synthesizer.close();
          resolve(duration);
        } else {
          synthesizer.close();
          reject(
            new Error(
              `语音合成失败: ${result.errorDetails}`
            )
          );
        }
      },
      // deno-lint-ignore no-explicit-any
      (error: any) => {
        synthesizer.close();
        reject(new Error(`语音合成错误: ${error}`));
      }
    );
  });
}

// 如果直接运行此文件
if (import.meta.main) {
  const args = Deno.args;

  if (args.length === 0) {
    console.error("用法: deno run -A tts.ts <target-dir> [--force]");
    Deno.exit(1);
  }

  const targetDir = args[0];
  const force = args.includes("--force");

  try {
    await generateAudio(targetDir, { force });
  } catch (error) {
    const err = error as Error;
    console.error("❌ 错误:", err.message);
    Deno.exit(1);
  }
}
