#!/usr/bin/env bash
# Build statically linked mosh-server binaries for the four arches Termit bundles.
#
#   linux-x86_64    musl static via zig cc
#   linux-aarch64   musl static via zig cc
#   darwin-x86_64   normally builds only on macOS (CI matrix runs this on a macOS runner)
#   darwin-aarch64  same
#
# Output: Resources/MoshServer/mosh-server-<os>-<arch>
#
# This script is invoked by .github/workflows/ios-testflight.yaml.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/Resources/MoshServer"
SRC="$ROOT/ThirdParty/mosh"
WORK="$ROOT/Tools/StaticBuilds/work"

mkdir -p "$OUT" "$WORK"

if [ ! -d "$SRC/.git" ]; then
  echo "Mosh submodule not present at $SRC — initialise with: git submodule update --init --recursive"
  exit 1
fi

build_linux() {
  local arch="$1"
  local zigtarget
  case "$arch" in
    x86_64) zigtarget="x86_64-linux-musl" ;;
    aarch64) zigtarget="aarch64-linux-musl" ;;
    *) echo "unknown arch $arch" >&2; exit 1 ;;
  esac

  local workdir="$WORK/linux-$arch"
  rm -rf "$workdir"
  cp -R "$SRC" "$workdir"

  pushd "$workdir" > /dev/null
  ./autogen.sh
  CC="zig cc -target $zigtarget" \
  CXX="zig c++ -target $zigtarget" \
  LDFLAGS="-static" \
    ./configure \
      --disable-shared \
      --without-utempter \
      --disable-completion \
      --disable-dependency-tracking \
      --host="$arch-linux-musl"
  make -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)" -C src/network
  make -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)" -C src/statesync
  make -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)" -C src/terminal
  make -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)" -C src/frontend mosh-server
  cp src/frontend/mosh-server "$OUT/mosh-server-linux-$arch"
  strip "$OUT/mosh-server-linux-$arch" || true
  popd > /dev/null

  echo "Built $OUT/mosh-server-linux-$arch ($(du -h "$OUT/mosh-server-linux-$arch" | cut -f1))"
}

build_darwin() {
  if [ "$(uname -s)" != "Darwin" ]; then
    echo "Darwin build requires a macOS host; skipping."
    return
  fi
  local arch="$1"
  local workdir="$WORK/darwin-$arch"
  rm -rf "$workdir"
  cp -R "$SRC" "$workdir"
  pushd "$workdir" > /dev/null
  ./autogen.sh
  CFLAGS="-arch $arch -mmacosx-version-min=11.0" \
  CXXFLAGS="-arch $arch -mmacosx-version-min=11.0" \
  LDFLAGS="-arch $arch -mmacosx-version-min=11.0" \
    ./configure --disable-shared --disable-dependency-tracking
  make -j"$(sysctl -n hw.ncpu)" -C src/frontend mosh-server
  cp src/frontend/mosh-server "$OUT/mosh-server-darwin-$arch"
  popd > /dev/null
}

build_linux x86_64
build_linux aarch64
build_darwin x86_64 || true
build_darwin aarch64 || true

echo "All available static mosh-server binaries:"
ls -lh "$OUT"
