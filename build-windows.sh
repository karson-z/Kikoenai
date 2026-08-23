#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIKO_ROOT_DIR="$ROOT_DIR"
# shellcheck source=scripts/build_common.sh
source "$ROOT_DIR/scripts/build_common.sh"

usage() {
  cat <<'EOF'
Usage: ./build-windows.sh [options] [-- flutter build windows arguments...]

This script must run on Windows in Git Bash, MSYS2, or Cygwin.

Options:
  --debug, -BuildDebug                Build in debug mode.
  --build-mode, -BuildMode M         Set release, debug, or profile mode.
  --no-zip, -NoZip                   Build without creating the portable ZIP.
  --clean, -Clean                     Run flutter clean first.
  --skip-runtime-dlls, -SkipRuntimeDlls
                                       Do not include VC++ runtime DLLs.
  --build-installer, -BuildInstaller  Compile the Inno Setup installer.
  --version, -Version V               Override the artifact version.
  -h, --help                          Show this help.

Examples:
  ./build-windows.sh
  ./build-windows.sh --clean --version 1.1.3
  ./build-windows.sh --no-zip -- --no-tree-shake-icons

Run this file from Git Bash on Windows.
EOF
}

mode=release
create_zip=true
clean=false
include_runtime_dlls=true
build_installer=false
version_override=''
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
    --no-zip|-NoZip)
      create_zip=false
      shift
      ;;
    --clean|-Clean)
      clean=true
      shift
      ;;
    --skip-runtime-dlls|-SkipRuntimeDlls)
      include_runtime_dlls=false
      shift
      ;;
    --build-installer|-BuildInstaller)
      build_installer=true
      shift
      ;;
    --version|-Version)
      [[ $# -ge 2 ]] || fail "$1 requires a version."
      version_override="$2"
      shift 2
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

is_windows_shell || fail \
  'Windows desktop builds require Windows. Run this script from Git Bash on Windows.'

require_file "$KIKO_APP_DIR/lib/main.dart" \
  "App entry point was not found at $KIKO_APP_DIR/lib/main.dart."
require_file "$KIKO_APP_DIR/pubspec.yaml" \
  "App pubspec was not found at $KIKO_APP_DIR/pubspec.yaml."

version_raw="$(awk '/^version:[[:space:]]*/ { print $2; exit }' "$KIKO_APP_DIR/pubspec.yaml")"
[[ -n "$version_raw" ]] || fail 'Unable to read version from kikoenai_app/pubspec.yaml.'
if [[ -n "$version_override" ]]; then
  version="${version_override#v}"
else
  version="${version_raw%%+*}"
fi

printf '==> Flutter: %s\n' "$(describe_flutter)"
if [[ "$clean" == true ]]; then
  print_command flutter clean
  run_flutter clean
fi

build_args=(build windows "--$mode")
if (( ${#rest_args[@]} > 0 )); then
  build_args+=("${rest_args[@]}")
fi
print_command flutter "${build_args[@]}"
run_flutter "${build_args[@]}"

if [[ "$create_zip" == false ]]; then
  printf '==> Packaging skipped. Output: %s\n' \
    "$KIKO_APP_DIR/build/windows/x64/runner"
  exit 0
fi

case "$mode" in
  debug) configuration=Debug ;;
  profile) configuration=Profile ;;
  release) configuration=Release ;;
esac

source_dir="$KIKO_APP_DIR/build/windows/x64/runner/$configuration"
for required in kikoenai.exe data flutter_windows.dll; do
  [[ -e "$source_dir/$required" ]] || \
    fail "Windows build output is missing: $source_dir/$required"
done

dist_dir="$ROOT_DIR/dist"
package_name="kikoenai-v${version}-windows-x64"
stage_dir="$dist_dir/$package_name"
zip_path="$dist_dir/$package_name.zip"

mkdir -p "$dist_dir"
rm -rf "$stage_dir"
mkdir -p "$stage_dir"
cp -a "$source_dir"/. "$stage_dir"/
printf '==> Copied Windows output to %s\n' "$stage_dir"

if [[ "$include_runtime_dlls" == true ]]; then
  windows_root="${WINDIR:-${SystemRoot:-C:\\Windows}}"
  system32="$(windows_to_posix_path "$windows_root")/System32"
  copied_dlls=()
  for dll in msvcp140.dll vcruntime140.dll vcruntime140_1.dll; do
    if [[ -f "$system32/$dll" ]]; then
      cp -f "$system32/$dll" "$stage_dir/"
      copied_dlls+=("$dll")
    fi
  done
  if [[ ${#copied_dlls[@]} -gt 0 ]]; then
    printf '==> Included VC++ runtime DLLs: %s\n' "${copied_dlls[*]}"
  else
    printf 'Warning: VC++ runtime DLLs were not found in %s.\n' "$system32" >&2
  fi
fi

rm -f "$zip_path"
if command -v powershell.exe >/dev/null 2>&1; then
  KIKO_STAGE_DIR="$(windows_to_native_path "$stage_dir")" \
  KIKO_ZIP_PATH="$(windows_to_native_path "$zip_path")" \
  MSYS2_ARG_CONV_EXCL='*' \
    powershell.exe -NoProfile -NonInteractive -Command \
      'Compress-Archive -LiteralPath $env:KIKO_STAGE_DIR -DestinationPath $env:KIKO_ZIP_PATH -CompressionLevel Optimal -Force'
elif command -v pwsh >/dev/null 2>&1; then
  KIKO_STAGE_DIR="$stage_dir" KIKO_ZIP_PATH="$zip_path" \
    pwsh -NoProfile -NonInteractive -Command \
      'Compress-Archive -LiteralPath $env:KIKO_STAGE_DIR -DestinationPath $env:KIKO_ZIP_PATH -CompressionLevel Optimal -Force'
elif command -v zip >/dev/null 2>&1; then
  (cd "$dist_dir" && zip -qr "$zip_path" "$package_name")
else
  fail 'Unable to create ZIP: powershell.exe, pwsh, or zip is required.'
fi

size_bytes="$(wc -c < "$zip_path" | tr -d '[:space:]')"
size_mb="$(awk -v bytes="$size_bytes" 'BEGIN { printf "%.2f", bytes / 1048576 }')"
printf '==> Portable ZIP: %s (%s MB)\n' "$zip_path" "$size_mb"

if [[ "$build_installer" == true ]]; then
  iscc=''
  candidates=(
    'F:/Inno Setup 6/ISCC.exe'
    'C:/Program Files (x86)/Inno Setup 6/ISCC.exe'
    'C:/Program Files/Inno Setup 6/ISCC.exe'
  )
  for candidate in "${candidates[@]}"; do
    candidate_posix="$(windows_to_posix_path "$candidate")"
    if [[ -f "$candidate_posix" ]]; then
      iscc="$candidate_posix"
      break
    fi
  done
  if [[ -z "$iscc" ]] && command -v iscc.exe >/dev/null 2>&1; then
    iscc="$(command -v iscc.exe)"
  fi

  if [[ -n "$iscc" ]]; then
    installer_script="$(windows_to_native_path "$ROOT_DIR/tool/kikoenai_installer.iss")"
    print_command "$iscc" "$installer_script"
    MSYS2_ARG_CONV_EXCL='*' "$iscc" "$installer_script"
    printf '==> Installer: %s/kikoenai-v%s-setup.exe\n' "$dist_dir" "$version"
  else
    printf 'Warning: Inno Setup was not found; installer compilation skipped.\n' >&2
  fi
fi
