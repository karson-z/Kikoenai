#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIKO_ROOT_DIR="$ROOT_DIR"
# shellcheck source=scripts/build_common.sh
source "$ROOT_DIR/scripts/build_common.sh"

usage() {
  cat <<'EOF'
Usage: ./build-apk.sh [options] [-- flutter build apk arguments...]

Options:
  --debug, -BuildDebug          Build in debug mode.
  --build-mode, -BuildMode M   Set release, debug, or profile mode.
  --no-split, -NoSplit         Do not split the APK per ABI.
  --no-obfuscate, -NoObfuscate Disable Dart obfuscation.
  --clean, -Clean               Run flutter clean first.
  -h, --help                    Show this help.

Examples:
  ./build-apk.sh
  ./build-apk.sh --debug --no-obfuscate
  ./build-apk.sh -- --no-tree-shake-icons

Windows: run this file from Git Bash.
EOF
}

mode=release
split=true
obfuscate=true
clean=false
rest_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug|-BuildDebug)
      mode=debug
      shift
      ;;
    --build-mode|-BuildMode)
      [[ $# -ge 2 ]] || fail "$1 requires release, debug, or profile."
      mode="$2"
      shift 2
      ;;
    --no-split|-NoSplit)
      split=false
      shift
      ;;
    --no-obfuscate|-NoObfuscate)
      obfuscate=false
      shift
      ;;
    --clean|-Clean)
      clean=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      rest_args+=("$@")
      break
      ;;
    *)
      rest_args+=("$1")
      shift
      ;;
  esac
done

case "$mode" in
  release|debug|profile) ;;
  *) fail "Unsupported build mode '$mode'. Use release, debug, or profile." ;;
esac

require_file "$KIKO_APP_DIR/lib/main.dart" \
  "App entry point was not found at $KIKO_APP_DIR/lib/main.dart."

symbols_dir="$ROOT_DIR/symbols"
mkdir -p "$symbols_dir"

printf '==> Flutter: %s\n' "$(describe_flutter)"
if [[ "$clean" == true ]]; then
  print_command flutter clean
  run_flutter clean
fi

build_args=(build apk "--$mode")
[[ "$split" == true ]] && build_args+=(--split-per-abi)
if [[ "$obfuscate" == true ]]; then
  build_args+=(--obfuscate --split-debug-info "$symbols_dir")
fi
if (( ${#rest_args[@]} > 0 )); then
  build_args+=("${rest_args[@]}")
fi

print_command flutter "${build_args[@]}"
run_flutter "${build_args[@]}"
printf '==> APK build completed. Symbols: %s\n' "$symbols_dir"
