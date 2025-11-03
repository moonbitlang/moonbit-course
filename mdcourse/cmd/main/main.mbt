///|
/// Main entry point for mdcourse CLI
async fn main {
  let cli_args = @sys.get_cli_args()

  // Define CLI arguments
  let parser = @clap.Parser::new(
    prog="mdcourse",
    description="Marp+SSML video generation tool",
    args={
      "output": @clap.Arg::named(
        short='o',
        nargs=One,
        help="Output video file path (default: ./output.mp4)",
        defaults=["./output.mp4"],
      ),
      "parse-only": @clap.Arg::flag(help="Only parse file"),
      "slides-only": @clap.Arg::flag(help="Only generate slide images"),
      "audio-only": @clap.Arg::flag(help="Only generate audio"),
      "compose-only": @clap.Arg::flag(help="Only compose video"),
      "force-audio": @clap.Arg::flag(help="Force regenerate all audio"),
      "keep-temp": @clap.Arg::flag(
        help="Keep temporary video segments for debugging",
      ),
      "voice": @clap.Arg::named(
        nargs=One,
        defaults=["zh-CN-YunyiMultilingualNeural"],
        help="Specify TTS voice",
      ),
      "fps": @clap.Arg::named(
        nargs=One,
        defaults=["30"],
        help="Video frame rate",
      ),
      "resolution": @clap.Arg::named(
        nargs=One,
        defaults=["1080p"],
        help="Video resolution (4k, 1440p, 1080p, 720p, 480p)",
      ),
      "retry": @clap.Arg::named(
        nargs=One,
        defaults=["3"],
        help="Retry count on TTS API failure",
      ),
      "default-duration": @clap.Arg::named(
        nargs=One,
        defaults=["3.0"],
        help="Default duration for slides without audio (seconds)",
      ),
      "input": @clap.Arg::positional(nargs=One, help="Input .mbt.md file"),
    },
  )
  let args = if cli_args.length() > 0 { cli_args[1:] } else { [] }

  // Parse arguments
  let value = @clap.SimpleValue::new("mdcourse")
  let help_msg = parser.parse(value, args) catch {
    e => {
      println("Error: \{e}")
      return
    }
  }

  // Show help if requested
  if help_msg is Some(msg) {
    println(msg)
    return
  }

  // Get input file (positional argument)
  let input_file = value.get_positional()[0] catch {
    e => {
      println("Error: \{e}")
      println("")
      println("Usage: mdcourse <input.mbt.md> [options]")
      println("Run 'mdcourse --help' for full help")
      return
    }
  }

  // Get flags
  let parse_only = value.get_flag("parse-only").unwrap_or(false)
  let slides_only = value.get_flag("slides-only").unwrap_or(false)
  let audio_only = value.get_flag("audio-only").unwrap_or(false)
  let compose_only = value.get_flag("compose-only").unwrap_or(false)
  let force_audio = value.get_flag("force-audio").unwrap_or(false)
  let keep_temp = value.get_flag("keep-temp").unwrap_or(false)

  // Get string options with defaults
  let voice : String = value.get_one("voice") catch {
    _ => "zh-CN-YunyiMultilingualNeural"
  }
  let fps_str : String = value.get_one("fps") catch { _ => "30" }
  let resolution : String = value.get_one("resolution") catch { _ => "1080p" }
  let retry_str : String = value.get_one("retry") catch { _ => "3" }
  let default_duration_str : String = value.get_one("default-duration") catch {
    _ => "3.0"
  }
  let output_file : String? = value.get_option("output") catch { _ => None }

  // Parse numeric values
  let fps = @strconv.parse_int(fps_str) catch {
    _ => {
      println("Error: Invalid fps value: \{fps_str}")
      return
    }
  }
  let retry = @strconv.parse_int(retry_str) catch {
    _ => {
      println("Error: Invalid retry value: \{retry_str}")
      return
    }
  }
  let default_duration = @strconv.parse_double(default_duration_str) catch {
    _ => {
      println("Error: Invalid default-duration value: \{default_duration_str}")
      return
    }
  }

  // Get course name from input file
  let course_name = @mdcourse.get_course_name_from_path(input_file)
  let output_dir = @mdcourse.target_dir(course_name)
  let options = @mdcourse.Options::new(
    voice, fps, resolution, retry, force_audio, keep_temp, default_duration, output_file,
  )
  println("mdcourse v0.1.0 - MoonBit Implementation")
  println("=========================================")
  println("Input:  \{input_file}")
  println("Output: \{output_dir}\n")

  // Step 1: Parse markdown and extract SSML (unless only composing)
  if !compose_only {
    @mdcourse.parse_file(input_file, output_dir)
    if parse_only {
      println("\nDone (parse only)")
      return
    }
  }

  // Step 2: Generate slide images (unless only audio or compose)
  if !audio_only && !compose_only {
    @mdcourse.generate_slides(input_file, output_dir, options)
    if slides_only {
      println("\nDone (slides only)")
      return
    }
  }

  // Step 3: Generate audio (unless only composing or only slides)
  if !compose_only && !slides_only {
    @mdcourse.generate_audio(output_dir, options)
    if audio_only {
      println("\nDone (audio only)")
      return
    }
  }

  // Step 4: Compose video (unless parse-only, audio-only, or slides-only)
  if !parse_only && !audio_only && !slides_only {
    @mdcourse.compose_video(output_dir, options.output_file, options)
    println("\nAll done!")
    if output_file is Some(path) {
      println("Video location: \{path}")
    } else {
      println("Video location: \{output_dir}/output.mp4")
    }
  }
}
