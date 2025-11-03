// parse.mbt - Markdown parsing with async file I/O

///|
/// Parse a markdown file and generate manifest
pub async fn parse_file(input_path : String, output_dir : String) -> Unit {
  println("Parsing file: \{input_path}")

  // Read the input file
  let content = read_file(input_path)

  // Split into pages (simplified - split by ---)
  let pages = split_pages_simple(content)
  println("   Found \{pages.length()} pages")

  // Create output directories
  create_dir_all(output_dir)
  create_dir_all(audio_dir(output_dir))

  // Process each page
  let slides : Array[SlideInfo] = []
  let videos : Array[VideoSegment] = []
  for i, page in pages {
    let slide_id = pad_slide_id(i + 1)

    // Extract video marker and its SSML (if any)
    let (video_path, video_ssml, page_without_video) = extract_video(page)

    // Extract slide SSML from the page (without video content)
    let ssml = extract_ssml_simple(page_without_video)
    let has_audio = !ssml.is_empty()
    let ssml_hash = if has_audio { hash_content(ssml) } else { "" }
    slides.push({ id: slide_id, ssml_hash, has_audio })

    // Save slide SSML if present
    if has_audio {
      let ssml_file = slide_ssml_path(output_dir, slide_id)
      write_file(ssml_file, ssml)
      println("   [+] slide-\{slide_id}: Saved SSML (\{ssml.length()} chars)")
    } else {
      println("   [ ] slide-\{slide_id}: No audio")
    }

    // Handle video insertion if present
    if !video_path.is_empty() {
      let has_video_audio = !video_ssml.is_empty()
      let video_ssml_hash = if has_video_audio { hash_content(video_ssml) } else { "" }

      videos.push({
        after_slide: slide_id,
        video_path,
        ssml_hash: video_ssml_hash,
        has_audio: has_video_audio,
      })

      // Save video SSML if present
      if has_video_audio {
        let video_ssml_file = video_ssml_path(output_dir, slide_id)
        write_file(video_ssml_file, video_ssml)
        println(
          "   [VIDEO] slide-\{slide_id} 后插入视频: \{video_path} (有配音, \{video_ssml.length()} chars)",
        )
      } else {
        println("   [VIDEO] slide-\{slide_id} 后插入视频: \{video_path}")
      }
    }
  }

  // Create manifest
  let manifest : Manifest = { slides, videos }

  // Save manifest as JSON
  let manifest_file = manifest_path(output_dir)
  let manifest_json = Json::stringify(manifest.to_json())
  write_file(manifest_file, manifest_json)
  println("   [+] Saved manifest.json")
  println("\nParsing complete!")
  println("   Output: \{output_dir}")
}

///|
/// Simple page splitting by --- delimiter and headingDivider
fn split_pages_simple(content : String) -> Array[String] {
  let result : Array[String] = []
  let lines : Array[String] = []
  for view in content.split("\n") {
    lines.push(view.to_string())
  }

  // Check if headingDivider: 1 is in frontmatter
  let mut has_heading_divider = false
  let mut in_frontmatter = true
  let mut frontmatter_count = 0
  for line in lines {
    if line.trim(char_set=" \t") == "---" {
      frontmatter_count += 1
      if frontmatter_count == 2 {
        break
      }
    }
    if frontmatter_count == 1 && line.contains("headingDivider: 1") {
      has_heading_divider = true
    }
  }
  let current_page : Array[String] = []
  in_frontmatter = true
  frontmatter_count = 0
  for line in lines {
    // Handle frontmatter - skip it entirely when using headingDivider
    if line.trim(char_set=" \t") == "---" {
      if in_frontmatter {
        frontmatter_count += 1
        if frontmatter_count == 2 {
          in_frontmatter = false
        }
        // Don't add frontmatter lines when using headingDivider
        if !has_heading_divider {
          current_page.push(line)
        }
        continue
      } else {
        // Page separator (only used when NOT using headingDivider)
        if current_page.length() > 0 {
          result.push(current_page.join("\n"))
          current_page.clear()
        }
        continue
      }
    }

    // Skip frontmatter content when using headingDivider
    if in_frontmatter && has_heading_divider {
      continue
    }

    // If headingDivider: 1, split on "# " headings
    if !in_frontmatter && has_heading_divider && line.has_prefix("# ") {
      // Only save previous page if it has substantial content (not just whitespace)
      if current_page.length() > 0 {
        let has_content = current_page
          .iter()
          .any(fn(l) { !l.trim(char_set=" \t\n").is_empty() })
        if has_content {
          result.push(current_page.join("\n"))
        }
        current_page.clear()
      }
    }
    current_page.push(line)
  }

  // Add last page
  if current_page.length() > 0 {
    result.push(current_page.join("\n"))
  }
  result
}

///|
/// Extract SSML from page content
fn extract_ssml_simple(page : String) -> String {
  let mut result = ""
  let mut in_ssml = false
  let lines : Array[String] = []
  for view in page.split("\n") {
    lines.push(view.to_string())
  }
  for line in lines {
    let trimmed = line.trim(char_set=" \t")
    if trimmed == "<!-- ssml" {
      in_ssml = true
      continue
    }
    if trimmed == "-->" && in_ssml {
      in_ssml = false
      continue
    }
    if in_ssml {
      result = result + line + "\n"
    }
  }
  result.trim(char_set=" \t\n").to_string()
}

///|
/// Extract video marker and optional SSML from page
/// Returns (video_path, video_ssml, page_without_video)
fn extract_video(page : String) -> (String, String, String) {
  // Look for: <!-- video path.mp4 -->
  // Optionally followed by: <!-- ssml\n...\n-->
  let lines : Array[String] = []
  for view in page.split("\n") {
    lines.push(view.to_string())
  }

  let mut video_path = ""
  let mut video_ssml = ""
  let mut in_video_ssml = false
  let result_lines : Array[String] = []

  let mut i = 0
  while i < lines.length() {
    let line = lines[i]
    let trimmed = line.trim(char_set=" \t")

    // Check for video marker
    if trimmed.has_prefix("<!-- video ") && trimmed.has_suffix(" -->") {
      // Extract video path: <!-- video path.mp4 -->
      let start = "<!-- video ".length()
      let end = trimmed.length() - " -->".length()
      let slice_result = try? trimmed[start:end]
      match slice_result {
        Ok(slice) => {
          let path_str = slice.to_string()
          video_path = path_str.trim(char_set=" \t").to_string()
        }
        Err(_) => {
          i += 1
          continue
        }
      }

      // Check if next line starts video SSML
      if i + 1 < lines.length() {
        let next_line = lines[i + 1].trim(char_set=" \t")
        if next_line == "<!-- ssml" {
          in_video_ssml = true
          i += 2  // Skip both video line and ssml opening
          continue
        }
      }
      i += 1
      continue
    }

    // If in video SSML block, collect until -->
    if in_video_ssml {
      if trimmed == "-->" {
        in_video_ssml = false
        i += 1
        continue
      }
      video_ssml = video_ssml + line + "\n"
      i += 1
      continue
    }

    // Keep lines that aren't video-related
    result_lines.push(line)
    i += 1
  }

  let page_without_video = result_lines.join("\n")
  (video_path, video_ssml.trim(char_set=" \t\n").to_string(), page_without_video)
}

///|
/// Get course name from input file path
pub fn get_course_name_from_path(input_file : String) -> String {
  // Get the filename without path
  let file_name = basename(input_file)

  // Remove .mbt.md or .md extension
  let mut base_name = file_name
  if base_name.has_suffix(".mbt.md") {
    let len = base_name.length()
    base_name = try base_name[0:len - 7].to_string() catch { _ => base_name }
  } else if base_name.has_suffix(".md") {
    let len = base_name.length()
    base_name = try base_name[0:len - 3].to_string() catch { _ => base_name }
  }

  // Use the base filename as the target directory name
  // Examples:
  //   lec7-1.mbt.md -> target/lec7-1/
  //   lec7-2.mbt.md -> target/lec7-2/
  //   slides.md -> target/slides/
  base_name
}
