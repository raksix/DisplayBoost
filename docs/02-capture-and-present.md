# 02 — Capture and Present

> **English** | [Türkçe](tr/02-yakalama-ve-sunum.md)

This document covers the user-mode half of DisplayBoost: getting frames out of the virtual
display, upscaling them, and getting them onto the physical monitor with as little latency as
the platform allows.

Two design questions dominate everything else:

1. **Where do the frames come from?** A capture API reading the virtual display's output, or the
   IddCx driver itself handing its swapchain buffers somewhere.
2. **How do they get to the monitor without adding three frames of latency?** The present path
   decides whether this project is usable or not.

## Capture methods compared

| Method | Minimum OS | Granularity | Model | Cursor | Notes |
|---|---|---|---|---|---|
| **DXGI Desktop Duplication** (DDA) | Windows 8, WDDM 1.2 | Whole monitor | Polling (`AcquireNextFrame`) | Returned as separate pointer data, not in the frame | Lowest level, full control. Invalidated by mode changes and by any switch away from the application's desktop. |
| **Windows.Graphics.Capture** (WGC) | Windows 10 1903 | Window or monitor | Event-driven, delivers frames to a `Direct3D11CaptureFramePool` | Optional, via `IsCursorCaptureEnabled` | Built on the same underpinnings as DDA. Modern, better behaved across GPU and mode changes. |
| **DWM shared surface** (`DwmGetDxSharedSurface`) | All | Full desktop | Polling | Not captured | Undocumented, used by Magpie as one of its frame sources. Works until Microsoft changes it. |
| **GDI `BitBlt`** | All | Window or screen | Polling | Not captured | CPU-bound, slow, no synchronisation with the compositor. A compatibility fallback only. |
| **Inside the IddCx driver** | Windows 10 1607+ | The virtual display | Driver callback, no copy | Driver decides | Zero extra capture step — see below. |

Sources: [IDXGIOutputDuplication](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_2/nn-dxgi1_2-idxgioutputduplication),
[Magpie — Frame Capture System](https://deepwiki.com/Blinue/Magpie/3.7-frame-capture-system).

### The DDA invalidation problem

`IDXGIOutputDuplication` is invalidated, and returns `DXGI_ERROR_ACCESS_LOST`, whenever:

- The display mode changes.
- The operating system switches to a different desktop — **including the secure desktop used for
  UAC prompts and the login screen**.
- Another fullscreen DirectX or OpenGL application takes exclusive control of the output.

The documented recovery is to release the duplication interface and create a new one. In
practice that means the capture session must be a state machine that can tear down and rebuild
itself at any moment, not a loop that assumes a stable output. This is a first-class design
constraint, not error handling bolted on afterwards.

Sources: [IDXGIOutputDuplication remarks](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_2/nn-dxgi1_2-idxgioutputduplication),
[Capturing the Windows Secure Desktop](https://etducky.com/blog/windows-uac-secure-desktop-capture).

### Capturing from inside the driver

An IddCx indirect display driver receives the composited desktop image directly. The OS assigns
a swapchain to the driver via `EvtIddCxMonitorAssignSwapChain`, and the driver calls
`IddCxSwapChainReleaseAndAcquireBuffer` in `EvtIddCxSwapChainReleaseAndAcquireBuffer` to obtain
the current frame as a DXGI resource, then signals completion with
`IddCxSwapChainFinishedProcessingFrame`.

This is theoretically the cheapest possible capture path — no duplication interface, no separate
copy, no invalidation. The complication is what comes next: the driver runs in **Session 0**
with no windowing, while presenting to the physical monitor requires a window on the interactive
desktop. Getting the upscaled texture from the driver to the presenting application means a
shared texture or a shared memory surface, plus the synchronisation that implies.

That is a V2 design decision, deferred deliberately. V1 uses ordinary capture so that the
presentation path and the measurement methodology can be validated before a driver is involved.

## Present path

### Use the flip model

Every modern consideration follows from this: present with a flip-model swapchain
(`DXGI_SWAP_EFFECT_FLIP_DISCARD`), not the legacy bitblt model. Flip model is what makes
windowed presentation competitive with fullscreen exclusive and what enables multiplane overlay.

Under the flip model:

- **Independent flip** is the fast path. The swapchain's buffer goes straight to the display
  without the compositor, giving fullscreen-like latency in a borderless window. It requires
  `SetFullScreenState(TRUE)`, a borderless fullscreen window, and a non-windowed flip-model
  swapchain.
- **Composed flip** is the fallback. If anything forces the compositor back into the path, an
  extra composition step is added. Reports of the penalty vary; one developer report puts the
  difference at roughly **25–30 ms** on affected systems. Treat that figure as **anecdotal** —
  it is a single report, not a measured benchmark, and the project's own numbers will come from
  V1.

Sources: [For best performance, use DXGI flip model](https://learn.microsoft.com/en-us/windows/win32/direct3ddxgi/for-best-performance--use-dxgi-flip-model),
[NVIDIA — Advanced API Performance: Swap Chains](https://developer.nvidia.com/blog/advanced-api-performance-swap-chains/),
[Stack Overflow: enforcing independent flip](https://stackoverflow.com/questions/72558096/enforce-use-of-independent-flip-mode-with-dxgi-flip-swapchain).

### Reducing latency further

`DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT` plus `SetMaximumFrameLatency(1)` is
documented to reach **one frame of latency** in independent flip, with a graceful fallback when
independent flip is not available. Combined with a waitable object instead of a blocking present,
this keeps the CPU from queuing work ahead of the GPU.

Sources: [For best performance, use DXGI flip model](https://learn.microsoft.com/en-us/windows/win32/direct3ddxgi/for-best-performance--use-dxgi-flip-model).

### The trade-off with VRR and tearing

Presenting with vsync keeps tearing away but ties the present rate to the monitor's refresh.
Presenting with `DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING` avoids the forced wait but tears. Neither
is obviously right for a general-purpose scaler, and both interact badly with variable refresh
rate: an extra composition layer frequently prevents the display from entering a variable-refresh
state at all. This is documented as an open risk in
[05 — Risks and limitations](05-risks-and-limitations.md) rather than solved here.

## Presenting to a specific monitor

The presenting application must enumerate adapters and outputs to find the physical monitor by
its `DXGI_OUTPUT_DESC` device name, then create the swapchain on that adapter/output pairing.
Enumerating and binding explicitly avoids the common failure where a fullscreen borderless window
lands on the wrong display, or on the virtual display itself.

## Cross-adapter: the worst case

If the virtual display is created on one GPU and the physical monitor is attached to another —
the normal situation on a hybrid laptop with a MUX — then every frame has to cross adapters. On
modern Windows this is done by sharing a texture (`IDXGIResource1::CreateSharedHandle` with a
keyed mutex, or `D3D11_RESOURCE_MISC_SHARED_NTHANDLE`) and opening it on the other device.

The cost is real: the data travels over PCIe, and in the worst case through system memory. For a
1920×1080 32-bit frame at 60 Hz that is roughly **500 MB/s** of traffic before overhead —
**estimated**, not measured. A single cross-adapter copy per frame can easily exceed everything
the upscale saves.

The mitigation is to pin both sides to the same adapter. An IddCx driver can be told which
adapter processes its frames with `IddCxAdapterSetRenderAdapter`; community drivers resolve the
target adapter from its PCI bus number to get a stable `LUID` rather than matching by name. That
is the approach DisplayBoost intends to take, and hybrid systems remain a degraded configuration
until it is measured.

Sources: [IddCx versions](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/iddcx-versions),
[Virtual-Display-Driver changelog](https://github.com/VirtualDrivers/Virtual-Display-Driver).

## Cursor handling

This is the problem that makes or breaks the user experience, and it is easy to underestimate.

Desktop Duplication does **not** bake the cursor into the frame. It returns pointer shape and
position as separate data, and the caller must composite the cursor itself. Windows.Graphics.
Capture can include it, but then the cursor is upscaled along with everything else.

Three things have to be got right:

1. **Composite the cursor at output resolution, not input resolution.** If the cursor is
   composited into the 1366×768 frame and then upscaled, it becomes blurry and slightly the wrong
   size. Drawing it last, at 1920×1080, keeps it pixel-exact.
2. **Map the coordinate space.** The pointer moves over the physical monitor at native
   resolution. The desktop being captured lives in the virtual display's coordinate space. If the
   scaler covers the monitor, the mapping is a simple scale factor; if the layout is not a clean
   full-screen mirror, it is not.
3. **Do not add a frame of latency to the cursor.** A cursor that lags the mouse by even one frame
   at 60 Hz is noticeable. Compositing the cursor as the final step, after the upscale pass, is
   what makes this tractable.

Magpie's `CursorManager` is the most complete public treatment of this problem: coordinate
transformation via a source-to-scaled mapping, cursor speed adjustment through `SPI_SETMOUSESPEED`
so that mouse feel stays consistent, and separate "touch hole" windows for touch input. It is
GPL-3.0, so it is a reference to study and not code to copy — see
[03 — Upscaling](03-upscaling.md) for the licence reasoning.

Sources: [Magpie — Cursor Mapping and Multi-Monitor Support](https://deepwiki.com/Blinue/Magpie/2.5-cursor-mapping-and-multi-monitor-support).

## Latency budget

The following is the shape of the cost, not a measurement. Every number in it is an **estimate**
to be replaced by V1's benchmark.

| Stage | Cost | Notes |
|---|---|---|
| Frame production | 1 frame | DWM composites at the virtual display's refresh rate |
| Capture acquire | < 1 ms | GPU-side; a shared texture read plus synchronisation |
| Upscale pass | ~0.2–2 ms | Single compute pass; scales with output size, not with the filter's reputation |
| Cursor composite | < 0.2 ms | A small textured quad at output resolution |
| Present | 1–2 frames | 1 frame in independent flip with a waitable object; substantially more in composed flip |
| **Total** | **~2–3 frames** | Roughly 33–50 ms at 60 Hz |

For context, that is the same order of magnitude as the latency a frame-generation feature adds
by design, and it is added to whatever latency the application already has. It is the single
strongest argument against using DisplayBoost for competitive gaming, and it is why the project
documents itself as a quality feature.

## Failure modes and recovery

| Event | Effect | Required response |
|---|---|---|
| Mode change (resolution or refresh) | Duplication invalidated | Recreate the duplication interface; do not assume the old one works |
| Secure desktop (UAC, lock, Ctrl+Alt+Del) | `DXGI_ERROR_ACCESS_LOST` | Release and reacquire; the physical display must already be showing the secure desktop |
| Monitor hotplug or arrival/departure | Output list changes | Re-enumerate adapters and outputs, rebuild the swapchain |
| DPMS sleep / monitor power off | Presentation stalls | Pause the pipeline; do not spin |
| TDR (GPU reset) | Device removed | Full device recreation; this is not a recoverable per-frame error |
| Virtual display removed | Nothing to capture | Fall back to passthrough and surface a clear message |

A scaler that covers the user's only visible display and then fails has done real harm. Every one
of these paths needs a defined recovery behaviour, and the application needs to be able to get
out of the way entirely.

## Implications for DisplayBoost

1. **V1 should not use a driver at all.** Capture the current display, upscale, present on the
   same display. That validates the pipeline, produces the latency numbers, and does not risk
   locking anyone out.
2. **WGC is the likely default capture path**, with DDA as the lower-level option where its
   frame timestamps or dirty-region data are useful. WGC's event-driven model is a better fit for
   a pipeline that must tolerate the display stack changing under it.
3. **Independent flip is a requirement, not a nice-to-have.** If the present path cannot reach
   it, the latency penalty is larger than the entire budget of the rest of the pipeline.
4. **Cursor handling is a design phase of its own**, not a detail to bolt on at the end.
5. **Cross-adapter must be designed out, not optimised later.** Pin the virtual display's render
   adapter to the target monitor's adapter from the start.

## Continue reading

- [01 — Virtual display driver](01-virtual-display-driver.md) — where the frames originate
- [03 — Upscaling](03-upscaling.md) — what happens between capture and present
- [05 — Risks and limitations](05-risks-and-limitations.md) — the full risk register
