# 07 — References

> **English** | [Türkçe](tr/07-kaynaklar.md)

Every source used in this research. All links were verified as reachable on **2026-09-14**.

Where a document makes a factual claim, it links to the entry below rather than repeating the URL
inline. Where a claim has no source, the document labels it as an estimate.

## Microsoft documentation

| Source | Used for |
|---|---|
| [Indirect display driver overview](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/indirect-display-driver-model-overview) | What an IDD is: UMDF2, Session 0, allowed APIs, universal driver requirement, sample pointer. Last updated 2025-11-07 |
| [IddCx versions](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/iddcx-versions) | The complete IddCx version matrix: features per version, `IddCxGetVersion` values, and the Windows build mapping. Last updated 2026-04-02 |
| [Updates for IddCx versions 1.11 and later](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/iddcx1-dot-11-updates) | D3D12 support, `IddCxSwapChainSetDevice2`, `IddCxCheckOsFeatureSupport`, DisplayID descriptors, down-level compatibility rules |
| [`IddCxSwapChainReleaseAndAcquireBuffer`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/iddcx/nf-iddcx-iddcxswapchainreleaseandacquirebuffer) | Frame acquisition from the driver's perspective |
| [`IddCxSwapChainReleaseAndAcquireBuffer2`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/iddcx/nf-iddcx-iddcxswapchainreleaseandacquirebuffer2) | FP16 and HDR frame acquisition; required instead of the original for HDR adapters |
| [Indirect Display Driver Sample](https://learn.microsoft.com/en-us/samples/microsoft/windows-driver-samples/indirect-display-driver-sample/) | Scope of the canonical sample: one monitor, no configuration |
| [`IDXGIOutputDuplication`](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_2/nn-dxgi1_2-idxgioutputduplication) | Desktop Duplication: invalidation on mode changes, on switching to a different desktop including the secure desktop, and on exclusive fullscreen applications |
| [For best performance, use DXGI flip model](https://learn.microsoft.com/en-us/windows/win32/direct3ddxgi/for-best-performance--use-dxgi-flip-model) | Flip model, independent flip, `DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT`, one-frame latency |
| [Attestation Sign Windows Drivers](https://learn.microsoft.com/en-us/windows-hardware/drivers/dashboard/code-signing-attestation) | The attestation signing workflow through Partner Center |
| [Driver Code Signing Requirements](https://learn.microsoft.com/en-us/windows-hardware/drivers/dashboard/code-signing-reqs) | Certificate types and requirements |
| [`ChangeDisplaySettingsEx`](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-changedisplaysettingsexa) | Display configuration changes: `DM_POSITION`, primary display handling |
| [Code signing options for Windows app developers](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options) | Confirms SignPath Foundation availability for open-source projects |

## Driver samples and virtual display projects

| Source | Used for |
|---|---|
| [microsoft/Windows-driver-samples — `video/IndirectDisplay`](https://github.com/microsoft/Windows-driver-samples/tree/main/video/IndirectDisplay) | The canonical IddCx sample |
| [Windows-driver-samples LICENSE](https://github.com/microsoft/Windows-driver-samples/blob/main/LICENSE) | **MS-PL**, not MIT. The basis for [R-15](05-risks-and-limitations.md#r-15--driver-licensing-ms-pl-versus-mit) |
| [VirtualDrivers/Virtual-Display-Driver](https://github.com/VirtualDrivers/Virtual-Display-Driver) | The reference community IddCx implementation: IddCx 1.10, HDR 10/12-bit, hardware cursor, custom EDID, ARM64, PCI-bus-to-LUID render adapter selection, SignPath signing, and the GPU-driver-update black screen warning |
| [nomi-san/parsec-vdd](https://github.com/nomi-san/parsec-vdd) | A standalone user-mode wrapper around Parsec's VDD, and a SignPath Foundation project |
| [Parsec VDD support documentation](https://support.parsec.app/hc/en-us/sections/32361161093780-Virtual-Display-Driver-VDD) | Parsec's own virtual display driver documentation |
| [ge9/IddSampleDriver](https://github.com/ge9/IddSampleDriver) | MIT/CC0 licensed sample fork; the ancestor of the Virtual Display Driver effort |
| [SudoMaker/SudoVDA](https://github.com/SudoMaker/SudoVDA) | A full rewrite descended from the MTT Virtual Display Driver lineage |

## Capture, presentation and latency

| Source | Used for |
|---|---|
| [Magpie — Frame Capture System](https://deepwiki.com/Blinue/Magpie/3.7-frame-capture-system) | The frame-source architecture: `FrameSourceBase`, WGC, Desktop Duplication, GDI and DWM shared surface implementations; duplicate-frame detection; output texture format |
| [Magpie — Cursor Mapping and Multi-Monitor Support](https://deepwiki.com/Blinue/Magpie/2.5-cursor-mapping-and-multi-monitor-support) | `CursorManager`, source-to-scaled coordinate mapping, `SPI_SETMOUSESPEED` adjustment, touch-hole windows, multi-monitor modes |
| [Magpie — Scaling Modes and Effects](https://deepwiki.com/Blinue/Magpie/2.3-scaling-modes-and-effects) | The effect system, the MagpieFX format, and the full list of built-in filters |
| [Desktop Duplication API vs Windows.Graphics.Capture](https://stackoverflow.com/questions/74084077/desktop-duplication-api-vs-windows-graphics-capture) | The relationship between the two APIs and when to prefer each |
| [NVIDIA — Advanced API Performance: Swap Chains](https://developer.nvidia.com/blog/advanced-api-performance-swap-chains/) | Flip-model swapchains, multiplane overlay, and the requirements for immediate independent flip |
| [Enforce use of independent flip mode](https://stackoverflow.com/questions/72558096/enforce-use-of-independent-flip-mode-with-dxgi-flip-swapchain) | The composed-flip latency penalty report (**anecdotal**, quoted as such) |
| [Capturing the Windows Secure Desktop with a uiAccess Process](https://etducky.com/blog/windows-uac-secure-desktop-capture) | `DXGI_ERROR_ACCESS_LOST` on secure desktop activation, and what a uiAccess process can and cannot do |
| [Sunshine — Windows capture methods](https://deepwiki.com/qiin2333/foundation-sunshine/4.1.1-windows-capture-methods) | A third implementation's comparison of Desktop Duplication, WGC and AMD display capture |

## Upscaling

| Source | Used for |
|---|---|
| [AMD GPUOpen — FidelityFX Super Resolution](https://gpuopen.com/fidelityfx-superresolution/) | FSR overview and licence |
| [GPUOpen-Effects/FidelityFX-FSR](https://github.com/GPUOpen-Effects/FidelityFX-FSR) | `ffx_fsr1.h`, the MIT-licensed FSR 1 shader implementation |
| [FidelityFX Super Resolution 1.2 (FSR1)](https://gpuopen.com/manuals/fidelityfx_sdk/techniques/super-resolution-spatial/) | FSR1 in the current FidelityFX SDK |
| [EASU and RCAS algorithms](https://deepwiki.com/GPUOpen-Effects/FidelityFX-FSR/2.1-easu-and-rcas-algorithms) | The two-pass structure of FSR 1 |
| [NVIDIAImageScaling](https://github.com/NVIDIAGameWorks/NVIDIAImageScaling) | The MIT-licensed NIS SDK v1.0.3: `NIS_Scaler.h`, `NIS_Main.hlsl`, `NIS_Config.h`, `NISOptimizer`, HDR modes, texture formats, sampler and dispatch requirements |
| [Getting Started with NVIDIA Image Scaling](https://developer.nvidia.com/rtx/image-scaling) | NVIDIA's own description of the SDK |
| [NVIDIA Image Scaling goes open source](https://www.phoronix.com/news/NVIDIA-Image-Scaling-SDK-1.0) | Confirmation that the SDK's compute shaders are MIT-licensed and vendor-neutral |

## Alternatives and prior art

| Source | Used for |
|---|---|
| [Blinue/Magpie](https://github.com/Blinue/Magpie) | **GPL-3.0**, ~14.9k stars, Windows 10 1903+ and DirectX feature level 11 requirements, feature list, architecture |
| [Lossless Scaling spatial scalers guide](https://sageinfinity.github.io/docs/FAQ/scalers) | Borderless and windowed requirements, resize-before-scaling behaviour |
| [Lossless Scaling LSFG guide](https://steamcommunity.com/app/993090/discussions/0/4139437492715610827/) | Confirmation that exclusive fullscreen does not work |
| [Automatic Super Resolution](https://support.microsoft.com/en-us/windows/ai/ai-features/automatic-super-resolution) | Microsoft's own description and availability |
| [Auto SR limitations](https://windowsforum.com/news/windows-11-gaming-2025-2026-fse-asd-and-auto-sr.393231/) | No HDR, DirectX 11/12 only, compatibility list and per-title opt-in |
| [AMD Radeon Super Resolution](https://www.amd.com/en/products/software/adrenalin/radeon-super-resolution.html) | The driver-level feature and its scope |
| [TechPowerUp — Radeon Super Resolution review](https://www.techpowerup.com/review/amd-radeon-super-resolution-rsr/) | Independent quality and performance assessment of driver-level FSR 1 |

## Programme and tooling

| Source | Used for |
|---|---|
| [SignPath Foundation](https://signpath.org/) | Free OV code signing for open-source projects |
| [SignPath — ParsecVDisplay](https://signpath.org/projects/parsecvdisplay/) | Evidence that a virtual display project qualifies for the programme |
| [Build a WDF driver for multiple versions of Windows](https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/building-a-wdf-driver-for-multiple-versions-of-windows) | Down-level driver compatibility, referenced by the IddCx 1.11 documentation |
| [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) | CHANGELOG format |
| [Conventional Commits](https://www.conventionalcommits.org/) | Commit message convention |
| [Contributor Covenant 2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct.html) | Code of Conduct |

## Notes on source quality

Being explicit about what this research is and is not:

- **Primary sources were preferred.** Where Microsoft Learn or a vendor's own documentation
  answered a question, that is what is cited. Stack Overflow and third-party write-ups are used
  only where no primary source exists, and are marked as such.
- **Single-source figures are flagged.** The composed-flip latency penalty appears once, in a
  developer report, and is quoted as anecdotal rather than as a benchmark.
- **Estimates are labelled.** The latency budget, the cross-adapter bandwidth figure and the
  upscale pass cost are reasoned estimates, and every document that uses them says so.
- **Version numbers are dated.** IddCx versions, driver capabilities and project features all
  change. The verification date at the top of this document applies to every link in it.
- **Community project details drift.** Star counts, IddCx targets and licensing for the community
  virtual display drivers were accurate on the verification date and should be re-checked before
  any of them is relied on.

If you find a claim in these documents that is wrong or unsourced, the most valuable thing you can
do is open a [research correction issue](https://github.com/raksix/DisplayBoost/issues/new?template=research_correction.yml).
