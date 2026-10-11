# Swarm Node Flasher

A web page that flashes Swarm node firmware (node build 14, broadcast link on) onto an ESP32-C5
straight from Chrome or Edge, with no Arduino IDE. It works like the JCMK C5 Wardriver installer and
uses ESP Web Tools (bundled in `vendor/`, so it needs no CDN).

Boards: Seeed Xiao ESP32-C5, and ESP32-C5-DevKitC-1 (the JCMK C5 Wardriver).

## Use it right now on your computer

Web Serial only runs on `https://` or `localhost`, so opening `index.html` by double-click won't work.
From inside this folder:

```
python3 -m http.server 8000
```

then open <http://localhost:8000> in Chrome or Edge. (On Windows, `py -m http.server 8000`.)

## Put it online (GitHub Pages, free)

1. On github.com, create a new **public** repository, for example `swarm-flasher`.
2. Click **Add file → Upload files** and drag in everything *inside* this folder (index.html, the
   manifests, swarm_logo.png, and the `firmware` and `vendor` folders). Commit.
3. Open **Settings → Pages**. Under **Build and deployment**, pick **Deploy from a branch**, branch
   **main**, folder **/ (root)**, and Save.
4. After a minute the page is live at `https://<your-username>.github.io/swarm-flasher/`.

To ship a new node build, replace the files in `firmware/` and bump the version in the two
`manifest-*.json` files and in `index.html`.

## What gets written

| Offset  | File            |
|---------|-----------------|
| 0x2000  | bootloader.bin  |
| 0x8000  | partitions.bin  |
| 0xE000  | boot_app0.bin   |
| 0x10000 | swarm_node.bin  |

These are separate parts, not a merged full-flash image, so flashing without **Erase device** keeps the
node's number, scan plan (NVS) and stored sightings (LittleFS). The Xiao uses its default 8 MB layout,
the same as the Arduino IDE. The DevKit build uses the "No OTA (2MB APP/2MB SPIFFS)" layout, because the
sketch (1.47 MB) doesn't fit the 4 MB default's 1.2 MB app slot.

## Rebuilding

`build-firmware.sh` recompiles both boards with arduino-cli. It needs ESP32 core 3.3.12, NimBLE-Arduino
2.5.1 and the `nimconfig.h` edit described in the main Swarm README.
