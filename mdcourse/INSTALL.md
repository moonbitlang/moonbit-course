# Installation Script Summary

## What Was Created

### 1. install.sh
A bash script that:
- ✅ Checks for required dependencies (moon, npx)
- ✅ Builds the native binary using `moon build --target native`
- ✅ Creates installation directory at `~/.mdcourse/`
- ✅ Copies the binary as `mdcourse-bin`
- ✅ Copies all resource files:
  - `engine.mjs` (Marp engine configuration)
  - `custom.css` (Marp theme)
  - `moonbit.tmLanguage.json` (syntax highlighting)
  - `abnf.tmLanguage.json` (syntax highlighting)
- ✅ Creates a wrapper script at `~/.local/bin/mdcourse` that:
  - Sets `MDCOURSE_DIR` environment variable
  - Executes the binary from the current working directory
- ✅ Provides clear success messages and uninstall instructions

### 2. Updated Code (types.mbt)
Added resource directory detection:
```moonbit
fn get_resource_dir() -> String {
  match @sys.get_env_vars().get("MDCOURSE_DIR") {
    Some(dir) => dir
    None => "."  // Development mode - use current directory
  }
}
```

The Options constructor now builds paths dynamically:
- `theme: resource_dir + "/custom.css"` (or `"custom.css"` in dev mode)
- `engine: resource_dir + "/engine.mjs"` (or `"engine.mjs"` in dev mode)

### 3. Updated README.mbt.md
Added comprehensive installation instructions:
- Prerequisites (ffmpeg, poppler, node.js, moonbit)
- Build instructions
- System-wide installation using `./install.sh`
- Development usage without installation
- Uninstall instructions

## How It Works

### Development Mode (No Installation)
```bash
cd mdcourse
moon run cmd/main -- input.mbt.md
```
- `MDCOURSE_DIR` not set → uses current directory `.`
- Looks for `engine.mjs` and `custom.css` in parent directory `../`

### Installed Mode
```bash
mdcourse input.mbt.md
```
- Wrapper script sets `MDCOURSE_DIR=$HOME/.mdcourse`
- Binary looks for resources in `~/.mdcourse/`
- Works from any directory

## File Layout After Installation

```
~/.mdcourse/
├── mdcourse-bin               # The actual binary
├── engine.mjs                 # Marp engine (imports JSON)
├── custom.css                 # Marp theme
├── moonbit.tmLanguage.json    # Syntax highlighting
└── abnf.tmLanguage.json       # Syntax highlighting

~/.local/bin/
└── mdcourse                   # Wrapper script (sets MDCOURSE_DIR)

./mdcoursetarget/              # Output directory (created when running)
└── course-name/
    ├── manifest.json
    ├── audio/
    ├── slides/
    └── output.mp4
```

## Key Benefits

1. **Single Command**: After installation, just run `mdcourse input.mbt.md`
2. **Resource Bundling**: All dependencies travel together
3. **Node.js Compatible**: engine.mjs can still import JSON files
4. **Clean Uninstall**: Two simple `rm` commands
5. **Development Friendly**: Works without installation for development
6. **No PATH Pollution**: Only one script in ~/.local/bin

## Testing

```bash
# Test without installation (development mode)
cd mdcourse
moon run cmd/main -- --parse-only ../course7/lec7-1.mbt.md

# Install
./install.sh

# Test after installation
~/.local/bin/mdcourse --parse-only ../course7/lec7-1.mbt.md

# Or add to PATH and test
export PATH="$HOME/.local/bin:$PATH"
mdcourse --help

# Uninstall
rm -rf ~/.mdcourse
rm ~/.local/bin/mdcourse
```

## Notes

- The binary is named `main.exe` on macOS/Darwin (even though it's not Windows)
- The wrapper script stays in the current working directory, preserving relative paths
- Resources are found via `MDCOURSE_DIR` environment variable
- In development mode (no MDCOURSE_DIR), it looks for resources in `.` (current dir) or `../` (parent dir)
- The binary is named `mdcourse-bin` to avoid confusion with the wrapper script
- Installation size: ~1.4MB binary + ~60KB resources
