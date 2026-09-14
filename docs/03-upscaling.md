# 03 — Upscaling

> **English** | [Türkçe](tr/03-olcekleme.md)

DisplayBoost's pipeline sees a **finished framebuffer**. No motion vectors, no depth buffer, no
per-frame jitter offsets, no engine cooperation. That single constraint eliminates every
well-known temporal upscaler and leaves a much shorter list of spatial filters.

This document establishes which of them can actually be used, which cannot, and — importantly —
which ones can be *legally shipped* in an MIT-licensed project.

## The constraint, stated precisely

| Data the upscaler wants | Available to DisplayBoost? |
|---|---|
| The lower-resolution colour buffer | ✅ Yes — that is the capture |
| Motion vectors | ❌ Only the renderer has them |
| Depth buffer | ❌ Same |
| Per-frame sub-pixel jitter offsets | ❌ Same |
| Exposure / tone-mapping state | ❌ Post-tone-mapping only |
| Temporal history | ⚠️ The project could accumulate its own, but without motion vectors it cannot do so reliably |

Everything that follows from this is a consequence of that table.

## Usable upscalers

### AMD FSR 1 — EASU + RCAS

**Status: recommended default.**

FSR 1 (FidelityFX Super Resolution 1) is a **spatial** upscaler consisting of two passes:

- **EASU** — Edge Adaptive Spatial Upsampling. A direction-aware interpolation that tries to
  reconstruct edges rather than smearing them the way bilinear filtering does.
- **RCAS** — Robust Contrast Adaptive Sharpening. A sharpening pass that adapts its strength to
  local contrast, avoiding the halos a uniform unsharp mask produces.

It is distributed by AMD under the **MIT licence** in the `FidelityFX-FSR` repository as
`ffx_fsr1.h`, containing the shader implementation for HLSL and GLSL, and it is also part of the
current FidelityFX SDK. It works on any GPU: it is a plain shader, not a hardware feature.

Requirements relevant to this pipeline:

- Input must be in **display-referred** colour space, after tone mapping. A composited desktop is
  already in exactly that state, which makes FSR 1 a good fit.
- The two passes are independent, so RCAS can be omitted if the sharpening is unwanted or if
  another filter is preferred.

Sources: [AMD GPUOpen — FSR](https://gpuopen.com/fidelityfx-superresolution/),
[GPUOpen-Effects/FidelityFX-FSR](https://github.com/GPUOpen-Effects/FidelityFX-FSR),
[EASU and RCAS algorithms](https://deepwiki.com/GPUOpen-Effects/FidelityFX-FSR/2.1-easu-and-rcas-algorithms).

### NVIDIA Image Scaling — NVScaler / NVSharpen

**Status: recommended alternative.**

NVIDIA released the image scaling algorithm as an open-source SDK under the **MIT licence**
(`NVIDIAImageScaling`, v1.0.3). It provides:

- **NVScaler** — a 6-tap scaling filter combined with four directional scaling and adaptive
  sharpening filters, in one compute shader pass. Scaling and sharpening together.
- **NVSharpen** — the adaptive directional sharpening algorithm alone, for when no scaling is
  needed. Should not be combined with NVScaler, which already sharpens.

Integration details worth recording now, because they constrain the D3D11 implementation:

| Requirement | Value |
|---|---|
| Shader entry points | `NIS_Scaler.h`, or the `NIS_Main.hlsl` / `NIS_Main.glsl` examples |
| Dispatch configuration | `NIS_Config.h`; per-architecture block and thread-group sizes via `NISOptimizer` |
| Default shader constants | NVScaler: block `32×24`, 256 threads. NVSharpen: block `32×32`, 256 threads |
| Input | Shader Resource View |
| Output | Unordered Access View |
| Coefficients | Two SRV textures (`coef_scaler`, `coef_USM`), fp32 or fp16 |
| Sampler | Linear filter, clamp-to-edge |
| Configuration | Constant buffer, updated when size or sharpness changes |
| Colour space | LDR `[0,1]`, HDR PQ `[0,1]`, or HDR Linear `[0,12.5]`; select with `NIS_HDR_MODE` |
| Input formats | `DXGI_FORMAT_R8G8B8A8_UNORM` or `DXGI_FORMAT_NV12` |

The SDK explicitly notes that its shaders process LDR and HDR content after tone mapping, and
that sharpening amplifies noise — film grain should be applied *after* the scaler, and low-pass
effects such as motion blur *before* it. For a desktop pipeline this mostly matters when video
is on screen.

Sources: [NVIDIAImageScaling README](https://github.com/NVIDIAGameWorks/NVIDIAImageScaling/blob/main/README.md),
[NVIDIA Image Scaling](https://developer.nvidia.com/rtx/image-scaling).

### First-party filters

Cheap, predictable, and useful for the cases where a learned-in filter is the wrong choice:

| Filter | Use case |
|---|---|
| **Lanczos** | Highest-quality general-purpose resampling for non-integer ratios such as 1366×768 → 1920×1080. Ringing is manageable with anti-ringing clamping. |
| **Bicubic** (Catmull-Rom, Mitchell, B-Spline) | Softer than Lanczos, fewer artefacts. A safe default for UI-heavy content. |
| **Bilinear + CAS** | Cheapest useful combination. Bilinear for the scale, Contrast Adaptive Sharpening to recover some edge definition. |
| **Nearest / integer** | Only for exact integer factors, which our default target is not. |

### Under evaluation

Anime4K, FSRCNNX, NNEDI3, ACNet and similar neural-network filters are available as HLSL
implementations and can produce striking results on the right content. They are **not** in the
V1 plan: each has its own licence, its own performance profile, and its own failure modes on
photographic or UI content. They are a plausible V3 addition once the core pipeline is measured.

## Unusable upscalers

| Technology | Why it cannot be used here |
|---|---|
| **FSR 2 / FSR 3 / FSR 3.1** | Temporal upscalers. They require motion vectors, a depth buffer and jitter from the renderer. MIT-licensed, but structurally unusable for a captured framebuffer. |
| **DLSS** | Requires NVIDIA's NGX SDK and integration inside the rendering engine. Not exposed as a general image filter. |
| **Intel XeSS** | The higher-quality modes require motion vectors and engine integration; the DP4a fallback path is still a temporal upscaler. |
| **NVIDIA RTX Video Super Resolution** | A video-specific pipeline (browser and media player integration with a restricted SDK), not a general-purpose desktop filter. |
| **GPU driver integer scaling** | Ampere-to-Ampere only. 1366×768 → 1920×1080 is **1.40625×**, not an integer factor, so it cannot express the default target. Where an integer relationship exists (960×540 → 1920×1080), nearest-neighbour is already available from the first-party filter list. |

## Licensing

This section exists because it constrains the implementation more than the algorithms do.

### The rule

DisplayBoost is **MIT-licensed**. Only code that can be redistributed under MIT — or code that is
kept clearly separated and correctly attributed — may enter the tree. In practice:

| Source | Licence | Can it be used? |
|---|---|---|
| AMD `FidelityFX-FSR` (`ffx_fsr1.h`) | **MIT** | ✅ Copy in, retain the copyright notice |
| AMD FidelityFX SDK (FSR 1 technique) | **MIT** | ✅ Same |
| NVIDIA `NVIDIAImageScaling` SDK | **MIT** | ✅ Copy in, retain the notice |
| First-party HLSL written for this project | MIT | ✅ |
| `microsoft/Windows-driver-samples` (`video/IndirectDisplay`) | **MS-PL** | ⚠️ See below |
| **Magpie** (Blinue/Magpie) | **GPL-3.0** | ❌ **Cannot be copied in any form** |
| Special K | Custom, source-available | ❌ Not compatible with an MIT distribution |

Sources: [NVIDIAImageScaling README](https://github.com/NVIDIAGameWorks/NVIDIAImageScaling/blob/main/README.md),
[Magpie](https://github.com/Blinue/Magpie),
[Windows-driver-samples LICENSE](https://github.com/microsoft/Windows-driver-samples/blob/main/LICENSE).

### The Magpie trap

Magpie is the most complete open-source study of capture-and-scale on Windows, and it ships HLSL
ports of FSR, NIS, Anime4K, FSRCNNX, NNEDI3, Lanczos, CAS and more. It is **GPL-3.0**.

Copying a shader file from Magpie into an MIT project is a licence violation, even when the
algorithm's upstream is MIT — the *file* is a Magpie contribution distributed under GPL. The
correct approach is to take FSR 1 from GPUOpen and NIS from NVIDIA GameWorks, where the licences
permit it, and to treat Magpie strictly as a reference for architecture and problem-solving.

This is not a technicality to work around. It is documented here so that no future contributor
makes the mistake by accident.

### The MS-PL question for the driver

The Microsoft Indirect Display Driver sample — the canonical starting point for any IddCx
virtual display — is licensed under the **Microsoft Public License (MS-PL)**, not MIT. MS-PL is
permissive and OSI-approved, but it has a specific condition:

> If you distribute any portion of the software in source code form, you may do so only under
> this license by including a complete copy of this license with your distribution.

The practical consequence for a single-licence repository: **driver source derived from the
Microsoft sample would have to remain under MS-PL**, producing a repository with mixed licensing
— MIT for the application and MS-PL for the derived driver files. That is legal and common, but
it must be explicit, with per-directory licence files and a note in the README.

There are two honest options, and the project has not yet chosen between them:

1. **Derive from the sample and accept mixed licensing.** Faster, better-tested code, and the
   IddCx programming model is subtle enough that a worked example is genuinely valuable.
2. **Write the driver from scratch against the documented IddCx API.** The API itself is
   documented on Microsoft Learn and is not covered by the sample's licence. Slower and riskier,
   but keeps the repository unambiguously MIT.

This is a decision point in [06 — Roadmap](06-roadmap.md), to be settled before V2 begins.

## Recommended defaults

| Setting | Choice | Reasoning |
|---|---|---|
| Default filter | **FSR 1 (EASU + RCAS)** | MIT, GPU-agnostic, designed for exactly this kind of input, and the best-documented spatial option |
| Alternative | **NVIDIA NIS** | MIT, single-pass scaling plus sharpening, strong on non-integer ratios and worth comparing against FSR 1 in V1 |
| UI / text mode | **Bicubic** or Lanczos with mild sharpening | FSR 1 and NIS are tuned for game imagery; on text they can look over-sharpened |
| Sharpening | Toggleable, off by default in UI mode | Sharpening artefacts are far more objectionable on text than on games |
| Auto mode | Pick the filter by content | Deferred to V3, once there is measured data to base it on |

The V1 prototype exists specifically to measure FSR 1, NIS and Lanczos against each other at
1366×768 → 1920×1080, on both game content and desktop content, and to publish the numbers.

## Continue reading

- [02 — Capture and present](02-capture-and-present.md) — where these passes sit in the pipeline
- [04 — Prior art](04-prior-art.md) — how existing tools pick their filters
- [07 — References](07-references.md) — the sources behind this document
