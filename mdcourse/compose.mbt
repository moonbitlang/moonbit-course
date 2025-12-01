// compose.mbt - Video composition using ffmpeg
// NOTE: This is a skeleton implementation showing the workflow.
// Full implementation requires proper JSON parsing for manifest and metadata.

///|
/// Compose final video from slides and audio
///
/// Workflow:
/// 1. Read manifest.json to get slides and their metadata
/// 2. For each slide:
///    - Create video segment from PNG + audio (or static duration)
///    - Use ffmpeg to combine image + audio
/// 3. Concatenate all segments into final video
/// 4. Apply resolution scaling and FPS settings
pub async fn compose_video(
  output_dir : String,
  output_file : String?,
  options : Options,
) -> Bool {
  println("Composing video...")

  // Check if ffmpeg is installed
  if !check_ffmpeg() {
    println("   [ERROR] ffmpeg not found")
    println("   Please install ffmpeg:")
    println("     macOS: brew install ffmpeg")
    println("     Ubuntu: sudo apt install ffmpeg")
    println("     Windows: https://ffmpeg.org/download.html")
    return false
  }

  // 1. Parse manifest.json
  let manifest_path = manifest_path(output_dir)
  let manifest_json = @fs.read_file(manifest_path).text()
  let manifest : Manifest = (@json.parse(manifest_json) |> @json.from_json) catch {
    e => {
      println("   [ERROR] Invalid manifest json: \{e}")
      return false
    }
  }
  if manifest.slides.length() == 0 {
    println("   [ERROR] No slides found in manifest")
    return false
  }

  // 2. Create temp directory for segments
  let segments_dir = path_join([output_dir, "segments"])
  create_dir_all(segments_dir)

  // 3. Generate video segment for each slide and insert videos after slides
  let segment_files : Array[String] = []
  let mut total_duration = 0.0
  let mut segment_counter = 1
  for slide in manifest.slides {
    // Generate slide segment
    let segment_file = path_join([
      segments_dir,
      "segment-\{pad_slide_id(segment_counter)}.mp4",
    ])
    segment_files.push(segment_file)
    segment_counter = segment_counter + 1
    let image_path = slide_image_path(output_dir, slide.id)
    let audio_path : String? = if slide.has_audio {
      Some(slide_audio_path(output_dir, slide.id))
    } else {
      None
    }

    // Check if we can skip this segment (caching)
    let (can_skip, cached_duration) = should_skip_slide_segment(
      output_dir,
      slide.id,
      segment_file,
      image_path,
      slide,
    )

    // Parse resolution once (used for both slides and videos)
    let resolution = parse_resolution(options.resolution)
    if can_skip {
      total_duration = total_duration + cached_duration
      println(
        "   [+] Skipping segment \{segment_counter - 1}/\{manifest.slides.length() + manifest.videos.length()}: slide-\{slide.id} (cached, \{cached_duration}s)",
      )
      // Don't use continue here - we still need to check for video insertions
    } else {
      // Get duration from metadata or use default
      let duration = if slide.has_audio {
        let meta_file = slide_meta_path(output_dir, slide.id)
        parse_audio_metadata(meta_file)
        .map(fn(meta) { meta.duration })
        .unwrap_or_else(fn() {
          println(
            "   [WARN] Could not read duration for slide-\{slide.id}, using default",
          )
          options.default_duration
        })
      } else {
        options.default_duration
      }
      total_duration = total_duration + duration
      println(
        "   [*] Generating segment \{segment_counter - 1}/\{manifest.slides.length() + manifest.videos.length()}: slide-\{slide.id} (\{duration}s)",
      )

      // Generate ffmpeg command for slide
      let args = generate_slide_video_command(
        image_path,
        audio_path,
        duration,
        segment_file,
        resolution,
        options.fps,
      )

      // Run ffmpeg
      let (exit_code, _stdout, stderr) = @process.collect_output("ffmpeg", args)
      if exit_code != 0 {
        println("   [ERROR] Failed to generate segment \{segment_counter - 1}")
        println("   ffmpeg error: \{stderr.text()}")
        return false
      }

      // Save segment metadata for caching
      let image_hash = hash_file(image_path)
      let audio_hash = if slide.has_audio { slide.ssml_hash } else { "" }
      let segment_meta_file = slide_segment_meta_path(output_dir, slide.id)
      save_segment_metadata(segment_meta_file, duration, image_hash, audio_hash)
    }

    // Check if there's a video to insert after this slide
    let mut video_index = 1 // Track which video number this is (1st, 2nd, etc.)
    for video in manifest.videos {
      if video.after_slide == slide.id {
        let video_segment_file = path_join([
          segments_dir,
          "segment-\{pad_slide_id(segment_counter)}.mp4",
        ])
        segment_files.push(video_segment_file)
        segment_counter = segment_counter + 1

        // Check if we can skip this video segment (caching)
        let (can_skip_video, cached_video_duration) = should_skip_video_segment(
          output_dir,
          slide.id,
          video_segment_file,
          video.video_path,
          video,
          video_index,
        )
        if can_skip_video {
          total_duration = total_duration + cached_video_duration
          println(
            "   [+] Skipping segment \{segment_counter - 1}/\{manifest.slides.length() + manifest.videos.length()}: video after slide-\{slide.id} (cached, \{cached_video_duration}s)",
          )
          video_index = video_index + 1 // Increment for next video
          continue // Skip to next video
        }

        // Process video with optional narration
        let video_duration = get_video_duration(video.video_path)
        let narration_audio : String? = if video.has_audio {
          Some(video_audio_path_indexed(output_dir, slide.id, video_index))
        } else {
          None
        }
        let narration_meta_file = video_meta_path_indexed(
          output_dir,
          slide.id,
          video_index,
        )
        let final_duration = if video.has_audio {
          parse_audio_metadata(narration_meta_file)
          .map(fn(meta) {
            if meta.duration > video_duration {
              meta.duration
            } else {
              video_duration
            }
          })
          .unwrap_or(video_duration)
        } else {
          video_duration
        }
        total_duration = total_duration + final_duration
        println(
          "   [*] Generating segment \{segment_counter - 1}/\{manifest.slides.length() + manifest.videos.length()}: video after slide-\{slide.id} (\{final_duration}s)",
        )

        // Generate video segment with optional audio mixing
        let video_args = generate_video_segment_command(
          video.video_path,
          narration_audio,
          narration_meta_file,
          video_duration,
          video_segment_file,
          resolution,
          options.fps,
        )
        let (exit_code, _stdout, stderr) = @process.collect_output(
          "ffmpeg", video_args,
        )
        if exit_code != 0 {
          println(
            "   [ERROR] Failed to generate video segment \{segment_counter - 1}",
          )
          println("   ffmpeg error: \{stderr.text()}")
          return false
        }

        // Save video segment metadata for caching
        let video_hash = hash_file(video.video_path)
        let video_audio_hash = if video.has_audio {
          video.ssml_hash
        } else {
          ""
        }
        let video_segment_meta_file = video_segment_meta_path(
          output_dir,
          slide.id,
          video_index,
        )
        save_segment_metadata(
          video_segment_meta_file, final_duration, video_hash, video_audio_hash,
        )
        video_index = video_index + 1 // Increment for next video
      }
    }
  }

  // 4. Concatenate all segments
  println("   [*] Concatenating \{segment_files.length()} segments...")
  let concat_list_file = path_join([segments_dir, "concat.txt"])
  let concat_content = generate_concat_list(segment_files)
  write_file(concat_list_file, concat_content)
  let final_output = output_file.unwrap_or(
    path_join([output_dir, "output.mp4"]),
  )
  let concat_args : Array[String] = [
    "-f", "concat", "-safe", "0", "-i", concat_list_file, "-c", "copy", "-y", final_output,
  ]
  let (exit_code, _stdout, stderr) = @process.collect_output(
    "ffmpeg", concat_args,
  )
  if exit_code != 0 {
    println("   [ERROR] Failed to concatenate segments")
    println("   ffmpeg error: \{stderr.text()}")
    return false
  }

  // 5. Cleanup temporary concat file
  if !options.keep_temp {
    println("   [*] Cleaning up temporary concat file...")
    remove_file(concat_list_file)
  }
  // Note: Segment files are kept for caching - they will be reused on next run
  println("   [+] Video composed successfully!")
  println("   Duration: \{total_duration}s")
  println(
    "   Size: ~\{estimate_video_size(total_duration, parse_resolution(options.resolution))}MB",
  )
  true
}

///|
/// Check if ffmpeg is installed
async fn check_ffmpeg() -> Bool {
  let args : Array[String] = ["-version"]
  let (exit_code, _stdout, _stderr) = @process.collect_output("ffmpeg", args)
  exit_code == 0
}

///|
/// Generate ffmpeg command for creating slide video (skeleton)
fn generate_slide_video_command(
  image_path : String,
  audio_path : String?,
  duration : Double,
  output_path : String,
  resolution : Resolution,
  fps : Int,
) -> Array[String] {
  let args : Array[String] = ["-loop", "1", "-i", image_path]

  // Add audio if available
  if audio_path is Some(path) {
    args.push("-i")
    args.push(path)
  }

  // Video encoding settings
  args.push("-c:v")
  args.push("libx264")
  args.push("-tune")
  args.push("stillimage")
  args.push("-pix_fmt")
  args.push("yuv420p")
  args.push("-r")
  args.push(fps.to_string())

  // Resolution scaling
  let scale_filter = "scale=\{resolution.width}:\{resolution.height}:force_original_aspect_ratio=decrease,pad=\{resolution.width}:\{resolution.height}:(ow-iw)/2:(oh-ih)/2"
  args.push("-vf")
  args.push(scale_filter)

  // Audio settings or no audio
  if audio_path is Some(_) {
    args.push("-c:a")
    args.push("aac")
    args.push("-ar")
    args.push("44100")
    // Use -t instead of -shortest for precise duration control
    args.push("-t")
    args.push(duration.to_string())
  } else {
    args.push("-t")
    args.push(duration.to_string())
    args.push("-an")
  }
  // Output
  args.push("-y")
  args.push(output_path)
  args
}

///|
/// Generate ffmpeg command for video segment with optional narration audio
async fn generate_video_segment_command(
  video_path : String,
  narration_audio : String?,
  narration_meta_file : String,
  video_duration : Double,
  output_path : String,
  resolution : Resolution,
  fps : Int,
) -> Array[String] {
  let args : Array[String] = []

  // Check if video has its own audio stream
  let video_has_audio = has_audio_stream(video_path)
  if narration_audio is Some(audio_path) {

    // Case 1 & 2: Video with narration (mix or replace audio)
    args.push("-i")
    args.push(video_path)
    args.push("-i")
    args.push(audio_path)

    // Video filter: scale + pad + adjust duration to match narration
    let scale_filter = "scale=\{resolution.width}:\{resolution.height}:force_original_aspect_ratio=decrease,pad=\{resolution.width}:\{resolution.height}:(ow-iw)/2:(oh-ih)/2"

    // Get narration duration from metadata file
    let narration_duration = parse_audio_metadata(narration_meta_file)
      .map(fn(meta) { meta.duration })
      .unwrap_or(video_duration)
    if narration_duration > video_duration {
      // Freeze last frame to match narration length
      let freeze_duration = narration_duration - video_duration
      args.push("-filter_complex")
      args.push(
        "[0:v]\{scale_filter},tpad=stop_mode=clone:stop_duration=\{freeze_duration}[v]",
      )
      args.push("-map")
      args.push("[v]")
    } else {
      // Trim video to match narration length
      args.push("-filter_complex")
      args.push(
        "[0:v]\{scale_filter},trim=duration=\{narration_duration},setpts=PTS-STARTPTS[v]",
      )
      args.push("-map")
      args.push("[v]")
    }

    // Audio mixing
    if video_has_audio {
      // Mix video audio with narration - use shortest to end when narration ends
      args.push("-filter_complex")
      args.push("[0:a][1:a]amix=inputs=2:duration=shortest[a]")
      args.push("-map")
      args.push("[a]")
    } else {
      // Use narration audio only
      args.push("-map")
      args.push("1:a")
    }

    // Video and audio encoding
    args.push("-c:v")
    args.push("libx264")
    args.push("-pix_fmt")
    args.push("yuv420p")
    args.push("-r")
    args.push(fps.to_string())
    args.push("-c:a")
    args.push("aac")
    args.push("-ar")
    args.push("44100")
    // Don't use -shortest - let narration audio control the duration
  } else {
    // Case 3 & 4: Video without narration (keep or no audio)
    args.push("-i")
    args.push(video_path)

    // Video settings
    let scale_filter = "scale=\{resolution.width}:\{resolution.height}:force_original_aspect_ratio=decrease,pad=\{resolution.width}:\{resolution.height}:(ow-iw)/2:(oh-ih)/2"
    args.push("-vf")
    args.push(scale_filter)
    args.push("-c:v")
    args.push("libx264")
    args.push("-pix_fmt")
    args.push("yuv420p")
    args.push("-r")
    args.push(fps.to_string())

    // Audio settings
    if video_has_audio {
      args.push("-c:a")
      args.push("aac")
      args.push("-ar")
      args.push("44100")
    } else {
      args.push("-an")
    }
  }

  // Output
  args.push("-y")
  args.push(output_path)
  args
}

///|
/// Generate ffmpeg concat list file content
fn generate_concat_list(segment_files : Array[String]) -> String {
  let mut content = ""
  for file in segment_files {
    // Extract just the filename from the full path
    let parts : Array[String] = []
    for view in file.split("/") {
      parts.push(view.to_string())
    }
    let filename = if parts.length() > 0 {
      parts[parts.length() - 1]
    } else {
      file
    }
    content = content + "file '\{filename}'\n"
  }
  content
}

///|
/// Parse audio metadata file
async fn parse_audio_metadata(meta_file : String) -> AudioMeta? {
  if !@fs.exists(meta_file) {
    return None
  }
  let meta : AudioMeta = (@fs.read_file(meta_file).text()
  |> @json.parse
  |> @json.from_json) catch {
    _ => return None
  }
  Some(meta)
}

///|
/// Parse segment metadata file
async fn parse_segment_metadata(meta_file : String) -> SegmentMeta? {
  if !@fs.exists(meta_file) {
    return None
  }
  let meta : SegmentMeta = (@fs.read_file(meta_file).text()
  |> @json.parse
  |> @json.from_json) catch {
    _ => return None
  }
  Some(meta)
}

///|
/// Check if a slide segment needs regeneration
/// Returns (should_skip, duration)
async fn should_skip_slide_segment(
  output_dir : String,
  slide_id : String,
  segment_file : String,
  image_path : String,
  slide : SlideInfo,
) -> (Bool, Double) {
  let meta_file = slide_segment_meta_path(output_dir, slide_id)

  // Check if segment file exists
  if !@fs.exists(segment_file) {
    return (false, 0.0)
  }

  // Parse metadata
  guard parse_segment_metadata(meta_file) is Some(meta) else {
    return (false, 0.0)
  }

  // Check if image hash matches
  let current_image_hash = hash_file(image_path)
  if current_image_hash != meta.content_hash {
    return (false, 0.0)
  }

  // Check if audio hash matches (if has audio)
  if slide.has_audio {
    if slide.ssml_hash != meta.audio_hash {
      return (false, 0.0)
    }
  }

  // All checks passed - can skip
  (true, meta.duration)
}

///|
/// Check if a video segment needs regeneration
/// Returns (should_skip, duration)
async fn should_skip_video_segment(
  output_dir : String,
  slide_id : String,
  segment_file : String,
  video_path : String,
  video : VideoSegment,
  video_index : Int,
) -> (Bool, Double) {
  let meta_file = video_segment_meta_path(output_dir, slide_id, video_index)

  // Check if segment file exists
  if !@fs.exists(segment_file) {
    return (false, 0.0)
  }

  // Parse metadata
  guard parse_segment_metadata(meta_file) is Some(meta) else {
    return (false, 0.0)
  }

  // Check if video hash matches
  let current_video_hash = hash_file(video_path)
  if current_video_hash != meta.content_hash {
    return (false, 0.0)
  }

  // Check if audio hash matches (if has audio)
  if video.has_audio {
    if video.ssml_hash != meta.audio_hash {
      return (false, 0.0)
    }
  }

  // All checks passed - can skip
  (true, meta.duration)
}

///|
/// Save segment metadata after generation
async fn save_segment_metadata(
  meta_file : String,
  duration : Double,
  content_hash : String,
  audio_hash : String,
) -> Unit {
  let meta : SegmentMeta = { duration, content_hash, audio_hash }
  write_file(meta_file, Json::stringify(meta.to_json()))
}
