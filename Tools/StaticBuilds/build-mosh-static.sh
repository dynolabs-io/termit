#!/usr/bin/env bash
# Build statically linked mosh-server binaries via docker buildx (Alpine/musl).
#
#   linux-x86_64    docker buildx --platform linux/amd64
#   linux-aarch64   docker buildx --platform linux/arm64
#   darwin-x86_64   only builds on macOS runners
#   darwin-aarch64  only builds on macOS runners
#
# Output: Resources/MoshServer/mosh-server-<os>-<arch>

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/Resources/MoshServer"
SRC="$ROOT/ThirdParty/mosh"
WORK="$ROOT/Tools/StaticBuilds/work"
DOCKERFILE="$ROOT/Tools/StaticBuilds/Dockerfile.alpine-mosh"

mkdir -p "$OUT" "$WORK"

if [ ! -e "$SRC/autogen.sh" ]; then
  echo "Mosh submodule content not present at $SRC — running git submodule update --init --recursive"
  (cd "$ROOT" && git submodule update --init --recursive ThirdParty/mosh)
fi

if [ ! -e "$SRC/autogen.sh" ]; then
  echo "Mosh submodule still not present after init at $SRC" >&2
  ls -la "$SRC" >&2 || true
  exit 1
fi

build_linux_via_docker() {
  local platform="$1"
  local arch_out="$2"

  if ! command -v docker >/dev/null 2>&1; then
    echo "docker not present — skipping $arch_out"
    return
  fi

  # Ensure buildx is available
  docker buildx version >/dev/null 2>&1 || {
    echo "docker buildx not available — skipping $arch_out"
    return
  }

  # buildx must use a builder that supports --platform
  if ! docker buildx ls 2>/dev/null | grep -q termit-multiarch; then
    docker buildx create --name termit-multiarch --use >/dev/null
    docker buildx inspect --bootstrap >/dev/null
  else
    docker buildx use termit-multiarch >/dev/null
  fi

  # Stage mosh source as a sibling of the Dockerfile so the context is small
  local ctx="$WORK/ctx-$arch_out"
  rm -rf "$ctx"
  mkdir -p "$ctx"
  cp "$DOCKERFILE" "$ctx/Dockerfile"
  cp -R "$SRC" "$ctx/mosh"
  # The mosh git directory is huge and unused for compilation
  rm -rf "$ctx/mosh/.git" "$ctx/mosh/.github"

  docker buildx build \
    --platform "$platform" \
    --output "type=local,dest=$WORK/out-$arch_out" \
    "$ctx"

  cp "$WORK/out-$arch_out/mosh-server" "$OUT/mosh-server-$arch_out"
  chmod +x "$OUT/mosh-server-$arch_out"
  echo "Built $OUT/mosh-server-$arch_out ($(du -h "$OUT/mosh-server-$arch_out" | cut -f1))"
}

build_darwin_native() {
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

build_linux_via_docker linux/amd64 linux-x86_64
build_linux_via_docker linux/arm64 linux-aarch64

if [ "$(uname -s)" = "Darwin" ]; then
  build_darwin_native x86_64 || true
  build_darwin_native arm64 || true
fi

echo "All available static mosh-server binaries:"
ls -lh "$OUT" || true
