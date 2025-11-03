// types.mbt - Shared data structures for mdcourse

///|
/// Slide information
priv struct SlideInfo {
  id : String
  ssml_hash : String
  has_audio : Bool
} derive (
  ToJson(fields(ssml_hash(rename="ssmlHash"), has_audio(rename="hasAudio"))),
)

///|
/// Video segment that follows a slide
priv struct VideoSegment {
  after_slide : String
  video_path : String
  ssml_hash : String
  has_audio : Bool
} derive (
  ToJson(
    fields(
      after_slide(rename="afterSlide"),
      video_path(rename="videoPath"),
      ssml_hash(rename="ssmlHash"),
      has_audio(rename="hasAudio"),
    ),
  ),
)

///|
/// Manifest file structure
priv struct Manifest {
  slides : Array[SlideInfo]
  videos : Array[VideoSegment]
} derive(ToJson)

///|
/// Audio metadata
priv struct AudioMeta {
  duration : Double
  hash : String
} derive(ToJson)

///|
/// CLI options
pub struct Options {
  input_file : String
  output_file : String?
  parse_only : Bool
  slides_only : Bool
  audio_only : Bool
  compose_only : Bool
  force_audio : Bool
  keep_temp : Bool
  voice : String
  fps : Int
  resolution : String
  retry : Int
  default_duration : Double
  theme : String
  engine : String
}

///|
/// Resolution preset
priv struct Resolution {
  width : Int
  height : Int
}

///|
/// Parse resolution preset to width and height
fn parse_resolution(preset : String) -> Resolution {
  match preset {
    "4k" | "4K" => { width: 3840, height: 2160 }
    "1440p" | "1440P" => { width: 2560, height: 1440 }
    "1080p" | "1080P" => { width: 1920, height: 1080 }
    "720p" | "720P" => { width: 1280, height: 720 }
    "480p" | "480P" => { width: 854, height: 480 }
    _ => { width: 1920, height: 1080 } // default to 1080p
  }
}

///|
/// Get resource directory (either MDCOURSE_DIR env var or current directory)
fn get_resource_dir() -> String {
  match @sys.get_env_vars().get("MDCOURSE_DIR") {
    Some(dir) => dir
    None => "."
  }
}

///|
/// Create Options from parsed CLI arguments
pub fn Options::new(
  voice : String,
  fps : Int,
  resolution : String,
  retry : Int,
  force_audio : Bool,
  keep_temp : Bool,
  default_duration : Double,
  output_file : String?,
) -> Options {
  let resource_dir = get_resource_dir()
  let theme_path = if resource_dir == "." {
    "custom.css"
  } else {
    resource_dir + "/custom.css"
  }
  let engine_path = if resource_dir == "." {
    "engine.mjs"
  } else {
    resource_dir + "/engine.mjs"
  }
  {
    input_file: "",
    output_file,
    parse_only: false,
    slides_only: false,
    audio_only: false,
    compose_only: false,
    force_audio,
    keep_temp,
    voice,
    fps,
    resolution,
    retry,
    default_duration,
    theme: theme_path,
    engine: engine_path,
  }
}
