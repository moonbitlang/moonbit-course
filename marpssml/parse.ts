#!/usr/bin/env -S deno run -A

import { basename, dirname, join } from "@std/path";
import { crypto } from "@std/crypto";
import { encodeHex } from "@std/encoding/hex";

interface SlideInfo {
  id: string;
  ssmlHash: string;
  hasAudio: boolean;
}

interface VideoSegment {
  afterSlide: string; // 在哪一页之后插入
  videoPath: string;  // 视频文件路径
  ssmlHash: string;   // 视频配音的 SSML 哈希
  hasAudio: boolean;  // 是否有配音
}

interface Manifest {
  slides: SlideInfo[];
  videos: VideoSegment[];
}

/**
 * 解析 Marp markdown 文件，提取幻灯片和 SSML 内容
 */
export async function parse(inputFile: string, targetDir: string) {
  console.log(`📖 解析文件: ${inputFile}`);

  // 读取输入文件
  const content = await Deno.readTextFile(inputFile);

  // 按 --- 分割页面（保留 frontmatter）
  const pages = splitPages(content);

  console.log(`   找到 ${pages.length} 页`);

  // 创建目标目录
  await Deno.mkdir(join(targetDir, "audio"), { recursive: true });
  await Deno.mkdir(join(targetDir, "slides"), { recursive: true });

  // 处理每一页
  const slides: SlideInfo[] = [];
  const videos: VideoSegment[] = [];

  for (let i = 0; i < pages.length; i++) {
    const pageNum = i + 1;
    const slideId = pageNum.toString().padStart(3, "0");
    const page = pages[i];

    // 检查是否有视频标记，以及视频后是否紧跟 SSML
    const videoMatch = page.match(/<!--\s*video\s+(.+?)\s*-->\s*(<!--\s*ssml\s*\n([\s\S]*?)\n-->)?/);
    let videoSSML = "";
    let pageWithoutVideoSSML = page;

    if (videoMatch) {
      const videoPath = videoMatch[1].trim();
      videoSSML = videoMatch[3] ? videoMatch[3].trim() : "";

      // 从页面中移除 video 及其后的 SSML（如果有）
      pageWithoutVideoSSML = page.replace(videoMatch[0], "");

      const hasVideoAudio = videoSSML.length > 0;
      const videoSSMLHash = hasVideoAudio ? await hashContent(videoSSML) : "";

      videos.push({
        afterSlide: slideId,
        videoPath,
        ssmlHash: videoSSMLHash,
        hasAudio: hasVideoAudio,
      });

      // 保存视频的 SSML 文件
      if (hasVideoAudio) {
        const videoSSMLFile = join(targetDir, "audio", `video-after-${slideId}.ssml`);
        await Deno.writeTextFile(videoSSMLFile, videoSSML);
        console.log(`   📹 slide-${slideId} 后插入视频: ${videoPath} (有配音)`);
      } else {
        console.log(`   📹 slide-${slideId} 后插入视频: ${videoPath}`);
      }
    }

    // 提取页面的 SSML 内容（不包括 video 后的 SSML）
    const { ssmlPart } = extractSSML(pageWithoutVideoSSML);

    // 计算 SSML 哈希
    const hasAudio = ssmlPart.trim().length > 0;
    const ssmlHash = hasAudio ? await hashContent(ssmlPart) : "";

    slides.push({
      id: slideId,
      ssmlHash,
      hasAudio,
    });

    // 保存 SSML 文件
    if (hasAudio) {
      const ssmlFile = join(targetDir, "audio", `slide-${slideId}.ssml`);
      await Deno.writeTextFile(ssmlFile, ssmlPart.trim());
      console.log(`   ✓ slide-${slideId}: 已保存 SSML (${ssmlPart.length} 字符)`);
    } else {
      console.log(`   ○ slide-${slideId}: 无音频`);
    }
  }

  // 提取 SSML 和 video 注释，生成 slides.md
  // 策略：保持原始文档结构，只移除特殊注释
  const ssmlRegex = /<!--\s*ssml\s*\n([\s\S]*?)\n-->/g;
  const videoRegex = /<!--\s*video\s+.+?\s*-->/g;
  let slidesContent = content.replace(ssmlRegex, "");
  slidesContent = slidesContent.replace(videoRegex, "");

  const slidesFile = join(targetDir, "slides.md");
  await Deno.writeTextFile(slidesFile, slidesContent);
  console.log(`   ✓ 已保存 slides.md`);

  // 保存 manifest.json
  const manifest: Manifest = { slides, videos };
  const manifestFile = join(targetDir, "manifest.json");
  await Deno.writeTextFile(manifestFile, JSON.stringify(manifest, null, 2));
  console.log(`   ✓ 已保存 manifest.json`);

  return manifest;
}

/**
 * 按 --- 或 headingDivider 分割页面
 */
function splitPages(content: string): string[] {
  // 先提取 frontmatter
  const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---\n/);
  let frontmatter = "";
  let mainContent = content;

  if (frontmatterMatch) {
    frontmatter = frontmatterMatch[0];
    mainContent = content.slice(frontmatterMatch[0].length);
  }

  // 检查是否使用了 headingDivider
  let headingLevel: number | null = null;
  if (frontmatter) {
    const headingDividerMatch = frontmatter.match(/headingDivider:\s*(\d+)/);
    if (headingDividerMatch) {
      headingLevel = parseInt(headingDividerMatch[1]);
    }
  }

  let pages: string[];

  if (headingLevel !== null) {
    // 使用 headingDivider 分割
    const headingPattern = new RegExp(`^${"#".repeat(headingLevel)}\\s+`, "gm");
    const parts = mainContent.split(headingPattern);

    // 获取所有标题文本
    const headings = Array.from(mainContent.matchAll(headingPattern)).map(m => m[0]);

    // 重新组合（跳过第一个空部分）
    pages = [];
    for (let i = 1; i < parts.length; i++) {
      pages.push(headings[i - 1] + parts[i]);
    }

    // 如果第一部分不为空，也加入
    if (parts[0].trim()) {
      pages.unshift(parts[0]);
    }
  } else {
    // 按 --- 分割页面
    pages = mainContent.split(/\n---\n+/);
  }

  // 第一页加上 frontmatter
  if (pages.length > 0 && frontmatter) {
    pages[0] = frontmatter + pages[0];
  }

  return pages.filter(p => p.trim().length > 0);
}

/**
 * 从页面中提取 SSML 内容
 */
function extractSSML(page: string): { marpPart: string; ssmlPart: string } {
  // 匹配 <!-- ssml ... --> 注释块
  const ssmlRegex = /<!--\s*ssml\s*\n([\s\S]*?)\n-->/g;

  let ssmlPart = "";
  const marpPart = page.replace(ssmlRegex, (_match, content) => {
    ssmlPart += content.trim() + "\n";
    // 保留一个空行，防止分隔符连在一起
    return "";
  });

  return {
    marpPart: marpPart.trim(),
    ssmlPart: ssmlPart.trim(),
  };
}

/**
 * 计算内容的 SHA-256 哈希
 */
async function hashContent(content: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(content);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  return encodeHex(new Uint8Array(hashBuffer));
}

/**
 * 获取课程名称（从文件路径）
 */
export function getCourseName(inputFile: string): string {
  const dir = dirname(inputFile);
  const dirName = basename(dir);

  // 如果目录名是 courseX 格式，直接使用
  if (dirName.match(/^course\d+$/)) {
    return dirName;
  }

  // 否则使用文件名（去掉扩展名）
  const fileName = basename(inputFile, ".mbt.md");
  return fileName.replace(/^lec/, "course");
}

// 如果直接运行此文件
if (import.meta.main) {
  const args = Deno.args;

  if (args.length === 0) {
    console.error("用法: deno run -A parse.ts <input.mbt.md>");
    Deno.exit(1);
  }

  const inputFile = args[0];
  const courseName = getCourseName(inputFile);
  const targetDir = join("target", courseName);

  await parse(inputFile, targetDir);
  console.log("✅ 解析完成");
}
