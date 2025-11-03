// slides.mbt - Generate slide images using Marp CLI and pdftoppm

///|
/// Generate slide images from markdown file
/// Step 1: Use Marp CLI to generate PDF
/// Step 2: Use pdftoppm to convert PDF to PNG images
pub async fn generate_slides(
  input_file : String,
  output_dir : String,
  options : Options,
) -> Unit {
  println("Generating slides...")
  let slides_dir = slides_dir(output_dir)
  create_dir_all(slides_dir)

  // Get PDF filename (same as input but .pdf extension)
  let pdf_file = get_pdf_filename(input_file)

  // Step 1: Generate PDF using Marp CLI
  println("   Generating PDF...")
  generate_pdf(input_file, pdf_file, options)

  // Step 2: Convert PDF to PNG images using pdftoppm
  println("   Converting PDF to PNG images...")
  convert_pdf_to_png(pdf_file, slides_dir)

  // Count generated slides
  let slide_files = list_slide_files(slides_dir)
  println("   [+] Generated \{slide_files.length()} slide images")

  // Show first few filenames
  let show_count = if slide_files.length() < 3 {
    slide_files.length()
  } else {
    3
  }
  for i = 0; i < show_count; i = i + 1 {
    println("     - \{slide_files[i]}")
  }
  if slide_files.length() > 3 {
    println("     ... and \{slide_files.length() - 3} more")
  }
}

///|
/// Generate PDF from markdown using Marp CLI
async fn generate_pdf(
  input_file : String,
  pdf_file : String,
  options : Options,
) -> Unit {
  let args : Array[String] = [
    "@marp-team/marp-cli",
    "--theme",
    options.theme,
    "--engine",
    options.engine,
    input_file,
    "--pdf",
    "--allow-local-files",
    "--html",
    "-o",
    pdf_file,
  ]
  let (exit_code, _stdout, stderr) = @process.collect_output("npx", args)
  if exit_code != 0 {
    println("   [ERROR] Marp CLI failed with exit code \{exit_code}")
    let error_text = stderr.text()
    if !error_text.is_empty() {
      println("   stderr: \{error_text}")
    }
    abort("Marp PDF generation failed")
  }
  println("   [+] PDF saved: \{pdf_file}")
}

///|
/// Convert PDF to PNG images using pdftoppm
async fn convert_pdf_to_png(pdf_file : String, slides_dir : String) -> Unit {
  // Remove all existing PNG files first to avoid conflicts
  let entries = @fs.readdir(slides_dir) catch { _ => [] }
  for entry in entries {
    if entry.has_suffix(".png") {
      let file_path = path_join([slides_dir, entry])
      @fs.remove(file_path)
    }
  }

  let args : Array[String] = [
    "-png",
    "-r",
    "300", // 300 DPI resolution
    pdf_file,
    slides_dir + "/slide",
  ]
  let (exit_code, _stdout, stderr) = @process.collect_output("pdftoppm", args)
  if exit_code != 0 {
    println("   [ERROR] pdftoppm failed with exit code \{exit_code}")
    let error_text = stderr.text()
    if !error_text.is_empty() {
      println("   stderr: \{error_text}")
    }
    abort("PDF to PNG conversion failed")
  }

  // Rename slides from pdftoppm format (slide-1.png, slide-2.png) to standard format (slide-001.png, slide-002.png)
  rename_slides(slides_dir)
}

///|
/// Get PDF filename from input markdown file
/// Example: "../course7/lec7-1.mbt.md" -> "../course7/lec7-1.pdf"
fn get_pdf_filename(input_file : String) -> String {
  // Remove .mbt.md or .md extension
  let mut result = input_file[:]
  if result.has_suffix(".mbt.md") {
    let len = result.length()
    result = try! result[0:len - 7]
  } else if result.has_suffix(".md") {
    let len = result.length()
    result = try! result[0:len - 3]
  }
  result.to_string() + ".pdf"
}

///|
/// List all PNG files in slides directory
async fn list_slide_files(slides_dir : String) -> Array[String] {
  let files : Array[String] = []

  // Try to read directory, return empty array if it doesn't exist
  let dir_exists = @fs.exists(slides_dir) catch { _ => false }
  if !dir_exists {
    return files
  }
  let entries = @fs.readdir(slides_dir) catch { _ => [] }
  for entry in entries {
    if entry.has_suffix(".png") {
      files.push(entry)
    }
  }

  // Sort files naturally
  files.sort()
  files
}

///|
/// Rename slides from pdftoppm format to standard format
/// pdftoppm generates: slide-1.png, slide-2.png, ..., slide-10.png (no leading zeros)
/// We want: slide-001.png, slide-002.png, ..., slide-010.png (3-digit padding)
async fn rename_slides(slides_dir : String) -> Unit {
  struct SlideFile {
    name : String
    num : Int
  }

  let new_entries : Array[SlideFile] = []

  // Read directory and find pdftoppm-generated files
  let entries = @fs.readdir(slides_dir) catch { _ => [] }
  for entry in entries {
    if !entry.has_suffix(".png") {
      continue
    }

    // Match pdftoppm format: slide-1.png, slide-2.png (1-2 digits, no leading zeros)
    // Exclude already-renamed files: slide-001.png (3 digits)
    // Extract the number from the filename
    let parts : Array[String] = []
    for view in entry.split("-") {
      parts.push(view.to_string())
    }
    if parts.length() == 2 && parts[0] == "slide" {
      let num_part = parts[1]
      if num_part.has_suffix(".png") {
        let num_str = try num_part[0:num_part.length() - 4].to_string() catch {
          _ => continue
        }
        // Only accept 1-2 digit numbers (pdftoppm format)
        // Skip 3-digit numbers (already renamed files)
        if num_str.length() > 2 {
          continue
        }
        let parse_result = try? @strconv.parse_int(num_str)
        match parse_result {
          Ok(num) => new_entries.push({ name: entry, num })
          Err(_) => ()
        }
      }
    }
  }

  if new_entries.length() == 0 {
    println("   [WARN] No pdftoppm-generated slide images found")
    return
  }

  // Sort by number
  new_entries.sort_by(fn(a, b) { a.num - b.num })

  // Rename each file to standard format
  for i, slide_file in new_entries {
    let old_path = path_join([slides_dir, slide_file.name])
    let slide_id = pad_slide_id(i + 1)
    let new_name = "slide-\{slide_id}.png"
    let new_path = path_join([slides_dir, new_name])

    // Rename the file using mv command
    let (exit_code, _, _) = @process.collect_output("mv", [old_path, new_path])
    if exit_code != 0 {
      println("   [WARN] Failed to rename \{slide_file.name} to \{new_name}")
    }
  }

  println("   [+] Renamed \{new_entries.length()} slide images to standard format")
}
