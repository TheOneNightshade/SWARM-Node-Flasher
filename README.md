# Swarm Node Flasher

Flash Swarm wardriving node firmware onto an ESP32-C5 from your browser. You don't need the Arduino
IDE, libraries or any config edits.

**▶ Open the flasher: https://YOUR-USERNAME.github.io/swarm-flasher/**

Current firmware: **Swarm node build 14**, with the broadcast link on.

## What is Swarm?

Swarm is a wardriving cluster. Several ESP32-C5 nodes each scan Wi-Fi (2.4 and 5 GHz) and BLE, then
send what they find to an Android phone over Bluetooth. The phone adds GPS and logs everything as WiGLE
CSV. Each node talks to the phone directly, so there's no chain and no node cap. Every node runs the
same firmware, and the phone gives each one its number and scan plan.

## Supported boards

| Board | Notes |
|-------|-------|
| Seeed Studio XIAO ESP32-C5 | Main Swarm node.  |
| Espressif ESP32-C5 | For example the JCMK C5 Wardriver. Works with 4 MB and 8 MB flash. |

## How to flash

You need **Chrome or Edge on a computer** (Windows, macOS, Linux or ChromeOS). Phones and Firefox/Safari
can't do Web Serial.

1. Plug the board in with a USB-C **data** cable.
2. Open the flasher, pick your board and click **Connect & install**.
3. Pick the board's port in the popup. It's usually "USB JTAG/serial debug unit", a COM port, or
   `cu.usbmodem…`.
4. Click **Install**. On the **Erase device** screen:
   - **Unticked** (normal update): keeps the node's number, scan plan and stored sightings.
   - **Ticked**: wipes the board clean. Use it for the first flash on a board that ran other firmware,
     or if it boot-loops after flashing.
5. When it finishes, open **Logs & Console** and press the board's reset button. You should see:
   ```
   link: broadcast + direct
   swarm node build 14
   swarm node ready: ..., node 0, ...
   ```

Then open the Swarm app on the phone. It finds the node and sets it up.

## Troubleshooting

- **No port in the list:** try another cable (lots of them are charge-only) or another USB port.
- **Connects but fails to flash:** put the board in download mode. Hold **BOOT**, tap **RESET** (or plug
  it in while holding BOOT), let go and try again. Press RESET once after flashing.
- **"Port is busy":** close the Arduino Serial Monitor or any other program using the board.
- **Boot-loops after flashing:** flash again with **Erase device** ticked.

## What gets written

| Offset  | File                 |
|---------|----------------------|
| 0x2000  | `<board>-bootloader.bin` |
| 0x8000  | `<board>-partitions.bin` |
| 0xE000  | `<board>-boot_app0.bin`  |
| 0x10000 | `<board>-swarm_node.bin` |

`<board>` is `xiao-c5` or `c5-devkit`.

These are separate images, not a merged full-flash image, so an update leaves the settings (NVS) and the
offline sighting queue (LittleFS) alone.

- **XIAO ESP32-C5:** the board's default 8 MB layout (3 MB app, 1.5 MB storage). It's the same as an
  Arduino IDE upload with default settings, so you can switch between the two without losing data.
- **ESP32-C5:** the "No OTA" layout (2 MB app, 2 MB storage). The firmware (about 1.47 MB)
  doesn't fit the 4 MB default's 1.2 MB app slot.

Flashing by hand with esptool, using the same files:

```
esptool --chip esp32c5 write-flash 0x2000 xiao-c5-bootloader.bin 0x8000 xiao-c5-partitions.bin 0xe000 xiao-c5-boot_app0.bin 0x10000 xiao-c5-swarm_node.bin
```

## Repo layout

Everything sits at the top level with no subfolders, so a plain GitHub "Upload files" works.

```
index.html                  the flasher page
manifest-xiao-c5.json       ESP Web Tools manifest, XIAO ESP32-C5
manifest-c5-devkit.json     ESP Web Tools manifest, ESP32-C5-DevKitC-1
xiao-c5-*.bin               the four images for the XIAO
c5-devkit-*.bin             the four images for the DevKit
*.js                        ESP Web Tools 10.4.0 (bundled, no CDN needed; LICENSE-esp-web-tools)
build-firmware.sh           rebuilds the .bin files from the node sketch
swarm_logo.png
```

## Hosting your own copy

The page is plain static files. Web Serial needs `https://` or `localhost`, so double-clicking
`index.html` won't work.

- **GitHub Pages:** go to Settings → Pages → Deploy from a branch → `main`, `/ (root)` → Save. The page
  goes live at `https://<user>.github.io/<repo>/`.
- **On your own computer:** run `python3 -m http.server 8000` in the repo folder, then open
  http://localhost:8000.

## Building the firmware

The images come from the `wd_swarm_node` Arduino sketch. To build them you need:

- ESP32 Arduino core **3.3.12**
- NimBLE-Arduino **2.5.1**, with these lines turned on in its `src/nimconfig.h` (they enable the broadcast link):
  ```
  #define CONFIG_BT_NIMBLE_EXT_ADV 1
  #define CONFIG_BT_NIMBLE_MAX_EXT_ADV_INSTANCES 1
  #define CONFIG_BT_NIMBLE_MAX_EXT_ADV_DATA_LEN 251
  ```

`build-firmware.sh` compiles both boards with `arduino-cli` and copies the results into the `<board>-*.bin` files. Set
`SKETCH=/path/to/wd_swarm_node` if the sketch isn't at `../wardrive-chain/firmware/wd_swarm_node`. It
warns you if the build came out without the broadcast link.

To release a new build, run the script, then bump `"version"` in both manifests and the build number in
`index.html`.

## Credits

- Flashing by [ESP Web Tools](https://github.com/esphome/esp-web-tools) (Apache-2.0, license in
  `LICENSE-esp-web-tools`).
- Idea taken from the
  [JCMK C5 Wardriver installer](https://justcallmekoko.github.io/C5WardriverInstaller/).
