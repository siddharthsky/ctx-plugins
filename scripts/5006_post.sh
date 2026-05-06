#!/bin/bash

PORT=0
UPDATE=false

# 🔹 Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --port)
      PORT="$2"
      shift 2
      ;;
    --update)
      UPDATE=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# 🔹 Require port only when needed
if [ "$PORT" -eq 0 ]; then
  echo "Port not provided! Use --port <number>"
  exit 1
fi

echo "Using Port: $PORT"

INSTALL_URL="https://jiotv_go.rabil.me/install.sh"
PROJECT_DIR="$(pwd)"
PLUGIN_DIR="$PROJECT_DIR/.jiotv_go"
BINARY_PATH="$PLUGIN_DIR/bin/jiotv_go"
RUN_BIN="$PROJECT_DIR/run.bin"
LAUNCH_SCRIPT="$PROJECT_DIR/$PORT.sh"

# 🔹 Create launcher script
create_launcher() {
  rm -f "$LAUNCH_SCRIPT"

  cat > "$LAUNCH_SCRIPT" <<EOF
#!/bin/bash
cd "$PROJECT_DIR"
./run.bin run --port $PORT --public
EOF

  chmod +x "$LAUNCH_SCRIPT"
  echo "Launcher ready: $PORT.sh"
}

# 🔹 Install or reinstall plugin
install_plugin() {
  export SHELL=/bin/bash

  echo "Downloading latest installer..."
  curl -fsSL "$INSTALL_URL" | bash || {
    echo "Installation failed!"
    exit 1
  }
}

# 🔹 Update mode
run_update() {
  echo "Updating Plugin..."

  # Remove old binary
  rm -f "$BINARY_PATH"

  install_plugin

  # Ensure local plugin folder exists
  mkdir -p "$PLUGIN_DIR/bin"

  # Replace binary
  mv -f "$HOME/.jiotv_go/bin/jiotv_go" "$BINARY_PATH"

  # Refresh symlink
  ln -sf "$BINARY_PATH" "$RUN_BIN"

  if [ -f "$RUN_BIN" ]; then
    echo "run.bin updated successfully"
    create_launcher
  else
    echo "Update failed: run.bin not found"
    exit 1
  fi

  echo "Update complete"
  sleep 2
  exit 0
}

# 🔹 Update-only mode
if [ "$UPDATE" = true ]; then
  run_update
fi

# 🔹 Normal install mode
echo "Installing Plugin..."

install_plugin

# Remove old install if exists
rm -rf "$PLUGIN_DIR"

# Move fresh install locally
mv "$HOME/.jiotv_go" "$PLUGIN_DIR"

# Create symlink
ln -sf "$BINARY_PATH" "$RUN_BIN"

if [ -f "$RUN_BIN" ]; then
  echo "Plugin installed successfully"
  create_launcher
else
  echo "Installation failed: run.bin missing"
  exit 1
fi

echo "Setup complete. Run ./$PORT.sh to start server."
sleep 2
