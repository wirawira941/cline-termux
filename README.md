# cline-termux

Run **Cline CLI** natively on **Termux** (Android aarch64).

Cline CLI (`npm install -g cline`) is a Node.js app that uses
[`@opentui/core`](https://github.com/sst/opentui) for its terminal UI.
OpenTUI ships no Android native library, so the CLI fails on Termux.
This repo builds `libopentui.so` for Android and wraps `cline` with a
Node.js preload that forces OpenTUI to use it.

## Quick install

```sh
# 1. Install Cline CLI itself
npm install -g cline

# 2. Download the latest cline-termux zip from Releases
mkdir ~/cline-termux && cd ~/cline-termux
unzip ~/cline-termux-android-aarch64.zip
bash install.sh

# 3. Run
cline-termux --version
```

Use `cline-termux` (not `cline`) to avoid clashing with any existing install.

## How it works

- `termux/cline` — launcher script. Runs your global `cline` via Node.js with
  `--import` preload and `NODE_PATH` pointing at the global npm root.
- `termux/cline-preload.mjs` — calls `setRenderLibPath()` from
  `@opentui/core` to override the native library path with our
  Android-built `libopentui.so`.
- `termux/install.sh` — installs the `.so` files, preload, and launcher.

## Building from source

The GitHub Actions workflow (`.github/workflows/build.yml`) does this
automatically on every push. To build manually, see `scripts/`.

Requirements: Zig 0.15.2, Android NDK r28c.

```sh
bash scripts/build-libopentui-android.sh
```

This produces `libopentui.so` + `libc++_shared.so` for
`aarch64-linux-android` (API 29).

## Updating

When Cline bumps `@opentui/core`, rebuild the `.so` from the matching
OpenTUI tag:

```sh
# in the workflow dispatch inputs, set opentui_version, e.g. 0.4.3
```

## License

Wrapper scripts: MIT. `libopentui.so` is built from OpenTUI (MIT).
Cline itself is Apache-2.0 by Cline Bot Inc.
