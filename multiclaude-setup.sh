#!/usr/bin/env bash
# Sets up wrapper commands for running multiple isolated Claude Code
# profiles (separate login, history, settings, plugins) side by side.
# Portable: only needs `claude` on PATH, works on any Linux/macOS box.
set -euo pipefail

BIN_DIR="${MULTICLAUDE_BIN_DIR:-$HOME/.local/bin}"
NAME_RE='^[a-zA-Z0-9_-]+$'

echo "Welcome to MultiClaude!"
echo "Let's set up a few isolated Claude Code profiles."
echo

if ! command -v claude >/dev/null 2>&1; then
  echo "Warning: 'claude' was not found on your PATH. The wrapper scripts" >&2
  echo "will still be created, but won't work until Claude Code is installed." >&2
  echo >&2
fi

names=()

prompt_name() {
  local prompt="$1" name
  while true; do
    read -rp "$prompt" name
    if [[ -z "$name" ]]; then
      echo "Name can't be empty."
    elif [[ ! "$name" =~ $NAME_RE ]]; then
      echo "Use only letters, numbers, '-' and '_'."
    elif [[ " ${names[*]-} " == *" $name "* ]]; then
      echo "You already added '$name'."
    else
      names+=("$name")
      break
    fi
  done
}

prompt_name "Name your first claude: "

while true; do
  read -rp "Add another claude? (y/n) " ans
  case "$ans" in
    y | Y) prompt_name "Name your claude: " ;;
    n | N) break ;;
    *) echo "Please answer y or n." ;;
  esac
done

echo
mkdir -p "$BIN_DIR"

for name in "${names[@]}"; do
  config_dir="$HOME/.$name"
  script_path="$BIN_DIR/$name"

  cat >"$script_path" <<EOF
#!/usr/bin/env bash
export CLAUDE_CONFIG_DIR="$config_dir"
exec claude "\$@"
EOF
  chmod +x "$script_path"
  mkdir -p "$config_dir"

  echo "Created $script_path (config dir: $config_dir)"
done

echo
echo "Done! Set up ${#names[@]} claude(s): ${names[*]}"

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo
  echo "$BIN_DIR is not on your PATH. Add this to your shell rc file:"
  echo "  export PATH=\"$BIN_DIR:\$PATH\""
fi

echo
echo "Next: log in to each one separately (they don't share credentials):"
for name in "${names[@]}"; do
  echo "  $name"
done
