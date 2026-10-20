#!/bin/bash
# Shared architecture selection for macOS build, package and verification scripts.
# Source this file; MACOS_ARCH may override the host's native architecture.

macos_architecture() {
  local architecture="${MACOS_ARCH:-$(uname -m)}"
  case "$architecture" in
    x86_64|arm64)
      printf '%s\n' "$architecture"
      ;;
    *)
      printf 'Unsupported macOS architecture: %s (expected x86_64 or arm64).\n' "$architecture" >&2
      return 1
      ;;
  esac
}
