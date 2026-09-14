# Contributing to DisplayBoost

Thanks for taking the time to look at this project. It is in an unusual state right now — a
fully documented feasibility study with no implementation — and that makes certain kinds of
contribution *more* valuable than code.

## Where the project actually is

DisplayBoost is in the **research phase**. There is no build system, no source tree and no
release. The repository contains documentation, and the documentation is the deliverable.

Practical consequence: the most useful thing you can do today is **attack the research**, not
write code against it.

## What we want most, in priority order

1. **Corrections.** Wrong API names, outdated version matrices, a licence we misread, a
   limitation we described incorrectly. Open an issue with a source and we will fix it.
2. **Missing prior art.** If something already does what DisplayBoost proposes, we need to
   know. A project we failed to find is a project we will duplicate badly.
3. **Contradicting evidence.** Our core claim is that this is a *quality and coverage* feature
   rather than a general performance win. If you have benchmarks showing otherwise — in either
   direction — that is extremely valuable. Measurements beat arguments.
4. **Risk additions.** If you have shipped, used or debugged an IddCx virtual display, a
   capture-and-present overlay, or a driver-signed Windows product, your failure modes belong
   in `docs/05-risks-and-limitations.md`.
5. **Translations and clarity.** The Turkish docs are a first-pass translation. Native-speaker
   corrections to terminology are welcome.

Code contributions become relevant when V1 starts. See [ROADMAP.md](ROADMAP.md).

## Documentation rules

The documentation is **bilingual**. English under `docs/` is canonical; Turkish under
`docs/tr/` mirrors it one-to-one.

- An English document and its Turkish counterpart **must be updated in the same pull request**.
  A PR that leaves the two out of sync will be asked to fix that before merging.
- New documents must be added to **both** indexes: [`docs/README.md`](docs/README.md) and
  [`docs/tr/README.md`](docs/tr/README.md).
- Keep technical identifiers in English in both languages — `IddCx`, `Desktop Duplication`,
  `swapchain`, `flip model`, `fill-rate`, algorithm names, API names. Translating these makes
  the text harder to search and harder to verify.
- **Cite sources.** Any factual claim about an API, a version number, a licence or a
  performance figure needs a link in [docs/07-references.md](docs/07-references.md). If you
  cannot source it, label it as an estimate in the text.
- Diagrams use [Mermaid](https://mermaid.js.org/) inside fenced code blocks so GitHub renders
  them without binary assets.

## Issue guidelines

Before opening an issue, search the existing ones. When you open one:

- **Bug reports** use the issue template and ask for your Windows build, GPU and driver
  version, monitor's native mode, and the render resolution and scaler in use. Empty templates
  will be closed.
- **Corrections** should include the document, the specific line or claim, what is wrong, and a
  link to a primary source.
- Keep one concern per issue.

## Pull request process

1. Fork the repository and branch from `main`.
2. Use a descriptive branch name: `docs/fix-iddcx-version-table`, `fix/typo-risk-register`.
3. Make your change. If it touches `docs/`, update `docs/tr/` too.
4. Open the pull request against `main` and fill in the template.

### Commit messages

This project follows [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>(<optional scope>): <description>
```

Common types here:

| Type | Use for |
|---|---|
| `docs` | Documentation, including all of `docs/`, `README.md`, `README_TR.md` |
| `feat` | A new feature, once implementation begins |
| `fix` | A bug fix |
| `build` | CMake, WDK, CI build configuration |
| `chore` | Maintenance that is neither docs nor code |
| `refactor` | Behaviour-preserving code change |

Examples:

```text
docs(upscaling): correct NIS licence attribution
docs(tr): translate revised risk register
build(cmake): add D3D11 capture target
```

Write the description in the imperative mood and keep the subject under 72 characters.

### Review expectations

A documentation PR is reviewed for three things: **is the claim sourced**, **do the two
language versions agree**, and **does it respect the project's stated scope**. Disagreements
are settled with sources, not seniority.

## Code style (for when V1 lands)

The intended stack is **C++20, CMake and Direct3D 11**. Formatting is pinned by the
[`.editorconfig`](.editorconfig) in the repository root: 4-space indentation for C++ and CMake,
2-space for JSON/YAML, LF line endings, UTF-8, and a 120-column limit for C++. A `.clang-format`
file will be added alongside the first source files.

## Security

Do not report security issues through public issues or pull requests. See
[SECURITY.md](SECURITY.md).

## Code of conduct

Participation in this project is covered by the [Code of Conduct](CODE_OF_CONDUCT.md). Be
straightforward, be technical, and cite your sources.
