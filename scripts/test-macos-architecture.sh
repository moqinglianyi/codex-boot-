#!/bin/bash
# No compiler or macOS SDK required: check architecture defaults and overrides.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source "$repo_root/scripts/macos-common.sh"

check_architecture() (
  MACOS_ARCH="$1"
  host_architecture="$2"
  expected="$3"
  uname() { printf '%s\n' "$host_architecture"; }
  actual="$(macos_architecture)"
  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL: requested=%s host=%s expected=%s actual=%s\n' \
      "$MACOS_ARCH" "$host_architecture" "$expected" "$actual" >&2
    exit 1
  fi
)

reject_architecture() (
  MACOS_ARCH="$1"
  host_architecture="$2"
  uname() { printf '%s\n' "$host_architecture"; }
  if macos_architecture >/dev/null 2>&1; then
    printf 'FAIL: accepted unsupported architecture %s on %s\n' "$MACOS_ARCH" "$host_architecture" >&2
    exit 1
  fi
)

check_architecture '' x86_64 x86_64
check_architecture '' arm64 arm64
check_architecture x86_64 arm64 x86_64
check_architecture arm64 x86_64 arm64
check_architecture x86_64 unknown x86_64
check_architecture arm64 unknown arm64
reject_architecture i386 x86_64
reject_architecture aarch64 arm64
reject_architecture invalid x86_64
reject_architecture '' unknown

printf 'PASS: macOS architecture defaults, cross-compilation overrides and unsupported targets.\n'
