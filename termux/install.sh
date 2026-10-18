#!/bin/sh
# Installer for cline-termux (Cline CLI on Termux with Android-native libopentui)
set -e

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
LIBEXEC="$PREFIX/libexec/cline-termux"
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "Installing cline-termux to $LIBEXEC..."
mkdir -p "$LIBEXEC"
cp "$HERE/libopentui.so" "$HERE/libc++_shared.so" "$HERE/cline-preload.mjs" "$LIBEXEC/"
cp "$HERE/cline" "$PREFIX/bin/cline-termux"
chmod 755 "$PREFIX/bin/cline-termux" "$LIBEXEC/libopentui.so"

echo ""
echo "Done! Now install Cline CLI itself (if not already installed):"
echo "  npm install -g cline"
echo ""
echo "Then run:"
echo "  cline-termux --version"
echo ""
echo "Note: 'cline-termux' is used instead of 'cline' to avoid clashing with"
echo "any existing cline installation. The wrapper finds your global cline"
echo "and preloads the Android-native OpenTUI library."
