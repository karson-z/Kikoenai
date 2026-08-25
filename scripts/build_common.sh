#!/usr/bin/env bash

# Shared helpers for the root build scripts. This file is sourced, not run.

set -Eeuo pipefail

KIKO_ROOT_DIR="${KIKO_ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
KIKO_APP_DIR="$KIKO_ROOT_DIR"

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "$2"
}

print_command() {
  printf '==>'
  printf ' %q' "$@"
  printf '\n'
}

describe_dart() {
  if is_windows_shell && [[ -f "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/dart.bat" ]]; then
    printf '%s\n' "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/dart.bat"
  elif [[ -x "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/dart" ]]; then
    printf '%s\n' "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/dart"
  elif [[ -f "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/dart.bat" ]]; then
    printf '%s\n' "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/dart.bat"
  elif command -v fvm >/dev/null 2>&1; then
    printf '%s\n' 'fvm dart'
  elif command -v dart >/dev/null 2>&1; then
    command -v dart
  else
    printf '%s\n' 'not found'
  fi
}

run_dart() {
  if is_windows_shell && [[ -f "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/dart.bat" ]]; then
    (cd "$KIKO_ROOT_DIR" && "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/dart.bat" "$@")
  elif [[ -x "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/dart" ]]; then
    (cd "$KIKO_ROOT_DIR" && "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/dart" "$@")
  elif [[ -f "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/dart.bat" ]]; then
    (cd "$KIKO_ROOT_DIR" && "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/dart.bat" "$@")
  elif command -v fvm >/dev/null 2>&1; then
    (cd "$KIKO_ROOT_DIR" && fvm dart "$@")
  elif command -v dart >/dev/null 2>&1; then
    (cd "$KIKO_ROOT_DIR" && dart "$@")
  else
    fail 'Dart was not found. Install FVM/Flutter or add dart to PATH.'
  fi
}

describe_flutter() {
  if is_windows_shell && [[ -f "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/flutter.bat" ]]; then
    printf '%s\n' "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/flutter.bat"
  elif [[ -x "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/flutter" ]]; then
    printf '%s\n' "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/flutter"
  elif [[ -f "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/flutter.bat" ]]; then
    printf '%s\n' "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/flutter.bat"
  elif command -v fvm >/dev/null 2>&1; then
    printf '%s\n' 'fvm flutter'
  elif command -v flutter >/dev/null 2>&1; then
    command -v flutter
  else
    printf '%s\n' 'not found'
  fi
}

run_flutter() {
  if is_windows_shell && [[ -f "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/flutter.bat" ]]; then
    (cd "$KIKO_APP_DIR" && "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/flutter.bat" "$@")
  elif [[ -x "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/flutter" ]]; then
    (cd "$KIKO_APP_DIR" && "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/flutter" "$@")
  elif [[ -f "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/flutter.bat" ]]; then
    (cd "$KIKO_APP_DIR" && "$KIKO_ROOT_DIR/.fvm/flutter_sdk/bin/flutter.bat" "$@")
  elif command -v fvm >/dev/null 2>&1; then
    (cd "$KIKO_APP_DIR" && fvm flutter "$@")
  elif command -v flutter >/dev/null 2>&1; then
    (cd "$KIKO_APP_DIR" && flutter "$@")
  else
    fail 'Flutter was not found. Install FVM/Flutter or add flutter to PATH.'
  fi
}

is_windows_shell() {
  case "$(uname -s 2>/dev/null || true)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

windows_to_posix_path() {
  command -v cygpath >/dev/null 2>&1 || fail 'cygpath is required in Git Bash.'
  cygpath -u "$1"
}

windows_to_native_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s\n' "$1"
  fi
}
