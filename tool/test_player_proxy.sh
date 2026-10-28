#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
test_directory="$(mktemp -d "${TMPDIR:-/tmp}/kikoenai-player-proxy.XXXXXX")"
trap 'rm -f "$test_directory/fixtures.json"; rmdir "$test_directory"' EXIT

# Public localhost-only test fixtures; never use this key outside tests.
python3 - "$project_root" "$test_directory/fixtures.json" <<'PY'
import base64
import json
import pathlib
import sys

fixtures = pathlib.Path(sys.argv[1]) / 'test/fixtures/proxy'
pathlib.Path(sys.argv[2]).write_text(json.dumps({
    'PLAYER_PROXY_TEST_CERT_B64': base64.b64encode((fixtures / 'cert.pem').read_bytes()).decode(),
    'PLAYER_PROXY_TEST_KEY_B64': base64.b64encode((fixtures / 'key.pem').read_bytes()).decode(),
}))
PY

cd "$project_root"
if [[ -n "${FLUTTER_BIN:-}" ]]; then
  flutter_command=("$FLUTTER_BIN")
elif [[ -x "$project_root/.fvm/flutter_sdk/bin/flutter" ]]; then
  flutter_command=("$project_root/.fvm/flutter_sdk/bin/flutter")
else
  flutter_command=(flutter)
fi
"${flutter_command[@]}" test --no-pub \
  --dart-define-from-file="$test_directory/fixtures.json" \
  integration_test/player_proxy_test.dart "$@"
