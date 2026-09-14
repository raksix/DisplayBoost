# 05 — Risks and Limitations

> **English** | [Türkçe](tr/05-riskler-ve-sinirlar.md)

**Read this document before getting excited about the project.** It is the reason the README
describes DisplayBoost as a coverage and quality feature rather than a performance feature, and it
is the list anyone considering DisplayBoost should check first.

Nothing here is hypothetical hand-waving: each entry is either a documented platform limitation
or a consequence of the architecture that the design has to work around.

## Summary

| ID | Risk | Severity | Status |
|---|---|---|---|
| [R-01](#r-01--the-secure-desktop-cannot-be-captured) | Secure desktop cannot be captured; possible lockout | 🔴 Critical | Mitigated by design |
| [R-02](#r-02--cursor-handling) | Cursor handling, mapping and latency | 🔴 Critical | Open — designed for in V1 |
| [R-03](#r-03--net-performance-is-frequently-negative) | Net performance is frequently zero or negative | 🔴 Critical | **Inherent — documented, not fixed** |
| [R-04](#r-04--added-latency-and-loss-of-independent-flip) | +1–3 frames of latency; loss of independent flip | 🟠 High | Partially mitigated |
| [R-05](#r-05--protected-content-appears-black) | DRM-protected content appears black | 🟠 High | Accepted limitation |
| [R-06](#r-06--cross-adapter-copies-on-hybrid-systems) | Cross-adapter copy per frame on hybrid systems | 🟠 High | Mitigation planned |
| [R-07](#r-07--text-and-ui-blur-at-non-integer-ratios) | Text and UI blur at 1.40625× | 🟠 High | Presets planned |
| [R-08](#r-08--exclusive-fullscreen-bypasses-the-pipeline) | Exclusive fullscreen bypasses the pipeline | 🟡 Medium | Accepted limitation |
| [R-09](#r-09--anti-cheat-and-virtual-displays) | Anti-cheat interaction is unverified | 🟡 Medium | Open |
| [R-10](#r-10--display-topology-changes-break-the-capture-session) | Topology changes break the capture session | 🟡 Medium | Recovery designed for |
| [R-11](#r-11--driver-signing-and-distribution) | Driver signing, admin rights, distribution | 🟡 Medium | Route identified |
| [R-12](#r-12--hdr-and-wide-colour-gamut) | HDR and wide colour gamut | 🟡 Medium | Deferred to post-V2 |
| [R-13](#r-13--black-screen-after-a-gpu-driver-update) | Black screen after a GPU driver update | 🟡 Medium | Documented procedure |
| [R-14](#r-14--hdr-vrr-and-adaptive-sync-breakage) | VRR / G-Sync / FreeSync breakage | 🟡 Medium | Open |
| [R-15](#r-15--driver-licensing-ms-pl-versus-mit) | Driver licensing: MS-PL versus MIT | 🟡 Medium | Open decision |
| [R-16](#r-16--display-ownership-and-window-management) | Which display owns the taskbar, and window placement | 🟡 Medium | Open |
| [R-17](#r-17--no-measurements-exist-yet) | No measurements exist yet | 🟡 Medium | Addressed by V1 |

---

## R-01 — The secure desktop cannot be captured

**Severity: critical. This is the risk that dictates the entire safety design.**

UAC prompts, Ctrl+Alt+Del and the login screen run on the **secure desktop**, an isolated desktop
that user-mode capture APIs cannot reach. `IDXGIOutputDuplication` documents that its interfaces
become invalid "when the operating system switches to a different component that produces the
desktop image", and it returns `DXGI_ERROR_ACCESS_LOST` in exactly this situation.

The consequence is worse than a black frame. If the virtual display were made the *only* display,
Windows could present the secure desktop on a monitor that nobody can see, while the user stares
at the real monitor — a lockout with no in-band way out.

**Mitigation (mandatory, not optional):**

- The physical monitor **always remains the Windows console display**. The virtual display is
  never the sole display, and is never the console display.
- The application must detect capture loss and degrade to passthrough rather than showing a frozen
  or black image.
- A global escape hotkey must disable DisplayBoost entirely and restore the previous display
  configuration.
- The uninstall path must work from Safe Mode, and must be documented in the README rather than
  buried in the wiki.

Sources: [IDXGIOutputDuplication](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_2/nn-dxgi1_2-idxgioutputduplication),
[Capturing the Windows Secure Desktop with a uiAccess Process](https://etducky.com/blog/windows-uac-secure-desktop-capture).

---

## R-02 — Cursor handling

**Severity: critical, because it is the most visible failure and the easiest to get wrong.**

Desktop Duplication does not include the cursor in the frame: it returns pointer shape and
position separately, and the caller must composite the cursor itself. Windows.Graphics.Capture can
include the cursor, but then it is upscaled along with everything else — a blurry, wrongly-sized
pointer.

Three separate problems are stacked here:

- **Composite position.** Drawing the cursor into the low-resolution frame and upscaling it makes
  it soft. It has to be drawn last, at output resolution.
- **Coordinate mapping.** The pointer moves over the physical monitor in native coordinates; the
  captured desktop lives in the virtual display's coordinates. Mapping is simple only when the
  layout is a clean full-screen mirror.
- **Latency.** A cursor lagging by even one frame at 60 Hz is noticeable and immediately
  objectionable. This argues for compositing the cursor as the final step of the present path,
  after the upscale, rather than as part of the captured content.

Magpie's `CursorManager` — coordinate transformation, `SPI_SETMOUSESPEED` adjustment for
consistent mouse feel, and touch-hole windows — is the best public reference for the mapping
problem. It is GPL-3.0, so it can be studied and not copied.

Sources: [Magpie — Cursor Mapping and Multi-Monitor Support](https://deepwiki.com/Blinue/Magpie/2.5-cursor-mapping-and-multi-monitor-support).

---

## R-03 — Net performance is frequently negative

**Severity: critical, because it undermines the intuitive expectation of the whole project.**

Whether DisplayBoost makes anything faster depends entirely on the workload.

**What gets cheaper.** Per-pixel work. 1366×768 is ≈1.05 MP against 1920×1080 at ≈2.07 MP — close
to half the shading, depth and raster operations for anything that scales with pixel count.

**What does not get cheaper.** Everything else: geometry, tessellation, compute, culling, draw
submission, and all CPU-side cost. A draw-call-bound workload gains nothing.

**What gets more expensive.** A capture read of the virtual framebuffer, an upscale pass, an extra
present, and the added latency. And if the two displays are on different adapters, a
cross-adapter copy every frame — see [R-06](#r-06--cross-adapter-copies-on-hybrid-systems).

**The honest conclusion.** For a fill-rate-bound game the arithmetic can work out. For the
desktop, UI and video — where per-pixel shading is cheap and the compositor is already efficient —
the fixed overhead can equal or exceed the saving. And for the cases where a real win exists,
driver-level AMD RSR or NVIDIA NIS already deliver it inside the present path, with no virtual
display and no capture copy.

**Mitigation: honesty.** The project states this plainly in the README and here. It does not
promise performance. Its value proposition is coverage and filter quality, and V1 exists to
produce numbers rather than arguments.

Sources: [AMD Radeon Super Resolution](https://www.amd.com/en/products/software/adrenalin/radeon-super-resolution.html),
[TechPowerUp — RSR quality and performance review](https://www.techpowerup.com/review/amd-radeon-super-resolution-rsr/).

---

## R-04 — Added latency and loss of independent flip

**Severity: high.**

The pipeline adds one frame for the virtual display's composition, roughly a millisecond for the
capture and upscale, and one to two frames at present — **approximately 2–3 frames in total,
roughly 33–50 ms at 60 Hz (estimated, to be measured in V1)**.

The variable part is the present path. **Independent flip** is the low-latency path, and it
requires a non-windowed flip-model swapchain, a borderless fullscreen window, and
`SetFullScreenState(TRUE)`. If anything forces the pipeline into **composed flip** instead, an
extra composition step is inserted; one developer report puts the difference at roughly 25–30 ms
(**anecdotal**, single source).

**Mitigations:**

- Use the flip model from the start; never ship a bitblt-model present path.
- Use `DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT` with `SetMaximumFrameLatency(1)`,
  which is documented to reach one frame of latency in independent flip.
- Measure the actual present mode in V1 rather than assuming it, and surface it in diagnostics.
- Document the latency so users can decide for themselves whether the trade is worth it.

Sources: [For best performance, use DXGI flip model](https://learn.microsoft.com/en-us/windows/win32/direct3ddxgi/for-best-performance--use-dxgi-flip-model),
[Enforce use of independent flip mode](https://stackoverflow.com/questions/72558096/enforce-use-of-independent-flip-mode-with-dxgi-flip-swapchain).

---

## R-05 — Protected content appears black

**Severity: high.**

Content playing on an HDCP-protected path cannot be captured. Streaming services that detect an
unprotected or virtual display path may refuse to play at all, and anything that opts out of
capture with `SetWindowDisplayAffinity(WDA_EXCLUDEFROMCAPTURE)` will be invisible.

**Mitigation:** none, and none is attempted. The correct behaviour is to detect it, document it,
and let the affected window pass through unmodified rather than showing the user a black
rectangle. This is explicitly listed as a non-goal in
[00 — Overview](00-overview.md).

---

## R-06 — Cross-adapter copies on hybrid systems

**Severity: high, and capable on its own of erasing the entire gain.**

On a laptop with a MUX — or any system where the virtual display is created on one GPU and the
physical monitor is attached to another — every frame has to cross adapters over PCIe, in the
worst case through system memory. For a 1080p 32-bit frame at 60 Hz that is roughly 500 MB/s
before overhead (**estimated**).

**Mitigation:** pin the virtual display's render adapter to the same adapter as the target
monitor, using `IddCxAdapterSetRenderAdapter` and a stable `LUID` derived from the PCI bus number
rather than a device name. Until this is implemented and measured, **hybrid systems should be
treated as a degraded configuration** and documented as such.

Sources: [IddCx versions](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/iddcx-versions),
[Virtual-Display-Driver](https://github.com/VirtualDrivers/Virtual-Display-Driver).

---

## R-07 — Text and UI blur at non-integer ratios

**Severity: high, because it affects the desktop every day, not just games.**

1366×768 → 1920×1080 is **1.40625×**, not an integer. Every glyph is resampled. Subpixel
antialiasing (ClearType) degrades because it depends on exact pixel alignment. On a desktop used
for reading and writing, this is a constant, visible regression.

There is also a DPI consequence: Windows and every application believe the display is 1366×768,
with that resolution's DPI, so window layout, snapping and per-monitor DPI behaviour follow the
virtual display and are then rescaled again by the scaler.

**Mitigations:**

- Offer **integer-friendly presets** where the ratio is exact — 960×540 → 1920×1080 at 2×,
  1280×720 → 2560×1440 at 2× — even though a 2× nearest-neighbour or Lanczos scale looks
  different from FSR.
- Offer a **UI mode** that uses bicubic or Lanczos with sharpening off, since FSR 1 and NIS are
  tuned for game imagery and can look over-sharpened on text.
- Be explicit in the documentation that desktop text quality is the price of the approach.

---

## R-08 — Exclusive fullscreen bypasses the pipeline

**Severity: medium.**

A game in exclusive fullscreen holds the display path directly. It will not appear on the virtual
display, so nothing is captured and nothing is scaled. Lossless Scaling's documentation is
explicit about the same constraint.

**Mitigation:** document it. The supported configuration is windowed or borderless fullscreen.
Applications that cannot run borderless are out of scope.

Source: [Lossless Scaling scaler guide](https://sageinfinity.github.io/docs/FAQ/scalers).

---

## R-09 — Anti-cheat and virtual displays

**Severity: medium, and largely unquantified.**

DisplayBoost's out-of-process capture is a genuine advantage over injected tools: it does not
touch the game's process. But anti-cheat systems may still object to *virtual displays*, unusual
adapters or screen capture in general, and the research did not find reliable evidence either way.

**Mitigation:** document it as unverified, do not claim compatibility, and give users a fast way
to disable the virtual display before launching a competitive title. This is a question better
answered by community reports than by speculation.

---

## R-10 — Display topology changes break the capture session

**Severity: medium.**

`IDXGIOutputDuplication` instances become invalid on mode changes, on any switch away from the
desktop being duplicated, and when the display device changes. Monitor hotplug, DPMS sleep and
resume, and driver updates all invalidate assumptions the pipeline may be holding.

**Mitigation:** treat the capture session as a state machine that can tear down and rebuild at any
moment, never as a stable loop. Enumerate adapters and outputs on every rebuild rather than
caching them. Watch for `WM_DISPLAYCHANGE` and for adapter/output arrival and removal.

See the failure-mode table in [02 — Capture and present](02-capture-and-present.md).

---

## R-11 — Driver signing and distribution

**Severity: medium.**

A display driver requires administrator rights to install and a valid signature to load. Users
cannot be expected to enable test signing, and asking them to do so would also break some
anti-cheat configurations.

**Route identified:**

- **SignPath Foundation** provides free OV-level code signing for qualifying open-source projects,
  with CI integration and keys held in the Foundation's HSM. Both the Virtual Display Driver and
  ParsecVDisplay use it, which is direct evidence the route works for this class of project.
- **Attestation signing** through Microsoft Partner Center with an **EV code-signing certificate**
  remains the fallback, and is required for any path that Partner Center itself signs.
- The installer must never install a driver without explicit, informed consent, and the uninstall
  path must work even when the display is not.

Sources: [SignPath Foundation](https://signpath.org/),
[Attestation Sign Windows Drivers](https://learn.microsoft.com/en-us/windows-hardware/drivers/dashboard/code-signing-attestation).

---

## R-12 — HDR and wide colour gamut

**Severity: medium.**

HDR requires IddCx 1.10 (Windows 11 23H2+) on the driver side, and an HDR-aware colour pipeline on
the capture and upscale side. NVIDIA NIS supports HDR Linear and PQ modes, but FSR 1 is designed
for display-referred SDR content after tone mapping, and the capture path may return FP16 surfaces
that need careful handling to avoid banding or a wrong transfer function.

**Mitigation:** **V1 ships SDR only, and says so.** HDR comes after the SDR path is correct and
measured. Note that Windows Automatic Super Resolution does not support HDR either — the
difficulty is not unique to this project.

Source: [Automatic Super Resolution](https://support.microsoft.com/en-us/windows/ai/ai-features/automatic-super-resolution).

---

## R-13 — Black screen after a GPU driver update

**Severity: medium, but with an obvious recovery.**

Documented by the Virtual Display Driver project: during a major GPU or chipset driver update,
Windows re-enumerates display devices and can promote the virtual display ahead of the physical
one. Because the virtual display has no physical screen, the result is a black screen on a system
that is otherwise working.

**Mitigation:** document that the virtual display should be uninstalled before a GPU driver
update. For recovery: force shutdown two or three times to reach Windows Recovery, boot to Safe
Mode, and remove the display adapter — or, if the system is merely showing the wrong display,
`Win+P` and cycling the options.

Source: [Virtual-Display-Driver troubleshooting](https://github.com/VirtualDrivers/Virtual-Display-Driver).

---

## R-14 — HDR, VRR and adaptive sync breakage

**Severity: medium.**

Variable refresh rate is negotiated between the GPU and the monitor. Inserting an extra
composition layer frequently prevents the display from entering a variable-refresh state at all,
reintroducing judder, or forces the pipeline into composed flip and its latency penalty. Mixed
refresh rates between the virtual display and the physical monitor compound the problem.

**Mitigation:** V1 measures present mode and frame pacing directly and reports what it actually
achieved. Users who depend on VRR should be told plainly that this may not be for them.

---

## R-15 — Driver licensing: MS-PL versus MIT

**Severity: medium, and entirely avoidable if decided early.**

The canonical IddCx sample in `microsoft/Windows-driver-samples` is licensed under the **Microsoft
Public License (MS-PL)**, not MIT. MS-PL is permissive, but it requires that source distributions
of the software remain under MS-PL. Deriving DisplayBoost's driver from that sample would
therefore create a **mixed-licence repository**: MIT for the application, MS-PL for the derived
driver source.

Two options, and the project has not yet chosen:

1. **Derive from the sample, accept mixed licensing.** Faster and lower risk technically, since
   IddCx's programming model is subtle and a worked example is valuable. Requires per-directory
   licence files and explicit documentation.
2. **Write the driver from scratch against the documented IddCx API.** The API documentation is
   not covered by the sample's licence. Slower, riskier, but the repository stays unambiguously
   MIT.

Sources: [Windows-driver-samples LICENSE](https://github.com/microsoft/Windows-driver-samples/blob/main/LICENSE),
[Indirect display driver overview](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/indirect-display-driver-model-overview).

---

## R-16 — Display ownership and window management

**Severity: medium.**

Making the virtual display primary and moving existing windows onto it is not an officially
supported operation. The primary monitor is defined by its position at the virtual-desktop origin,
usually reconfigured through `SetDisplayConfig`, and "move every window" is implemented by
enumerating top-level windows and repositioning them — an approach that elevated windows,
fullscreen windows and windows on other desktops will resist.

There is also a user-experience question with no obviously correct answer: which display should
own the taskbar and the notification area while the scaler is active?

**Mitigation:** consider not making the virtual display primary at all in the first iteration, and
instead scoping DisplayBoost to a single application or a single window on the virtual display.
That reduces the topology work to nothing and leaves the secure desktop, the taskbar and window
management entirely alone. It also narrows the product — a decision worth making explicitly rather
than by accident.

Sources: [ChangeDisplaySettingsEx](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-changedisplaysettingsexa).

---

## R-17 — No measurements exist yet

**Severity: medium.**

Every performance figure in these documents is an **estimate** or is **sourced from third
parties**. DisplayBoost has measured nothing of its own. The latency budget, the cross-adapter
cost and the upscale pass cost are all reasoned from first principles and published sources, not
from this project's hardware.

**Mitigation:** V1 exists specifically to fix this. It will publish latency, GPU cost and image
quality for FSR 1, NIS and Lanczos at 1366×768 → 1920×1080, with a documented methodology, before
any driver work begins. Until then, treat every number here as provisional.

---

## Known limitations summary

Things DisplayBoost will not do, stated plainly:

- **It will not make a modern game faster** than the in-game upscaler or the GPU driver's own
  scaling option.
- **It will not work with exclusive fullscreen** applications.
- **It will not capture the secure desktop**, DRM-protected video, or windows that opt out of
  capture.
- **It will not work without administrator rights**, because installing a display driver requires
  them.
- **It will not preserve text sharpness** as well as running at native resolution. That is the
  fundamental trade.
- **It will not eliminate the GPU's work**, only the per-pixel portion of it.

## Continue reading

- [06 — Roadmap](06-roadmap.md) — how these risks shape the plan
- [00 — Overview](00-overview.md) — the design principles that come out of this register
- [07 — References](07-references.md) — the sources behind every claim above
