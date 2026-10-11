#!/usr/bin/env bash
# Rebuilds the flasher's firmware binaries (<board>-*.bin) from ../wardrive-chain/firmware/wd_swarm_node.
# Needs arduino-cli with esp32:esp32@3.3.12 and NimBLE-Arduino 2.5.1 installed, and NimBLE's
# src/nimconfig.h edited for broadcast mode:
#   #define CONFIG_BT_NIMBLE_EXT_ADV 1
#   #define CONFIG_BT_NIMBLE_MAX_EXT_ADV_INSTANCES 1
#   #define CONFIG_BT_NIMBLE_MAX_EXT_ADV_DATA_LEN 251
# After building, update "version" in both manifest-*.json files and the build number in index.html.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SKETCH="${SKETCH:-$HERE/../wardrive-chain/firmware/wd_swarm_node}"
CLI="${ARDUINO_CLI:-arduino-cli}"
OUT="$(mktemp -d)"
CORE="$("$CLI" config get directories.data)/packages/esp32/hardware/esp32/3.3.12"

build() {  # fqbn  folder
  "$CLI" compile -b "$1" --output-dir "$OUT/$2" "$SKETCH"
  # Flat file names (no subfolders) so a plain GitHub "Upload files" keeps everything working.
  cp "$OUT/$2/wd_swarm_node.ino.bootloader.bin" "$HERE/$2-bootloader.bin"   # 0x2000
  cp "$OUT/$2/wd_swarm_node.ino.partitions.bin" "$HERE/$2-partitions.bin"   # 0x8000
  cp "$CORE/tools/partitions/boot_app0.bin"     "$HERE/$2-boot_app0.bin"    # 0xe000
  cp "$OUT/$2/wd_swarm_node.ino.bin"            "$HERE/$2-swarm_node.bin"   # 0x10000
}

# Xiao: the board's default 8 MB layout (3 MB app, 1.5 MB LittleFS), same as the Arduino IDE default.
build esp32:esp32:XIAO_ESP32C5 xiao-c5
# DevKitC-1: the 4 MB default app slot (1.2 MB) is too small for the sketch, so use No OTA
# (2 MB app, 2 MB LittleFS). Works on 4 MB and 8 MB modules.
build esp32:esp32:esp32c5:PartitionScheme=no_ota c5-devkit

grep -q "broadcast + direct" "$HERE/xiao-c5-swarm_node.bin" \
  && echo "broadcast mode: on" || echo "WARNING: broadcast mode is OFF (nimconfig.h edit missing)"
rm -rf "$OUT"
