#!/usr/bin/env bash

set -ueo pipefail

: "${STEAM_DIR:?'ERROR: STEAM_DIR IS NOT SET!'}"

INSTALL_PLUGINS="${INSTALL_PLUGINS:-https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1293-linux.tar.gz
https://github.com/splewis/csgo-practice-mode/releases/download/1.3.4/practicemode_1.3.4.zip
}"

get_checksum_from_string () {
  local md5
  md5=$(echo -n "$1" | md5sum | awk '{print $1}')
  echo "$md5"
}

is_plugin_installed() {
  local url_hash
  url_hash=$(get_checksum_from_string "$1")
  if [[ -f "$STEAM_DIR/csgo/${url_hash}.marker" ]]; then
    return 0
  else
    return 1
  fi
}

create_install_marker() {
  echo "$1" > "$STEAM_DIR/csgo/$(get_checksum_from_string "$1").marker"
}

file_url_exists() {
  if curl --output /dev/null --silent --head --fail "$1"; then
    return 0
  fi
  return 1
}

install_plugin() {
  filename=${1##*/}
  filename_ext=$(echo "${1##*.}" | awk '{print tolower($0)}')
  if ! file_url_exists "$1"; then
    echo "Plugin download check FAILED for $filename";
    return 0
  fi
  if ! is_plugin_installed "$1"; then
    echo "Downloading $1..."
    case "$filename_ext" in
      "gz"|"tgz")
        curl -sSL "$1" | tar -zx -C "$STEAM_DIR/csgo"
        echo "Extracting $filename..."
        create_install_marker "$1"
        ;;
      "zip")
        curl -sSL -o "$filename" "$1"
        echo "Extracting $filename..."
        unzip -oq "$filename" -d "$STEAM_DIR/csgo"
        rm "$filename"
        create_install_marker "$1"
        ;;
      "smx")
        (cd "$STEAM_DIR/csgo/addons/sourcemod/plugins/" && curl -sSLO "$1")
        create_install_marker "$1"
        ;;
      *)
        echo "Plugin $filename has an unknown file extension, skipping"
        ;;
    esac
  else
    echo "Plugin $filename is already installed, skipping"
  fi
}

echo "Installing plugins..."

mkdir -p "$STEAM_DIR/csgo"
IFS=' ' read -ra PLUGIN_URLS <<< "$(echo "$INSTALL_PLUGINS" | tr "\n" " ")"
for URL in "${PLUGIN_URLS[@]}"; do
  install_plugin "$URL"
done

echo "Finished installing plugins."

# Add steam ids to sourcemod admin file
mkdir -p "$STEAM_DIR/csgo/addons/sourcemod/configs"
IFS=',' read -ra STEAMIDS <<< "$SOURCEMOD_ADMINS"
for id in "${STEAMIDS[@]}"; do
    echo "\"$id\" \"99:z\"" >> "$STEAM_DIR/csgo/addons/sourcemod/configs/admins_simple.ini"
done

PLUGINS_ENABLED_DIR="$STEAM_DIR/csgo/addons/sourcemod/plugins"
PLUGINS_DISABLED_DIR="$STEAM_DIR/csgo/addons/sourcemod/plugins/disabled"
