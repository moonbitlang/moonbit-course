// io.mbt - File I/O operations using @fs package

///|
/// Read a file to string
async fn read_file(path : String) -> String {
  let data = @fs.read_file(path)
  data.text()
}

///|
/// Write string to file
async fn write_file(path : String, content : String) -> Unit {
  @fs.write_file(path, @encoding/utf8.encode(content), create=0o644)
}

///|
/// Create directory and all parents
async fn create_dir_all(path : String) -> Unit {
  // Split path and create each level
  let parts : Array[String] = []
  for view in path.split("/") {
    parts.push(view.to_string())
  }
  let mut current = ""
  for part in parts {
    if part.is_empty() {
      continue
    }
    current = if current.is_empty() { part } else { current + "/" + part }
    let dir_exists = @fs.exists(current)
    if !dir_exists {
      @fs.mkdir(current, permission=0o755)
    }
  }
}

///|
/// Remove file
async fn remove_file(path : String) -> Unit {
  @fs.remove(path)
}

///|
/// Get basename from path
fn basename(path : String) -> String {
  let parts : Array[String] = []
  for view in path.split("/") {
    parts.push(view.to_string())
  }
  if parts.length() == 0 {
    return ""
  }
  parts[parts.length() - 1]
}
