#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIKO_ROOT_DIR="$ROOT_DIR"
# shellcheck source=scripts/build_common.sh
source "$ROOT_DIR/scripts/build_common.sh"

usage() {
  cat <<'EOF'
Usage: ./build-gen.sh [options] [-- build_runner arguments...]

Generate code for every package in the Dart pub workspace.

Options:
  --watch, -Watch   Watch files and regenerate after changes.
  --clean, -Clean   Clean build_runner caches before generation.
  -h, --help        Show this help.

Examples:
  ./build-gen.sh
  ./build-gen.sh --watch
  ./build-gen.sh --clean -- --delete-conflicting-outputs

Windows: run this file from Git Bash.
EOF
}

watch=false
clean=false
rest_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --watch|-Watch)
      watch=true
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

require_file "$ROOT_DIR/pubspec.yaml" \
  "Root pubspec.yaml was not found at $ROOT_DIR."

printf '==> Dart: %s\n' "$(describe_dart)"

if [[ "$clean" == true ]]; then
  print_command dart run build_runner clean --workspace
  run_dart run build_runner clean --workspace
fi

action=build
[[ "$watch" == true ]] && action=watch
command_args=(run build_runner "$action" --workspace)
if (( ${#rest_args[@]} > 0 )); then
  command_args+=("${rest_args[@]}")
fi
print_command dart "${command_args[@]}"
run_dart "${command_args[@]}"

printf '==> Code generation completed.\n'
