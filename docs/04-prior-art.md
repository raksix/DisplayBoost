# 04 — Prior Art

> **English** | [Türkçe](tr/04-benzer-projeler.md)

Every component of DisplayBoost exists somewhere already. What does not exist is the specific
combination: a **whole-desktop, display-level** scaling chain that lowers what Windows renders.
Knowing precisely how the neighbours differ is what keeps this project honest about what it adds.

## The tools

### Magpie — `Blinue/Magpie`

| | |
|---|---|
| **Licence** | **GPL-3.0** |
| **Popularity** | ~14.9k stars, ~666 forks |
| **Stack** | C++/WinRT, Direct3D 11, WinUI |
| **Requirements** | Windows 10 v1903+, DirectX feature level 11 |
| **What it is** | A general-purpose **window** upscaler with a MagpieFX shader format and a large effects library: FSR, NIS, Anime4K, FSRCNNX, NNEDI3, ACNet, CRT shaders, SMAA/FXAA, CAS, Lanczos, bicubic, bilinear, nearest |

**What it does well.** Magpie is the most complete open treatment of the capture-and-scale problem
on Windows. Its frame-source abstraction (`GraphicsCaptureFrameSource`,
`DesktopDuplicationFrameSource`, `GDIFrameSource`, `DwmSharedSurfaceFrameSource`) is a good model
for handling the platform's variability. Its duplicate-frame detection using a compute shader
(`DuplicateFrameCS.hlsl`) is a neat trick for not re-rendering unchanged content. Its
`CursorManager` is the most serious public attempt at cursor mapping.

**How DisplayBoost differs.** Magpie **magnifies a window that already rendered at its own
resolution**. It changes how pixels are stretched, never how many are rendered. It therefore saves
no render cost at all — it is a quality tool, and it is honest about being one. DisplayBoost
lowers the resolution the desktop is *composed* at, which is where the (conditional) saving comes
from.

**What we take from it.** Architecture lessons only. The licence forbids copying anything, and
the shader files in particular are GPL-3.0 contributions even where the upstream algorithm is MIT.
See [03 — Upscaling](03-upscaling.md).

### Lossless Scaling

| | |
|---|---|
| **Licence** | Closed source, sold on Steam (around US$7) |
| **What it is** | External upscaling (LS1, FSR 1, NIS, integer) for a captured window, plus **LSFG** frame generation |

**How it works.** It captures a window or a fullscreen app and re-presents it scaled. It requires
the application to run in **windowed or borderless mode** — the guides are explicit that exclusive
fullscreen does not work. Frame generation inserts synthetic frames between real ones, which raises
perceived smoothness without raising the render rate, and adds latency by design.

**How DisplayBoost differs.** Lossless Scaling is per-application and does not lower the
application's render resolution; the user does that themselves in-game. DisplayBoost is
display-level. Frame generation is explicitly outside DisplayBoost's scope — it is a different
problem with a different latency budget.

**What it tells us.** That users will pay for this category of tool, and that the per-application
model is the established one. It also tells us that the *combination* of capture latency and frame
generation latency is already a known complaint, which is a warning for any pipeline that adds
both.

### Windows Automatic Super Resolution (Auto SR)

| | |
|---|---|
| **Availability** | Windows 11 24H2+, Copilot+ PCs, and the ROG Xbox Ally X |
| **Hardware** | Requires an **NPU**; not available on ordinary x86 gaming hardware at launch |
| **Scope** | DirectX 11 and 12 games, opted in per title |

**What it is.** Microsoft's OS-level super resolution. The game renders at a lower internal
resolution and Auto SR restores it — conceptually the closest thing to DisplayBoost's goal that
ships today.

**How DisplayBoost differs.** Three ways, and all three are worth understanding:

1. **It uses the NPU**, not the GPU. DisplayBoost is GPU-only by design and therefore runs on
   hardware Auto SR cannot touch.
2. **It is inside the compositor.** There is no virtual display, no capture copy and no extra
   present. Its overhead is structurally lower than anything DisplayBoost can achieve.
3. **It is restricted.** HDR is not supported, DirectX 9, OpenGL and Vulkan are not supported, and
   fine HUD and UI text is known to suffer at very low internal resolutions.

**What it tells us.** Microsoft validated the demand, and chose the in-stack approach precisely
because the capture-based approach carries costs that are hard to hide. That is the strongest
evidence for this project's own honest framing: the general case is hard, and the value is in
coverage rather than raw performance.

### AMD Radeon Super Resolution (RSR)

| | |
|---|---|
| **What it is** | Driver-level **FSR 1 (EASU)** applied inside the present path of any fullscreen game |
| **Requirements** | Fullscreen, game rendering below the display's native resolution |

**Why it matters here.** RSR is the closest functional competitor to DisplayBoost and it is
strictly cheaper: no virtual display, no capture copy, no extra frame. It does the same
low-resolution-to-native trick and the user does not install a driver to get it.

**How DisplayBoost differs.** RSR engages for **fullscreen games** and nothing else. It will never
help a legacy windowed application, a browser, or the desktop itself. That is the gap DisplayBoost
targets, and it is a narrower gap than "better performance" would suggest.

### NVIDIA features

| Feature | What it does | Relevance |
|---|---|---|
| **NVIDIA Image Scaling (driver feature)** | Driver-level NIS spatial upscaling and sharpening | Direct competitor on the same terms as RSR |
| **DSR / DLDSR** | Renders **above** native and downsamples — supersampling | Opposite direction; irrelevant to performance |
| **RTX Video Super Resolution** | Tensor-core upscaling for video playback only | Confirms that GPU upscaling of a captured surface is practical at scale, but it is not a general desktop filter |
| **Integer scaling** | Nearest-neighbour by exact integer factors | Cannot express 1366×768 → 1920×1080, which is 1.40625× |

### Others worth knowing

| Tool | What it does | Why it matters to us |
|---|---|---|
| **Intel XeSS** | Per-game temporal upscaler with a DP4a fallback | Needs engine integration; not a generic filter |
| **Special K** | Injected game framework: flip-model forcing, frame limiting, HDR retrofit, FSR injection | Injection is explicitly outside DisplayBoost's design, and it carries anti-cheat risk |
| **ReShade** | Post-process shader injection for D3D9–12, OpenGL and Vulkan | Proves shader-based upscaling as a post-process works; still requires the app to render at the lower resolution itself |
| **Borderless Gaming** | Forces windowed games to borderless fullscreen | Not a scaler, but a useful precursor — many games need it before any capture-based scaler can work |
| **Magpie's Linux/SteamOS equivalents, Gamescope** | Compositor-level scaling with FSR 1 on Linux | Architecturally the closest thing to DisplayBoost that exists anywhere: it lowers the render resolution *at the compositor*. Worth studying for the idea, not the code. |

## Positioning

| Dimension | Magpie / Lossless Scaling | RSR / NIS (driver) | Auto SR | **DisplayBoost** |
|---|---|---|---|---|
| Capture scope | One window | The game's present call | The game's swapchain, in-compositor | **Whole desktop** |
| Lowers render resolution | No | Yes | Yes | **Yes** |
| Requires per-app support | Capture support only | Fullscreen only | Per-title opt-in | **No** |
| Extra per-frame copies | One capture, one present | None | None | **One capture, one upscale, one present** |
| Hardware requirement | Any D3D11 GPU | AMD / NVIDIA GPU | Copilot+ NPU | **Any D3D11 GPU** |
| Needs a display driver | No | No | No | **Yes** |
| Works on legacy fixed-resolution software | Partly | No | No | **Yes** |
| Adds latency | Yes | Minimal | Some | **Yes, 1–3 frames** |

Read the last three rows together and the trade is clear: DisplayBoost pays a driver installation
and added latency in exchange for coverage that none of the alternatives provide.

## Where DisplayBoost can genuinely win

1. **Software that will never get an upscaler.** Legacy fixed-resolution games, old CAD and
   line-of-business tools, emulators without scaling options, and anything abandoned by its
   developer.
2. **Whole-desktop coverage.** When the goal is "everything is cheaper to draw", the alternatives
   do not offer a mechanism at all.
3. **Filter quality over the monitor's scaler.** A monitor stretching 768p to 1080p uses whatever
   cheap scaler is in its display controller. FSR 1, NIS or Lanczos with proper sharpening control
   is meaningfully better, and that is true whether or not any performance is saved.
4. **Deterministic, inspectable behaviour.** No injection, no hooks, no per-game patching. The
   pipeline is visible and its costs are measurable.

## Where DisplayBoost cannot compete

1. **Frame rate in a modern game.** The in-game upscaler will always win: it has motion vectors
   and depth, it does not pay for a capture, and it does not add a frame.
2. **Fullscreen games generally.** Exclusive fullscreen bypasses the chain entirely.
3. **Protected content.** HDCP content cannot be captured.
4. **The secure desktop.** UAC, Ctrl+Alt+Del and the login screen are out of reach.

All four are documented in [05 — Risks and limitations](05-risks-and-limitations.md), because a
reader who discovers them after installing will reasonably feel misled.

## Continue reading

- [03 — Upscaling](03-upscaling.md) — the filters these tools use, and their licences
- [05 — Risks and limitations](05-risks-and-limitations.md) — the full risk register
- [07 — References](07-references.md) — sources
