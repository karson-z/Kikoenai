# Project scripts

Run all commands from the repository root through the single entry point:

```bash
./scripts/kiko help
```

For a fresh checkout, run `./scripts/kiko get` followed by
`./scripts/kiko generate` before analysis or tests. Generated Dart files are
intentionally excluded from Git.

| Task | Command |
| --- | --- |
| Get workspace dependencies | `./scripts/kiko get` |
| Generate all code | `./scripts/kiko generate` |
| Generate only core code | `./scripts/kiko generate kikoenai_core` |
| Watch core code generation | `./scripts/kiko watch` |
| Analyze all packages | `./scripts/kiko analyze` |
| Test all packages | `./scripts/kiko test` |
| Check formatting, analyze, and test | `./scripts/kiko verify` |
| Run the iOS app | `./scripts/kiko run` |
| Build the iOS app | `./scripts/kiko ios-build` |
| Push the current branch | `./scripts/kiko push` |
| Show and validate the current version | `./scripts/kiko version` |
| Manually run Android APK Actions | `./scripts/kiko workflow` |
| View recent Android APK Actions runs | `./scripts/kiko workflow-status` |
| Increment patch and publish | `./scripts/kiko release` |
| Increment minor and publish | `./scripts/kiko release minor` |
| Increment major and publish | `./scripts/kiko release major` |

`generate`, `analyze`, and `test` accept `kikoenai_core`, `kikoenai_sites`,
`kikoenai_app`, or `all` as an optional package argument.

Code generation runs `fvm dart run build_runner` from the selected package, so
it uses that package's dev dependencies without needing to manually `cd`.

## Version and release behavior

The application version is synchronized between `kikoenai_app/pubspec.yaml`
and `VersionConfig.version`. The Flutter build number after `+` always remains
`1`:

| Command from `1.1.0+1` | Next Flutter version | `VersionConfig.version` |
| --- | --- | --- |
| `./scripts/kiko release` | `1.1.1+1` | `1.1.1` |
| `./scripts/kiko release minor` | `1.2.0+1` | `1.2.0` |
| `./scripts/kiko release major` | `2.0.0+1` | `2.0.0` |

The GitHub Actions workflow in `.github/workflows/android-apk.yml` runs on a
`v*` tag. `release` checks that the working tree is clean and the next tag is
available, synchronizes both version declarations, creates a release commit and
annotated tag, then pushes the branch and tag atomically. This triggers the
Android APK build and GitHub Release creation.

`workflow` uses GitHub CLI (`gh`) to run the same workflow manually on the
current branch. It builds an artifact but does not create a GitHub Release,
because the workflow only creates releases for tags.
