# Security Policy

## Supported versions

DisplayBoost has not shipped a release yet. There are no supported versions and no binaries to
download. Anything claiming to be a DisplayBoost build is not ours.

The project's threat model matters *before* the first release, because the eventual shape of
this software is unusual: it combines a **Windows display driver** with a **screen-capturing
user-mode application**. Both halves sit on sensitive boundaries.

## Reporting a vulnerability

Please **do not** open a public issue or pull request for a security problem.

Use GitHub's private vulnerability reporting:

1. Go to the **Security** tab of this repository.
2. Select **Report a vulnerability**.
3. Describe the issue, the affected component, and how to reproduce it.

If private reporting is unavailable, contact the maintainer through the options listed on the
[maintainer's GitHub profile](https://github.com/raksix) and ask for a private channel before
sharing details.

We will acknowledge your report, keep you updated as we investigate, and credit you in the
advisory unless you prefer otherwise. Please give us a reasonable opportunity to ship a fix
before disclosing publicly.

## In scope

Anything that breaks a security boundary the project intends to hold:

- **Privilege boundaries.** The keyboard input stack, window station and desktop handling, or
  any path where the user-mode application could act with more privilege than intended.
- **Driver installation and update.** Unsigned or substituted driver packages, installer or
  servicer paths that could be hijacked, DLL search-order issues in the driver or the service.
- **Capture scope violations.** Capturing content that the project explicitly promises not to
  capture, or persisting captured frames beyond their intended lifetime.
- **Memory safety** in the driver and in the capture/upscale/present pipeline, particularly
  around attacker-influenced sizes: monitor descriptions, EDID blobs, mode lists and
  configuration files.
- **Local privilege escalation** via configuration, IPC between the application and the driver,
  or the `DeviceIoControl` surface.
- **Supply chain.** Compromised build dependencies, signing pipeline issues, or release
  artifacts that do not match the published source.

## Out of scope

These are documented limitations of the approach rather than vulnerabilities. They are
described in [docs/05-risks-and-limitations.md](docs/05-risks-and-limitations.md):

- **The secure desktop cannot be captured.** UAC prompts, Ctrl+Alt+Del and the login screen are
  outside the reach of user-mode capture APIs. This is expected behaviour, not a bug — but if
  you find a way to make DisplayBoost *lock a user out*, that **is** in scope and we want to
  hear about it.
- **DRM-protected playback appears black.** Content on an HDCP path cannot be captured by
  design.
- **Windows that opt out of capture** via `SetWindowDisplayAffinity` will not appear. That is
  the API working correctly.
- **Anti-cheat software flagging a virtual display.** This is a compatibility concern, not a
  vulnerability in DisplayBoost.
- Issues that require an already-compromised kernel or an attacker with administrator rights
  prior to exploitation.

## Reporting something you are unsure about

If you are not sure whether something is in scope, report it privately anyway. A short report
that turns out to be a documented limitation costs us a few minutes; an unreported privilege
escalation costs users far more.
