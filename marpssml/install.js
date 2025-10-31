#!/usr/bin/env node

/**
 * 安装脚本 - 根据平台选择正确的二进制文件
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function getPlatform() {
  const platform = process.platform;
  const arch = process.arch;

  if (platform === 'darwin') {
    if (arch === 'arm64') {
      return 'mdcourse-macos-arm64';
    }
    return 'mdcourse-macos-x64';
  }

  if (platform === 'linux' && arch === 'x64') {
    return 'mdcourse-linux-x64';
  }

  if (platform === 'win32' && arch === 'x64') {
    return 'mdcourse-win-x64.exe';
  }

  throw new Error(`不支持的平台: ${platform} ${arch}`);
}

function install() {
  try {
    console.log('📦 安装 mdcourse...');

    const binaryName = getPlatform();
    const binaryPath = path.join(__dirname, 'bin', binaryName);
    const targetPath = path.join(__dirname, 'bin', 'mdcourse' + (process.platform === 'win32' ? '.exe' : ''));

    // 检查二进制文件是否存在
    if (!fs.existsSync(binaryPath)) {
      console.error(`❌ 错误: 找不到预编译的二进制文件: ${binaryName}`);
      console.error('请运行 npm run build 编译二进制文件');
      process.exit(1);
    }

    // 复制到目标位置
    fs.copyFileSync(binaryPath, targetPath);

    // 设置可执行权限 (Unix-like systems)
    if (process.platform !== 'win32') {
      fs.chmodSync(targetPath, 0o755);
    }

    console.log('✅ mdcourse 安装成功！');
    console.log(`   平台: ${process.platform} ${process.arch}`);
    console.log(`   二进制: ${binaryName}`);
    console.log('\n使用方法:');
    console.log('  mdcourse my-slides.mbt.md -o video.mp4');
  } catch (error) {
    console.error('❌ 安装失败:', error.message);
    process.exit(1);
  }
}

install();
