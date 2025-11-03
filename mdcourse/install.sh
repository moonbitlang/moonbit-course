#!/bin/bash
# install.sh - Install mdcourse to user's local bin directory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Installation directories
INSTALL_DIR="$HOME/.mdcourse"
BIN_DIR="$HOME/.local/bin"

echo "==================================="
echo "mdcourse Installation Script"
echo "==================================="
echo ""

# Check if moon is installed
if ! command -v moon &> /dev/null; then
    echo -e "${RED}Error: moon command not found${NC}"
    echo "Please install MoonBit first:"
    echo "  curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm not found${NC}"
    echo "You'll need Node.js and npm to install Marp CLI and dependencies"
    echo "Install from: https://nodejs.org/"
    exit 1
fi

# Build the binary
echo -e "${GREEN}[1/4]${NC} Building mdcourse binary..."
moon build --target native

# Check for binary (try both .exe and no extension)
BINARY_PATH=""
if [ -f "target/native/release/build/cmd/main/main.exe" ]; then
    BINARY_PATH="target/native/release/build/cmd/main/main.exe"
elif [ -f "target/native/release/build/cmd/main/main" ]; then
    BINARY_PATH="target/native/release/build/cmd/main/main"
else
    echo -e "${RED}Error: Build failed - binary not found${NC}"
    echo "Expected location: target/native/release/build/cmd/main/main[.exe]"
    exit 1
fi

echo "Found binary: $BINARY_PATH"

# Create installation directory
echo -e "${GREEN}[2/4]${NC} Creating installation directory..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# Copy binary
echo -e "${GREEN}[3/4]${NC} Installing files..."
cp "$BINARY_PATH" "$INSTALL_DIR/mdcourse-bin"
chmod +x "$INSTALL_DIR/mdcourse-bin"

# Copy resources (from parent directory)
if [ -f "../engine.mjs" ]; then
    cp ../engine.mjs "$INSTALL_DIR/"
else
    echo -e "${YELLOW}Warning: engine.mjs not found in parent directory${NC}"
fi

if [ -f "../custom.css" ]; then
    cp ../custom.css "$INSTALL_DIR/"
else
    echo -e "${YELLOW}Warning: custom.css not found in parent directory${NC}"
fi

# Copy tmLanguage files if they exist
for file in ../moonbit.tmLanguage.json ../abnf.tmLanguage.json; do
    if [ -f "$file" ]; then
        cp "$file" "$INSTALL_DIR/"
    fi
done

# Install npm dependencies (Marp CLI and engine.mjs dependencies)
echo -e "${GREEN}Installing npm dependencies...${NC}"
cat > "$INSTALL_DIR/package.json" << 'PACKAGE_JSON'
{
  "type": "module",
  "dependencies": {
    "@marp-team/marp-cli": "^3.4.0",
    "shiki": "^1.1.7"
  }
}
PACKAGE_JSON

# Install npm packages in the resource directory
cd "$INSTALL_DIR"
npm install --silent 2>&1 | grep -v "npm WARN" || true
cd - > /dev/null

# Create wrapper script
echo -e "${GREEN}[4/4]${NC} Creating wrapper script..."
cat > "$BIN_DIR/mdcourse" << 'EOF'
#!/bin/bash
# mdcourse wrapper script
# Sets MDCOURSE_DIR for resource location

export MDCOURSE_DIR="$HOME/.mdcourse"

# Check if resource directory exists
if [ ! -d "$MDCOURSE_DIR" ]; then
    echo "Error: mdcourse directory not found at $MDCOURSE_DIR"
    echo "Please run the install script again"
    exit 1
fi

# Execute the binary directly (no cd needed - all paths are absolute)
exec "$MDCOURSE_DIR/mdcourse-bin" "$@"
EOF

chmod +x "$BIN_DIR/mdcourse"

# Check if ~/.local/bin is in PATH
echo ""
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo -e "${YELLOW}Warning: $HOME/.local/bin is not in your PATH${NC}"
    echo "Add this line to your ~/.bashrc or ~/.zshrc:"
    echo ""
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# Success message
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo "Installed files:"
echo "  Binary:    $INSTALL_DIR/mdcourse-bin"
echo "  Resources: $INSTALL_DIR/"
echo "  Wrapper:   $BIN_DIR/mdcourse"
echo ""
echo "Usage:"
echo "  mdcourse input.mbt.md"
echo "  mdcourse --help"
echo ""
echo "To uninstall:"
echo "  rm -rf $INSTALL_DIR"
echo "  rm $BIN_DIR/mdcourse"
