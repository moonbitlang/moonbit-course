// utils.mbt - Utility functions for mdcourse

///|
/// Pad a string to the left with a character
fn pad_start(s : String, length : Int, pad_char : Char) -> String {
  let current_len = s.length()
  if current_len >= length {
    return s
  }
  let pad_count = length - current_len
  let mut result = ""
  for _i = 0; _i < pad_count; _i = _i + 1 {
    result = result + pad_char.to_string()
  }
  result + s
}

///|
/// Pad a number to 3 digits (for slide IDs)
fn pad_slide_id(num : Int) -> String {
  pad_start(num.to_string(), 3, '0')
}

///|
/// Simple path join (Unix-style)
fn path_join(parts : Array[String]) -> String {
  let mut result = ""
  for i, part in parts {
    if i > 0 && !result.is_empty() {
      result = result + "/"
    }
    result = result + part
  }
  result
}

///|
/// Read 32-bit little-endian integer from Bytes
fn read_u32_le(bytes : Bytes, offset : Int) -> Int {
  let b0 = bytes[offset].to_int()
  let b1 = bytes[offset + 1].to_int()
  let b2 = bytes[offset + 2].to_int()
  let b3 = bytes[offset + 3].to_int()
  b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
}

///|
/// Calculate WAV audio duration from WAV file bytes
/// WAV header structure:
/// - Bytes 24-27: Sample rate (little-endian) - not needed for duration calculation
/// - Bytes 28-31: Byte rate (little-endian) - bytes per second
/// - Bytes 40-43: Data size (little-endian) - total audio data size
/// Duration = data_size / byte_rate
fn get_wav_duration(wav_bytes : Bytes) -> Double {
  let byte_rate = read_u32_le(wav_bytes, 28)
  let data_size = read_u32_le(wav_bytes, 40)
  data_size.to_double() / byte_rate.to_double()
}

///|
/// Build target directory path from course name
pub fn target_dir(course_name : String) -> String {
  path_join(["mdcoursetarget", course_name])
}

///|
/// Build audio directory path from target directory
fn audio_dir(target : String) -> String {
  path_join([target, "audio"])
}

///|
/// Build slides directory path from target directory
fn slides_dir(target : String) -> String {
  path_join([target, "slides"])
}

///|
/// Build manifest file path
fn manifest_path(target : String) -> String {
  path_join([target, "manifest.json"])
}

///|
/// Build slide image path
fn slide_image_path(target : String, slide_id : String) -> String {
  path_join([slides_dir(target), "slide-\{slide_id}.png"])
}

///|
/// Build audio file path for a slide
fn slide_audio_path(target : String, slide_id : String) -> String {
  path_join([audio_dir(target), "slide-\{slide_id}.wav"])
}

///|
/// Build audio metadata path for a slide
fn slide_meta_path(target : String, slide_id : String) -> String {
  path_join([audio_dir(target), "slide-\{slide_id}.meta.json"])
}

///|
/// Build SSML file path for a slide
fn slide_ssml_path(target : String, slide_id : String) -> String {
  path_join([audio_dir(target), "slide-\{slide_id}.ssml"])
}

///|
/// Build SSML file path for video after a slide (with video index)
fn video_ssml_path_indexed(
  target : String,
  slide_id : String,
  video_index : Int
) -> String {
  path_join([audio_dir(target), "video-after-\{slide_id}-\{video_index}.ssml"])
}

///|
/// Build audio file path for video after a slide (with video index)
fn video_audio_path_indexed(
  target : String,
  slide_id : String,
  video_index : Int
) -> String {
  path_join([audio_dir(target), "video-after-\{slide_id}-\{video_index}.wav"])
}

///|
/// Build audio metadata path for video after a slide (with video index)
fn video_meta_path_indexed(
  target : String,
  slide_id : String,
  video_index : Int
) -> String {
  path_join([
    audio_dir(target),
    "video-after-\{slide_id}-\{video_index}.meta.json",
  ])
}

///|
/// Check if video has an audio stream using ffprobe
async fn has_audio_stream(video_path : String) -> Bool {
  let args : Array[String] = [
    "-v", "error", "-select_streams", "a:0", "-show_entries", "stream=codec_type",
    "-of", "default=noprint_wrappers=1:nokey=1", video_path,
  ]
  let (exit_code, stdout, _stderr) = @process.collect_output("ffprobe", args)
  if exit_code != 0 {
    return false
  }
  let output = stdout.text().trim(char_set=" \t\n")
  output.to_string() == "audio"
}

///|
/// Get video duration using ffprobe
pub async fn get_video_duration(video_path : String) -> Double {
  let args : Array[String] = [
    "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1",
    video_path,
  ]
  let (exit_code, stdout, _stderr) = @process.collect_output("ffprobe", args)
  if exit_code != 0 {
    return 0.0
  }
  let duration_str = stdout.text().trim(char_set=" \t\n")
  @strconv.parse_double(duration_str.to_string()) catch {
    _ => 0.0
  }
}

///|
/// Estimate video size in MB (rough approximation)
/// Assumes H.264 with ~3 Mbps bitrate
fn estimate_video_size(
  duration_seconds : Double,
  resolution : Resolution,
) -> Double {
  // Base bitrate in Mbps
  let base_bitrate = match resolution.width {
    3840 => 10.0 // 4K
    2560 => 6.0 // 1440p
    1920 => 3.0 // 1080p
    1280 => 1.5 // 720p
    _ => 1.0 // 480p or lower
  }

  // MB = (bitrate in Mbps * duration in seconds) / 8
  base_bitrate * duration_seconds / 8.0
}

///|
/// Get segment metadata file path for a slide segment
fn slide_segment_meta_path(output_dir : String, slide_id : String) -> String {
  path_join([output_dir, "segments", "slide-\{slide_id}.meta.json"])
}

///|
/// Get segment metadata file path for a video segment
/// video_index: 1-based index for videos after the same slide (1st video, 2nd video, etc.)
fn video_segment_meta_path(
  output_dir : String,
  slide_id : String,
  video_index : Int
) -> String {
  path_join([
    output_dir,
    "segments",
    "video-after-\{slide_id}-\{video_index}.meta.json",
  ])
}

///|
/// Hash file contents using SHA256
pub async fn hash_file(file_path : String) -> String {
  if !@fs.exists(file_path) {
    return ""
  }
  let bytes = @fs.read_file(file_path).binary()
  let digest = @sha256.Digest::new()
  for b in bytes {
    digest.write(b)
  }
  digest.check_sum()
}
