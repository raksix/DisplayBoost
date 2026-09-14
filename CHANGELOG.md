# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) from its first release
onward.

## [Unreleased]

### Added

- Research documentation under `docs/`, covering the IddCx indirect display driver framework,
  capture and present pipelines, upscaler licensing, prior art, and a risk register.
- Turkish translations of all research documents under `docs/tr/`, mirroring `docs/` one-to-one.
- Project README in English and Turkish, describing the architecture, design goals, non-goals
  and roadmap.
- Repository scaffolding: MIT licence, contributing guide, code of conduct, security policy,
  changelog, roadmap, `.editorconfig`, `.gitattributes` and `.gitignore`.
- GitHub issue templates, a pull request template, and a documentation CI workflow that lints
  Markdown, checks links, and verifies English/Turkish document parity.

### Changed

- Positioning: the project is documented as a **coverage and quality** feature rather than a
  general performance feature, based on the findings in `docs/05-risks-and-limitations.md`.

[Unreleased]: https://github.com/raksix/DisplayBoost/commits/main
