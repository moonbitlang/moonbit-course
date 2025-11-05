// tts.mbt - Text-to-Speech using Azure Cognitive Services

///|
/// Task for concurrent audio generation
priv struct AudioGenTask {
  slide : SlideInfo
  audio_file : String
  meta_file : String
  ssml_file : String
}

///|
/// Result of audio generation
priv struct AudioGenResult {
  slide_id : String
  duration : Double
}

///|
/// Generate audio files from SSML using Azure TTS
///
/// Workflow:
/// 1. Read manifest.json to get list of slides with SSML
/// 2. For each slide with audio:
///    - Check if audio already exists and hasn't changed (via hash)
///    - Read SSML file
///    - Wrap SSML in proper XML document
///    - Call Azure TTS REST API
///    - Save WAV file
///    - Calculate duration from WAV header
///    - Save metadata (duration + hash)
pub async fn generate_audio(output_dir : String, options : Options) -> Unit {
  println("Generating audio...")

  // 1. Get environment variables
  let env_vars = @sys.get_env_vars()
  guard env_vars.get("TTS_KEY") is Some(tts_key) else {
    println("   [ERROR] TTS_KEY environment variable not set")
    println("   Please set TTS_KEY and TTS_REGION:")
    println("     export TTS_KEY=\"your-azure-subscription-key\"")
    println("     export TTS_REGION=\"eastus\"")
    return
  }
  guard env_vars.get("TTS_REGION") is Some(tts_region) else {
    println("   [ERROR] TTS_REGION environment variable not set")
    return
  }

  // 2. Parse manifest.json
  let manifest_path = manifest_path(output_dir)
  let manifest_json = @fs.read_file(manifest_path).text()
  let manifest = parse_manifest_full(manifest_json)

  // 3. Prepare tasks for slides that need audio generation
  let tasks : Array[AudioGenTask] = []
  let mut skipped = 0
  for slide in manifest.slides {
    if !slide.has_audio {
      println("   [ ] slide-\{slide.id}: Skip (no audio)")
      continue
    }

    // Check if audio exists and unchanged
    let meta_file = slide_meta_path(output_dir, slide.id)
    if !options.force_audio && should_skip(meta_file, slide.ssml_hash) {
      println("   [+] slide-\{slide.id}: Skip (exists and unchanged)")
      skipped = skipped + 1
      continue
    }

    // Add to task list
    let audio_file = slide_audio_path(output_dir, slide.id)
    let ssml_file = slide_ssml_path(output_dir, slide.id)
    tasks.push({ slide, audio_file, meta_file, ssml_file })
  }

  // 4. Prepare tasks for videos that need audio generation
  // Group videos by slide to track indices
  let videos_by_slide : Map[String, Array[(Int, VideoSegment)]] = {}
  for video in manifest.videos {
    if !video.has_audio {
      continue
    }
    let slide_videos = videos_by_slide.get_or_default(video.after_slide, [])
    slide_videos.push((slide_videos.length() + 1, video)) // 1-based index
    videos_by_slide[video.after_slide] = slide_videos
  }

  for entry in videos_by_slide {
    let slide_id = entry.0
    let indexed_videos = entry.1
    for indexed_video in indexed_videos {
      let video_index = indexed_video.0
      let video = indexed_video.1
      // Check if audio exists and unchanged
      let meta_file = video_meta_path_indexed(output_dir, slide_id, video_index)
      if !options.force_audio && should_skip(meta_file, video.ssml_hash) {
        println(
          "   [+] video-after-\{slide_id}-\{video_index}: Skip (exists and unchanged)",
        )
        skipped = skipped + 1
        continue
      }

      // Add to task list - convert VideoSegment to SlideInfo for compatibility
      let video_as_slide : SlideInfo = {
        id: "video-after-\{slide_id}-\{video_index}",
        ssml_hash: video.ssml_hash,
        has_audio: video.has_audio,
      }
      let audio_file = video_audio_path_indexed(output_dir, slide_id, video_index)
      let ssml_file = video_ssml_path_indexed(output_dir, slide_id, video_index)
      tasks.push({ slide: video_as_slide, audio_file, meta_file, ssml_file })
    }
  }

  // 5. Generate audio concurrently using task group
  if tasks.length() == 0 {
    println("Audio generation complete: 0 generated, \{skipped} skipped")
    return
  }
  let results : Array[Result[AudioGenResult, String]] = []
  @async.with_task_group(fn(tg) {
    for task in tasks {
      tg.spawn_bg(fn() {
        let result = generate_single_audio(
          task.slide.id,
          task.slide.ssml_hash,
          task.audio_file,
          task.meta_file,
          task.ssml_file,
          options.voice,
          tts_key,
          tts_region,
          options.retry,
        )
        results.push(result)
      })
    }
  })

  // 5. Report results (after all tasks complete)
  let mut generated = 0
  for result in results {
    match result {
      Ok(audio_result) => {
        println(
          "   [+] slide-\{audio_result.slide_id}: Generated (\{audio_result.duration}s)",
        )
        generated = generated + 1
      }
      Err(error) => println("   [ERROR] \{error}")
    }
  }
  println(
    "Audio generation complete: \{generated} generated, \{skipped} skipped",
  )
}

///|
/// Generate audio for a single slide
async fn generate_single_audio(
  slide_id : String,
  ssml_hash : String,
  audio_file : String,
  meta_file : String,
  ssml_file : String,
  voice : String,
  tts_key : String,
  tts_region : String,
  max_retries : Int,
) -> Result[AudioGenResult, String] {
  println("   [*] slide-\{slide_id}: Generating audio...")
  let ssml_content = @fs.read_file(ssml_file).text()
  let full_ssml = wrap_ssml(ssml_content, voice)

  // Call Azure TTS API with retry
  match
    synthesize_with_retry(
      full_ssml, audio_file, tts_key, tts_region, max_retries,
    ) {
    Ok(duration) => {
      // Save metadata
      let meta : AudioMeta = { duration, hash: ssml_hash }
      write_file(meta_file, Json::stringify(meta.to_json()))
      Ok({ slide_id, duration })
    }
    Err(error) => Err("slide-\{slide_id}: Failed - \{error}")
  }
}

///|
/// Wrap SSML content into complete SSML document
fn wrap_ssml(content : String, voice : String) -> String {
  "<speak version=\"1.0\" xmlns=\"http://www.w3.org/2001/10/synthesis\" xml:lang=\"zh-CN\">\n  <voice name=\"\{voice}\">\n    <p>\n      \{content}\n    </p>\n  </voice>\n</speak>"
}

///|
/// Check if audio should be skipped (exists and hash matches)
async fn should_skip(meta_file : String, current_hash : String) -> Bool {
  if !@fs.exists(meta_file) {
    return false
  }
  let meta_json = @fs.read_file(meta_file).text()
  let meta = parse_audio_meta(meta_json)
  meta.hash == current_hash
}

///|
/// Synthesize speech with retry logic
async fn synthesize_with_retry(
  ssml : String,
  output_file : String,
  tts_key : String,
  tts_region : String,
  max_retries : Int,
) -> Result[Double, String] {
  let mut last_error = ""
  for attempt = 1; attempt <= max_retries; attempt = attempt + 1 {
    match synthesize_speech(ssml, output_file, tts_key, tts_region) {
      Ok(duration) => return Ok(duration)
      Err(error) => {
        last_error = error
        if attempt < max_retries {
          let delay = min(1000 * pow(2, attempt - 1), 10000)
          println(
            "   [WARN] Attempt \{attempt}/\{max_retries} failed: \{error}",
          )
          println("   [WAIT] Retrying in \{delay}ms...")
          // TODO: Add sleep when available
          // @async.sleep(delay)
        }
      }
    }
  }
  Err("Failed after \{max_retries} attempts: \{last_error}")
}

///|
/// Call Azure TTS API to synthesize speech
async fn synthesize_speech(
  ssml : String,
  output_file : String,
  tts_key : String,
  tts_region : String,
) -> Result[Double, String] {
  // Connect to Azure TTS endpoint
  let host = "\{tts_region}.tts.speech.microsoft.com"
  let headers = {
    "Ocp-Apim-Subscription-Key": tts_key,
    "X-Microsoft-OutputFormat": "riff-24khz-16bit-mono-pcm",
    "User-Agent": "mdcourse-moonbit/0.1.0",
  }
  let client = @http.Client::connect(host, headers~, protocol=Https)

  // POST SSML to Azure TTS API
  let extra_headers = { "Content-Type": "application/ssml+xml" }
  let response = client.post(
    "/cognitiveservices/v1",
    ssml, // String implements Data trait
    extra_headers~,
  )

  // Check response status
  if response.code != 200 {
    client.close()
    return Err("TTS API error: HTTP \{response.code} - \{response.reason}")
  }

  // Read binary audio data
  let audio_data = client.read_all()
  let audio_bytes = audio_data.binary()
  client.close()

  // Save WAV file
  @fs.write_file(output_file, audio_bytes, create=0o644)

  // Calculate duration from WAV header
  let duration = get_wav_duration(audio_bytes)
  Ok(duration)
}

///|
/// Helper: min of two integers
fn min(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
/// Helper: power function for integers
fn pow(base : Int, exp : Int) -> Int {
  let mut result = 1
  for _i = 0; _i < exp; _i = _i + 1 {
    result = result * base
  }
  result
}

///|
/// Parse manifest.json to extract slide and video info
fn parse_manifest_full(json_str : String) -> Manifest {
  let json = @json5.parse(json_str) catch {
    e => abort("JSON parse error: \{e}")
  }
  guard json is Object(map) else { abort("manifest.json is not a JSON object") }
  let slides = match map.get("slides") {
    Some(Array(slide_array)) => {
      let slides_result : Array[SlideInfo] = []
      for slide_json in slide_array {
        let slide = parse_slide_info(slide_json)
        slides_result.push(slide)
      }
      slides_result
    }
    _ => []
  }
  let videos = match map.get("videos") {
    Some(Array(video_array)) => {
      let videos_result : Array[VideoSegment] = []
      for video_json in video_array {
        guard video_json is Object(video_map) else { continue }
        guard video_map.get("afterSlide") is Some(String(after_slide)) else {
          continue
        }
        guard video_map.get("videoPath") is Some(String(video_path)) else {
          continue
        }
        let ssml_hash = if video_map.get("ssmlHash") is Some(String(s)) {
          s
        } else {
          ""
        }
        let has_audio = if video_map.get("hasAudio") is Some(True) {
          true
        } else if video_map.get("hasAudio") is Some(False) {
          false
        } else {
          false
        }
        videos_result.push({ after_slide, video_path, ssml_hash, has_audio })
      }
      videos_result
    }
    _ => []
  }
  { slides, videos }
}

///|
/// Parse individual slide info from JSON
fn parse_slide_info(json : Json) -> SlideInfo {
  guard json is Object(map) else { abort("slide is not a JSON object") }
  guard map.get("id") is Some(String(id)) else {
    abort("slide.id missing or not a string")
  }
  guard map.get("ssmlHash") is Some(String(ssml_hash)) else {
    abort("slide.ssmlHash missing or not a string")
  }
  let has_audio = if map.get("hasAudio") is Some(True) {
    true
  } else if map.get("hasAudio") is Some(False) {
    false
  } else {
    abort("slide.hasAudio missing or not a boolean")
  }
  { id, ssml_hash, has_audio }
}

///|
/// Parse audio metadata from JSON
fn parse_audio_meta(json_str : String) -> AudioMeta {
  let json = @json5.parse(json_str) catch {
    e => abort("JSON parse error: \{e}")
  }
  guard json is Object(map) else { abort("meta.json is not a JSON object") }
  guard map.get("duration") is Some(Number(duration, ..)) else {
    abort("duration missing or not a number")
  }
  guard map.get("hash") is Some(String(hash)) else {
    abort("hash missing or not a string")
  }
  { duration, hash }
}
