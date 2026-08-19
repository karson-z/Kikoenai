# Upstream and local changes

- Upstream: https://github.com/ozyl/flutter_lyric.git
- Imported commit: `5b4f2b65e05549d289881c86a077357764c8c71b`
- Upstream version: `3.0.7`
- License: MIT, retained in `LICENSE`

This workspace copy adds an Apple Music inspired presentation while keeping the
upstream controller, parser, selection, translation, and public widget APIs
available. Local additions include spring scroll behavior, depth-of-field blur,
progress glow, and an `appleMusic` style preset.

The visual treatment follows publicly observable Apple Music behavior and
community implementation research. Apple does not publish the private source or
exact animation constants used by the Music app, so the constants here are a
carefully tuned approximation rather than copied proprietary implementation.
