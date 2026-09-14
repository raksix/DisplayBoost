# Roadmap

A milestone-level summary. For the reasoning, success criteria and measurement plan behind each
phase, see [docs/06-roadmap.md](docs/06-roadmap.md).

DisplayBoost lowers the resolution Windows renders the desktop at, captures the result, upscales
it on the GPU and presents it to the physical monitor. Read
[docs/00-overview.md](docs/00-overview.md) first if that is new to you — and read
[docs/05-risks-and-limitations.md](docs/05-risks-and-limitations.md) before assuming it will make
your games faster, because it often will not.

## Milestones

| Milestone | Scope | Exit criteria | Status |
|---|---|---|---|
| **V0 — Research** | Feasibility study across the IddCx driver model, capture and present paths, upscaler licensing, prior art and risks. | Every architectural claim is sourced, the risk register is complete, and a phased plan with measurable criteria exists. | ✅ Complete |
| **V1 — Driver-less prototype** | Capture an existing display with DXGI Desktop Duplication, upscale with FSR 1 or NVIDIA NIS, present fullscreen on the same monitor. No virtual display, no driver, no topology changes. | Published latency, GPU-cost and image-quality numbers for at least FSR 1, NIS and Lanczos at 1366×768 → 1920×1080. Reproducible benchmarks, not impressions. | 🔜 Next |
| **V2 — Virtual display** | IddCx indirect display driver as the low-resolution render target. Capture the virtual output, present on the physical monitor. Ship or document the driver signing path. | A working virtual display at a configurable resolution, captured and presented end to end, with a documented and reversible install/uninstall path. | 📋 Planned |
| **V3 — Automatic profiles** | Detect the monitor's native mode, propose the optimal render resolution and scaler, apply in one click, and remember per-application overrides. | A first-run flow that configures a correct setup without the user reading any documentation. | 💡 Idea |

## Explicitly out of scope

These are not "not yet" — they are decisions, justified in
[docs/00-overview.md](docs/00-overview.md):

- Frame generation and synthetic frame interpolation
- Per-application hooking, DLL injection or overlay rendering
- Capturing DRM-protected playback
- Covering the secure desktop (UAC, Ctrl+Alt+Del, login)

## How to influence the roadmap

Open an issue. The most persuasive inputs at this stage are **contradicting measurements**, a
**prior-art project we missed**, or a **failure mode** you have hit in production. See
[CONTRIBUTING.md](CONTRIBUTING.md).
