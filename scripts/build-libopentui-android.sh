#!/bin/bash
# Build libopentui.so for @opentui/core on Android aarch64.
# Adapted from the opencode-termux build (same Zig+NDK approach).
set -euo pipefail

OPENTUI_VERSION="${OPENTUI_VERSION:-0.4.3}"
ZIG_VERSION="0.15.2"
NDK_VERSION="r28c"
ANDROID_API=29

WORK="${WORK:-$HOME/cline-termux-work}"
TOOLS="$WORK/tools"
ZIG="$TOOLS/zig/zig"
NDK="$TOOLS/android-ndk"
SRC="$WORK/opentui-$OPENTUI_VERSION/packages/core/src/zig"
OUT="$WORK/dist"

mkdir -p "$WORK" "$OUT"

# --- toolchain ---
if [ ! -x "$ZIG" ]; then
  echo "Downloading Zig $ZIG_VERSION..."
  curl -sL -o "$WORK/zig.tar.xz" "https://ziglang.org/download/$ZIG_VERSION/zig-x86_64-linux-$ZIG_VERSION.tar.xz"
  mkdir -p "$TOOLS/zig" && tar xf "$WORK/zig.tar.xz" -C "$TOOLS/zig" --strip-components=1
fi
if [ ! -d "$NDK" ]; then
  echo "Downloading Android NDK $NDK_VERSION..."
  curl -sL -o "$WORK/ndk.zip" "https://dl.google.com/android/repository/android-ndk-$NDK_VERSION-linux.zip"
  mkdir -p "$TOOLS" && unzip -q "$WORK/ndk.zip" -d "$TOOLS" && mv "$TOOLS/android-ndk-$NDK_VERSION" "$NDK"
fi

# --- opentui source ---
if [ ! -d "$WORK/opentui-$OPENTUI_VERSION" ]; then
  echo "Cloning OpenTUI v$OPENTUI_VERSION..."
  git clone --depth 1 --branch "v$OPENTUI_VERSION" https://github.com/sst/opentui.git "$WORK/opentui-$OPENTUI_VERSION"
fi

# --- android patch: skip libdl/libpthread on bionic ---
python3 - "$SRC/build.zig" <<'EOF'
import sys
p = sys.argv[1]
t = open(p).read()
old = '''        .linux => {
            artifact.linkSystemLibrary("dl");
            artifact.linkSystemLibrary("pthread");
        },'''
new = '''        .linux => {
            if (!target.result.abi.isAndroid()) {
                artifact.linkSystemLibrary("dl");
                artifact.linkSystemLibrary("pthread");
            }
        },'''
if old in t:
    open(p, "w").write(t.replace(old, new))
    print("libdl patch applied")
else:
    print("libdl pattern not found (may already be patched)")
EOF

# --- bionic sysroot ---
NDK_SYSROOT="$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
BIONIC_INC="$WORK/bionic-include"
rm -rf "$BIONIC_INC"
mkdir -p "$BIONIC_INC" "$BIONIC_INC/__opentui"
cp -a "$NDK_SYSROOT/usr/include/." "$BIONIC_INC/"
cp -a "$NDK_SYSROOT/usr/include/aarch64-linux-android/." "$BIONIC_INC/"
cp -a "$SRC/vendor/miniaudio/miniaudio.h" "$BIONIC_INC/miniaudio.h"
cat > "$BIONIC_INC/__opentui/miniaudio_shimmed.h" <<'EOF'
#define _Nullable
#define _Nonnull
#include "../miniaudio.h"
EOF
cat > "$WORK/bionic-libc.txt" <<EOF
include_dir=$BIONIC_INC
sys_include_dir=$BIONIC_INC
crt_dir=$NDK_SYSROOT/usr/lib/aarch64-linux-android/$ANDROID_API
msvc_lib_dir=
kernel32_lib_dir=
gcc_dir=
EOF

# --- build ---
export ZIG_LIBC="$WORK/bionic-libc.txt"
cd "$SRC"
"$ZIG" build "build-aarch64-linux-android" -Dtarget=aarch64-linux-android -Doptimize=ReleaseSafe

LIB="$(find . -path "*lib/aarch64-linux-android/libopentui.so" | head -1)"
if [ -z "$LIB" ]; then
  echo "BUILD FAILED: libopentui.so not found" >&2
  exit 1
fi
cp "$LIB" "$OUT/libopentui.so"
cp "$NDK_SYSROOT/usr/lib/aarch64-linux-android/libc++_shared.so" "$OUT/libc++_shared.so"
file "$OUT/libopentui.so"
echo "OK: $OUT/libopentui.so"
