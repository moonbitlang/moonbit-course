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
) -> Unit {
  println("Composing video...")

  // Check if ffmpeg is installed
  if !check_ffmpeg() {
    println("   [ERROR] ffmpeg not found")
    println("   Please install ffmpeg:")
    println("     macOS: brew install ffmpeg")
    println("     Ubuntu: sudo apt install ffmpeg")
    println("     Windows: https://ffmpeg.org/download.html")
    return
  }

  // 1. Parse manifest.json
  let manifest_path = manifest_path(output_dir)
  let manifest_json = @fs.read_file(manifest_path).text()
  let manifest = parse_manifest_for_compose(manifest_json)
  if manifest.slides.length() == 0 {
    println("   [ERROR] No slides found in manifest")
    return
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

    // Get duration from metadata or use default
    let duration = if slide.has_audio {
      let meta_file = slide_meta_path(output_dir, slide.id)
      match parse_audio_metadata(meta_file) {
        Some(meta) => meta.duration
        None => {
          println(
            "   [WARN] Could not read duration for slide-\{slide.id}, using default",
          )
          options.default_duration
        }
      }
    } else {
      options.default_duration
    }
    total_duration = total_duration + duration
    println(
      "   [*] Generating segment \{segment_counter - 1}/\{manifest.slides.length() + manifest.videos.length()}: slide-\{slide.id} (\{duration}s)",
    )

    // Generate ffmpeg command for slide
    let resolution = parse_resolution(options.resolution)
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
      return
    }

    // Check if there's a video to insert after this slide
    for video in manifest.videos {
      if video.after_slide == slide.id {
        let video_segment_file = path_join([
          segments_dir,
          "segment-\{pad_slide_id(segment_counter)}.mp4",
        ])
        segment_files.push(video_segment_file)
        segment_counter = segment_counter + 1

        // Process video with optional narration
        let video_duration = get_video_duration(video.video_path)
        let narration_audio : String? = if video.has_audio {
          Some(video_audio_path(output_dir, slide.id))
        } else {
          None
        }

        let final_duration = match narration_audio {
          Some(_audio_path) => {
            let meta_file = video_meta_path(output_dir, slide.id)
            match parse_audio_metadata(meta_file) {
              Some(meta) => {
                if meta.duration > video_duration {
                  meta.duration
                } else {
                  video_duration
                }
              }
              None => video_duration
            }
          }
          None => video_duration
        }

        total_duration = total_duration + final_duration
        println(
          "   [*] Generating segment \{segment_counter - 1}/\{manifest.slides.length() + manifest.videos.length()}: video after slide-\{slide.id} (\{final_duration}s)",
        )

        // Generate video segment with optional audio mixing
        let video_args = generate_video_segment_command(
          video.video_path,
          narration_audio,
          video_duration,
          video_segment_file,
          resolution,
          options.fps,
        )

        let (exit_code, _stdout, stderr) = @process.collect_output(
          "ffmpeg", video_args,
        )
        if exit_code != 0 {
          println("   [ERROR] Failed to generate video segment \{segment_counter - 1}")
          println("   ffmpeg error: \{stderr.text()}")
          return
        }
      }
    }
  }

  // 4. Concatenate all segments
  println("   [*] Concatenating \{segment_files.length()} segments...")
  let concat_list_file = path_join([segments_dir, "concat.txt"])
  let concat_content = generate_concat_list(segment_files)
  write_file(concat_list_file, concat_content)
  let final_output = match output_file {
    Some(path) => path
    None => path_join([output_dir, "output.mp4"])
  }
  let concat_args : Array[String] = [
    "-f", "concat", "-safe", "0", "-i", concat_list_file, "-c", "copy", "-y", final_output,
  ]
  let (exit_code, _stdout, stderr) = @process.collect_output(
    "ffmpeg", concat_args,
  )
  if exit_code != 0 {
    println("   [ERROR] Failed to concatenate segments")
    println("   ffmpeg error: \{stderr.text()}")
    return
  }

  // 5. Cleanup temp segments if not keeping
  if !options.keep_temp {
    println("   [*] Cleaning up temporary segments...")
    for segment in segment_files {
      remove_file(segment)
    }
    remove_file(concat_list_file)
  }
  println("   [+] Video composed successfully!")
  println("   Duration: \{total_duration}s")
  println(
    "   Size: ~\{estimate_video_size(total_duration, parse_resolution(options.resolution))}MB",
  )
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
  match audio_path {
    Some(path) => {
      args.push("-i")
      args.push(path)
    }
    None => ()
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
  match audio_path {
    Some(_) => {
      args.push("-c:a")
      args.push("aac")
      args.push("-ar")
      args.push("44100")
      args.push("-shortest")
    }
    None => {
      args.push("-t")
      args.push(duration.to_string())
      args.push("-an")
    }
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
  video_duration : Double,
  output_path : String,
  resolution : Resolution,
  fps : Int,
) -> Array[String] {
  let args : Array[String] = []

  // Check if video has its own audio stream
  let video_has_audio = has_audio_stream(video_path)

  match narration_audio {
    Some(audio_path) => {
      // Case 1 & 2: Video with narration (mix or replace audio)
      args.push("-i")
      args.push(video_path)
      args.push("-i")
      args.push(audio_path)

      // Video filter: scale + pad + loop if needed
      let scale_filter = "scale=\{resolution.width}:\{resolution.height}:force_original_aspect_ratio=decrease,pad=\{resolution.width}:\{resolution.height}:(ow-iw)/2:(oh-ih)/2"

      // Get narration duration from metadata by replacing .wav with .meta.json
      let meta_path = audio_path[0:audio_path.length() - 4].to_string() + ".meta.json"
      let narration_duration = match parse_audio_metadata(meta_path) {
        Some(meta) => meta.duration
        None => video_duration  // Fallback to video duration if no metadata
      }

      if narration_duration > video_duration {
        // Need to loop the video to match narration length
        let loop_count = (narration_duration / video_duration).ceil().to_int()
        args.push("-filter_complex")
        args.push(
          "[0:v]loop=loop=\{loop_count}:size=1:start=0,\{scale_filter}[v]",
        )
        args.push("-map")
        args.push("[v]")
      } else {
        // No looping needed
        args.push("-vf")
        args.push(scale_filter)
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
      args.push("-shortest")
    }
    None => {
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
/// Parse manifest for video composition
fn parse_manifest_for_compose(json_str : String) -> Manifest {
  let json = @json5.parse(json_str) catch {
    e => abort("JSON parse error: \{e}")
  }
  match json {
    Object(map) => {
      let slides = match map.get("slides") {
        Some(Array(slide_array)) => {
          let slides_result : Array[SlideInfo] = []
          for slide_json in slide_array {
            match slide_json {
              Object(slide_map) => {
                let id = match slide_map.get("id") {
                  Some(String(s)) => s
                  _ => abort("slide.id missing")
                }
                let ssml_hash = match slide_map.get("ssmlHash") {
                  Some(String(s)) => s
                  _ => ""
                }
                let has_audio = match slide_map.get("hasAudio") {
                  Some(True) => true
                  Some(False) => false
                  _ => false
                }
                slides_result.push({ id, ssml_hash, has_audio })
              }
              _ => ()
            }
          }
          slides_result
        }
        _ => []
      }
      let videos = match map.get("videos") {
        Some(Array(video_array)) => {
          let videos_result : Array[VideoSegment] = []
          for video_json in video_array {
            match video_json {
              Object(video_map) => {
                let after_slide = match video_map.get("afterSlide") {
                  Some(String(s)) => s
                  _ => continue
                }
                let video_path = match video_map.get("videoPath") {
                  Some(String(s)) => s
                  _ => continue
                }
                let ssml_hash = match video_map.get("ssmlHash") {
                  Some(String(s)) => s
                  _ => ""
                }
                let has_audio = match video_map.get("hasAudio") {
                  Some(True) => true
                  Some(False) => false
                  _ => false
                }
                videos_result.push({ after_slide, video_path, ssml_hash, has_audio })
              }
              _ => ()
            }
          }
          videos_result
        }
        _ => []
      }
      { slides, videos }
    }
    _ => abort("manifest.json is not a JSON object")
  }
}

///|
/// Parse audio metadata file
async fn parse_audio_metadata(meta_file : String) -> AudioMeta? {
  if !@fs.exists(meta_file) {
    return None
  }
  let json_str = @fs.read_file(meta_file).text()
  let json = @json5.parse(json_str) catch { _ => return None }
  match json {
    Object(map) => {
      let duration = match map.get("duration") {
        Some(Number(n, ..)) => n
        _ => return None
      }
      let hash = match map.get("hash") {
        Some(String(s)) => s
        _ => ""
      }
      Some({ duration, hash })
    }
    _ => None
  }
}
