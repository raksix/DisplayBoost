# 06 — Roadmap

> **English** | [Türkçe](tr/06-yol-haritasi.md)

The plan is deliberately ordered so that the riskiest, most irreversible work — a display driver
that can take over the user's screen — comes **after** the pipeline is proven and measured.

## Phase summary

| Phase | Scope | Status |
|---|---|---|
| **V0 — Research** | Feasibility, IddCx, capture and present, upscaling licences, prior art, risks | ✅ Complete |
| **V1 — Driver-less prototype** | Capture, upscale, present on the existing display. Measurements. | 🔜 Next |
| **V2 — Virtual display** | IddCx driver as the low-resolution render target | 📋 Planned |
| **V3 — Automatic profiles** | Detection, recommendations, one-click setup | 💡 Idea |

---

## V0 — Research ✅

**Deliverable:** these documents.

**Exit criteria, all met:**

- Every architectural claim is backed by a primary source in [07 — References](07-references.md),
  or explicitly labelled as an estimate.
- The IddCx version-to-Windows matrix is verified against Microsoft Learn.
- Every candidate upscaler has a stated licence and a clear verdict on usability.
- The risk register in [05 — Risks and limitations](05-risks-and-limitations.md) is complete,
  including the risks that argue against the project.
- A phased plan exists with measurable success criteria.

**What the research changed.** Three findings materially reshaped the project:

1. **The performance premise is much weaker than it first appears.** Driver-level AMD RSR and
   NVIDIA NIS already do the same low-resolution-to-native trick inside the present path. The
   project was repositioned from "make everything faster" to "cover what the drivers do not".
2. **The Microsoft IDD sample is MS-PL, not MIT.** This is a real constraint on the repository's
   licensing model, recorded as [R-15](05-risks-and-limitations.md#r-15--driver-licensing-ms-pl-versus-mit).
3. **Magpie is GPL-3.0.** Its shader collection cannot be copied into an MIT project, so the
   upscalers must come from AMD and NVIDIA directly.

---

## V1 — Driver-less prototype 🔜

**Goal: prove the pipeline and produce the numbers, without touching display topology.**

Capture an existing display, upscale it, and present it fullscreen on that same display. No
virtual display, no driver, no administrator rights, no risk of stranding anyone. The output is
functionally a very elaborate mirror — and that is exactly the point.

### Scope

- A D3D11 application that captures the primary display with Windows.Graphics.Capture, with DXGI
  Desktop Duplication as an alternative backend.
- Three upscale backends: **FSR 1 (EASU + RCAS)**, **NVIDIA NIS (NVScaler)** and **Lanczos**.
- Fullscreen, flip-model presentation with `DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT`
  and `SetMaximumFrameLatency(1)`.
- Cursor composited at output resolution, as the final step.
- A benchmark mode that reports frame times for each stage.

### Success criteria

| Criterion | Target |
|---|---|
| Runs at 1366×768 → 1920×1080 on a DirectX 11 feature level 11 GPU | Required |
| Present mode reported as **independent flip** on the reference machine | Required |
| Per-stage timing reported, not guessed: capture, upscale, cursor, present | Required |
| Comparison of FSR 1, NIS and Lanczos on **game content and desktop content separately** | Required |
| End-to-end added latency measured against a native baseline | Required |
| Methodology documented well enough for a third party to reproduce | Required |
| Any GPU cost measured as a delta against the same scene rendered natively | Required |

**What V1 explicitly does not do:** no driver, no virtual display, no HDR, no VRR claims, no
anti-cheat claims, no desktop text-quality claims.

### Why this order matters

V1 is cheap, entirely reversible, and it answers the questions that would otherwise be answered by
guesswork inside a driver. If the measured overhead turns out to exceed the saving in every
realistic case, that is a result — and it costs nothing but the prototype.

---

## V2 — Virtual display 📋

**Goal: make the low-resolution render target real.**

### Open decisions to settle before V2 begins

| Decision | Options | Leaning |
|---|---|---|
| **Driver source** | Derive from the MS-PL sample (mixed licence, faster) vs. clean-room against the documented IddCx API (unambiguously MIT, slower) | Undecided — [R-15](05-risks-and-limitations.md#r-15--driver-licensing-ms-pl-versus-mit) |
| **Frame handoff** | Capture the virtual output from user mode (simple, an extra copy) vs. hand the IddCx swapchain texture to the presenting process (faster, far more intricate) | Start with user-mode capture, measure, then optimise |
| **IddCx target** | 1.10 for HDR on Windows 11 23H2+ vs. 1.5 for a wider Windows 10 reach | 1.10 with a 1.5 fallback path |
| **Display scope** | Whole desktop on the virtual display vs. a single application window on it | **Start narrow.** Making the virtual display primary drags in window management, taskbar ownership and the secure desktop for no additional insight — see [R-16](05-risks-and-limitations.md#r-16--display-ownership-and-window-management) |
| **Signing route** | SignPath Foundation vs. attestation signing with an EV certificate | SignPath first |

### Scope

- An IddCx indirect display driver advertising a deliberate, small mode list.
- Render adapter pinned to the physical monitor's adapter via `IddCxAdapterSetRenderAdapter` and a
  PCI-derived `LUID`.
- A safe install, uninstall and recovery flow, reversible without Safe Mode in the normal case and
  documented for the cases where it is not.
- Capture of the virtual output and presentation on the physical monitor, reusing V1's pipeline.

### Success criteria

| Criterion | Target |
|---|---|
| Virtual display at a configurable resolution, visible to Windows as a normal monitor | Required |
| Frames captured and presented end to end at the same latency as V1, ±1 frame | Required |
| Install and uninstall reversible, with no residual display configuration | Required |
| Recovery from Safe Mode documented and tested | Required |
| The physical monitor remains the console display at all times | Required |
| Escape hotkey disables DisplayBoost and restores the previous configuration | Required |
| Cross-adapter cost measured on a hybrid system, or the configuration declared unsupported | Required |

---

## V3 — Automatic profiles 💡

**Goal: a first-run experience that configures itself correctly.**

- Enumerate the physical monitor and read its native mode.
- Propose the best render resolution and filter combination from the measured V1 data, taking the
  scale ratio and the content type into account.
- Apply in one click, with a preview.
- Remember per-application overrides.
- Detect and warn about the configurations in the risk register: hybrid adapters, HDR displays,
  VRR displays, DRM playback.

This is where the project becomes usable by someone who has not read any of these documents, which
is the only definition of "done" that matters.

---

## Explicitly out of scope

These are decisions, not deferrals, and the reasoning is in
[00 — Overview](00-overview.md):

| Out of scope | Why |
|---|---|
| Frame generation | Different problem, different latency budget, and it does not reduce render cost |
| DLL injection, hooks, overlays | Anti-cheat risk, fragility across updates, and responsibility for other applications' crashes |
| Capturing DRM-protected playback | Not possible via the available APIs |
| Covering the secure desktop | Not possible from user mode |
| Supersampling above native | The opposite direction from the project's purpose |
| Linux, macOS | A different compositor model, and a different project |

---

## Measurement methodology

So that V1's numbers mean something:

- **Reference hardware must be stated** in full: CPU, GPU, driver version, monitor native mode and
  refresh rate, and the Windows build.
- **Latency** is measured, not inferred: the added delay from input to photons, comparing native
  rendering against the DisplayBoost chain on the same content. Frame-count reasoning is not a
  measurement.
- **GPU cost** is a delta against the same scene rendered natively, not an absolute figure.
- **Image quality** is compared on two content classes separately — game-like imagery and desktop
  text — because the filters are tuned very differently for each and an aggregate score would hide
  exactly the trade-off users need to know about.
- **Present mode is reported**, not assumed: whether the swapchain reached independent flip
  changes the latency result by more than the rest of the pipeline combined.
- **Every negative result is published.** A benchmark set that only reports the cases where the
  project wins is not a benchmark.

---

## How to influence the plan

The most useful contributions right now are the ones in
[CONTRIBUTING.md](../CONTRIBUTING.md): corrections to the research, prior art the project missed,
measurements that contradict the estimates here, and failure modes from people who have shipped
display drivers or capture overlays.
