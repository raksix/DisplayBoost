# 07 — Kaynaklar

> [English](../07-references.md) | **Türkçe**

Bu araştırmada kullanılan tüm kaynaklar. Tüm linkler **2026-09-14** tarihinde erişilebilir olarak
doğrulandı.

Bir doküman olgusal bir iddiada bulunduğunda, URL'yi metinde tekrarlamak yerine aşağıdaki girdiye
link verir. Bir iddianın kaynağı yoksa, doküman onu tahmin olarak etiketler.

## Microsoft dokümantasyonu

| Kaynak | Neyi için kullanıldı |
|---|---|
| [Indirect display driver overview](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/indirect-display-driver-model-overview) | IDD'nin tanımı: UMDF2, Session 0, izin verilen API'ler, universal driver gereksinimi, örnek işaretçisi. Son güncelleme 2025-11-07 |
| [IddCx versions](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/iddcx-versions) | Tam IddCx sürüm matrisi: sürüm başına özellikler, `IddCxGetVersion` değerleri ve Windows derlemesi eşlemesi. Son güncelleme 2026-04-02 |
| [Updates for IddCx versions 1.11 and later](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/iddcx1-dot-11-updates) | D3D12 desteği, `IddCxSwapChainSetDevice2`, `IddCxCheckOsFeatureSupport`, DisplayID descriptor'ları, down-level uyumluluk kuralları |
| [`IddCxSwapChainReleaseAndAcquireBuffer`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/iddcx/nf-iddcx-iddcxswapchainreleaseandacquirebuffer) | Sürücü tarafından kare edinimi |
| [`IddCxSwapChainReleaseAndAcquireBuffer2`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/iddcx/nf-iddcx-iddcxswapchainreleaseandacquirebuffer2) | FP16 ve HDR kare edinimi; HDR adaptörleri için orijinal yerine zorunlu |
| [Indirect Display Driver Sample](https://learn.microsoft.com/en-us/samples/microsoft/windows-driver-samples/indirect-display-driver-sample/) | Kanonik örneğin kapsamı: tek monitör, konfigürasyon yok |
| [`IDXGIOutputDuplication`](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_2/nn-dxgi1_2-idxgioutputduplication) | Desktop Duplication: mod değişimlerinde, secure desktop dahil farklı bir masaüstüne geçişte ve exclusive fullscreen uygulamalarda geçersizleşme |
| [For best performance, use DXGI flip model](https://learn.microsoft.com/en-us/windows/win32/direct3ddxgi/for-best-performance--use-dxgi-flip-model) | Flip model, independent flip, `DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT`, tek kare gecikme |
| [Attestation Sign Windows Drivers](https://learn.microsoft.com/en-us/windows-hardware/drivers/dashboard/code-signing-attestation) | Partner Center üzerinden attestation signing akışı |
| [Driver Code Signing Requirements](https://learn.microsoft.com/en-us/windows-hardware/drivers/dashboard/code-signing-reqs) | Sertifika türleri ve gereksinimler |
| [`ChangeDisplaySettingsEx`](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-changedisplaysettingsexa) | Ekran yapılandırma değişiklikleri: `DM_POSITION`, birincil ekran işlemleri |
| [Code signing options for Windows app developers](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options) | Açık kaynak projeler için SignPath Foundation mevcudiyetini doğruluyor |

## Sürücü örnekleri ve sanal ekran projeleri

| Kaynak | Neyi için kullanıldı |
|---|---|
| [microsoft/Windows-driver-samples — `video/IndirectDisplay`](https://github.com/microsoft/Windows-driver-samples/tree/main/video/IndirectDisplay) | Kanonik IddCx örneği |
| [Windows-driver-samples LICENSE](https://github.com/microsoft/Windows-driver-samples/blob/main/LICENSE) | **MS-PL**, MIT değil. `R-15` riskinin temeli |
| [VirtualDrivers/Virtual-Display-Driver](https://github.com/VirtualDrivers/Virtual-Display-Driver) | Referans topluluk IddCx implementasyonu: IddCx 1.10, HDR 10/12-bit, hardware cursor, özel EDID, ARM64, PCI bus'tan LUID'e render adaptörü seçimi, SignPath imzalaması ve GPU sürücüsü güncellemesi siyah ekran uyarısı |
| [nomi-san/parsec-vdd](https://github.com/nomi-san/parsec-vdd) | Parsec'in VDD'sini saran bağımsız bir kullanıcı modu sarmalayıcı ve bir SignPath Foundation projesi |
| [Parsec VDD destek dokümantasyonu](https://support.parsec.app/hc/en-us/sections/32361161093780-Virtual-Display-Driver-VDD) | Parsec'in kendi sanal ekran sürücüsü dokümantasyonu |
| [ge9/IddSampleDriver](https://github.com/ge9/IddSampleDriver) | MIT/CC0 lisanslı örnek fork; Virtual Display Driver çalışmasının atası |
| [SudoMaker/SudoVDA](https://github.com/SudoMaker/SudoVDA) | MTT Virtual Display Driver soyundan gelen tam bir yeniden yazım |

## Yakalama, sunum ve gecikme

| Kaynak | Neyi için kullanıldı |
|---|---|
| [Magpie — Frame Capture System](https://deepwiki.com/Blinue/Magpie/3.7-frame-capture-system) | Kare kaynağı mimarisi: `FrameSourceBase`, WGC, Desktop Duplication, GDI ve DWM shared surface implementasyonları; duplicate-frame tespiti; çıkış doku formatı |
| [Magpie — Cursor Mapping and Multi-Monitor Support](https://deepwiki.com/Blinue/Magpie/2.5-cursor-mapping-and-multi-monitor-support) | `CursorManager`, kaynak-ölçeklenmiş koordinat eşlemesi, `SPI_SETMOUSESPEED` ayarı, touch-hole pencereleri, çoklu monitör modları |
| [Magpie — Scaling Modes and Effects](https://deepwiki.com/Blinue/Magpie/2.3-scaling-modes-and-effects) | Efekt sistemi, MagpieFX formatı ve yerleşik filtrelerin tam listesi |
| [Desktop Duplication API vs Windows.Graphics.Capture](https://stackoverflow.com/questions/74084077/desktop-duplication-api-vs-windows-graphics-capture) | İki API arasındaki ilişki ve hangisinin ne zaman tercih edileceği |
| [NVIDIA — Advanced API Performance: Swap Chains](https://developer.nvidia.com/blog/advanced-api-performance-swap-chains/) | Flip-model swapchain'ler, multiplane overlay ve immediate independent flip gereksinimleri |
| [Enforce use of independent flip mode](https://stackoverflow.com/questions/72558096/enforce-use-of-independent-flip-mode-with-dxgi-flip-swapchain) | Composed flip gecikme cezası raporu (**anekdot**, öyle alıntılandı) |
| [Capturing the Windows Secure Desktop with a uiAccess Process](https://etducky.com/blog/windows-uac-secure-desktop-capture) | Secure desktop aktifleştiğinde `DXGI_ERROR_ACCESS_LOST` ve bir uiAccess sürecinin yapıp yapamadıkları |
| [Sunshine — Windows capture methods](https://deepwiki.com/qiin2333/foundation-sunshine/4.1.1-windows-capture-methods) | Üçüncü bir implementasyonun Desktop Duplication, WGC ve AMD display capture karşılaştırması |

## Ölçekleme

| Kaynak | Neyi için kullanıldı |
|---|---|
| [AMD GPUOpen — FidelityFX Super Resolution](https://gpuopen.com/fidelityfx-superresolution/) | FSR genel bakış ve lisans |
| [GPUOpen-Effects/FidelityFX-FSR](https://github.com/GPUOpen-Effects/FidelityFX-FSR) | `ffx_fsr1.h`, MIT lisanslı FSR 1 shader implementasyonu |
| [FidelityFX Super Resolution 1.2 (FSR1)](https://gpuopen.com/manuals/fidelityfx_sdk/techniques/super-resolution-spatial/) | Güncel FidelityFX SDK içindeki FSR1 |
| [EASU and RCAS algorithms](https://deepwiki.com/GPUOpen-Effects/FidelityFX-FSR/2.1-easu-and-rcas-algorithms) | FSR 1'in iki geçişli yapısı |
| [NVIDIAImageScaling](https://github.com/NVIDIAGameWorks/NVIDIAImageScaling) | MIT lisanslı NIS SDK v1.0.3: `NIS_Scaler.h`, `NIS_Main.hlsl`, `NIS_Config.h`, `NISOptimizer`, HDR modları, doku formatları, sampler ve dispatch gereksinimleri |
| [Getting Started with NVIDIA Image Scaling](https://developer.nvidia.com/rtx/image-scaling) | NVIDIA'nın SDK'yı kendi anlatımı |
| [NVIDIA Image Scaling goes open source](https://www.phoronix.com/news/NVIDIA-Image-Scaling-SDK-1.0) | SDK'nın compute shader'larının MIT lisanslı ve üretici bağımsız olduğunun doğrulanması |

## Alternatifler ve benzer projeler

| Kaynak | Neyi için kullanıldı |
|---|---|
| [Blinue/Magpie](https://github.com/Blinue/Magpie) | **GPL-3.0**, ~14.9k yıldız, Windows 10 1903+ ve DirectX feature level 11 gereksinimleri, özellik listesi, mimari |
| [Lossless Scaling spatial scalers guide](https://sageinfinity.github.io/docs/FAQ/scalers) | Borderless ve windowed gereksinimleri, resize-before-scaling davranışı |
| [Lossless Scaling LSFG guide](https://steamcommunity.com/app/993090/discussions/0/4139437492715610827/) | Exclusive fullscreen'in çalışmadığının doğrulanması |
| [Automatic Super Resolution](https://support.microsoft.com/en-us/windows/ai/ai-features/automatic-super-resolution) | Microsoft'un kendi tanımı ve bulunabilirliği |
| [Auto SR limitations](https://windowsforum.com/news/windows-11-gaming-2025-2026-fse-asd-and-auto-sr.393231/) | HDR yok, sadece DirectX 11/12, uyumluluk listesi ve başlık bazında isteğe bağlı katılım |
| [AMD Radeon Super Resolution](https://www.amd.com/en/products/software/adrenalin/radeon-super-resolution.html) | Sürücü düzeyi özellik ve kapsamı |
| [TechPowerUp — Radeon Super Resolution review](https://www.techpowerup.com/review/amd-radeon-super-resolution-rsr/) | Sürücü düzeyi FSR 1'in bağımsız kalite ve performans değerlendirmesi |

## Süreç ve araçlar

| Kaynak | Neyi için kullanıldı |
|---|---|
| [SignPath Foundation](https://signpath.org/) | Açık kaynak projeler için ücretsiz OV kod imzalama |
| [SignPath — ParsecVDisplay](https://signpath.org/projects/parsecvdisplay/) | Bir sanal ekran projesinin programa uygun olduğunun kanıtı |
| [Build a WDF driver for multiple versions of Windows](https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/building-a-wdf-driver-for-multiple-versions-of-windows) | Down-level sürücü uyumluluğu; IddCx 1.11 dokümantasyonunun referans verdiği sayfa |
| [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) | CHANGELOG formatı |
| [Conventional Commits](https://www.conventionalcommits.org/) | Commit mesajı konvansiyonu |
| [Contributor Covenant 2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct.html) | Code of Conduct |

## Kaynak kalitesi üzerine notlar

Bu araştırmanın ne olduğu ve ne olmadığı konusunda açık olmak gerekirse:

- **Birincil kaynaklar tercih edildi.** Bir soruyu Microsoft Learn veya üreticinin kendi
  dokümantasyonu yanıtladığında, alıntılanan odur. Stack Overflow ve üçüncü taraf yazılar
  yalnızca birincil kaynağın bulunmadığı yerlerde kullanıldı ve öyle işaretlendi.
- **Tek kaynaklı rakamlar işaretlendi.** Composed flip gecikme cezası tek bir geliştirici
  raporunda geçiyor ve benchmark olarak değil anekdot olarak alıntılandı.
- **Tahminler etiketlendi.** Gecikme bütçesi, adaptörler arası bant genişliği rakamı ve upscale
  geçiş maliyeti akıl yürütülmüş tahminlerdir ve bunları kullanan her doküman bunu söyler.
- **Sürüm numaraları tarihlidir.** IddCx sürümleri, sürücü yetenekleri ve proje özellikleri
  değişir. Bu dokümanın başındaki doğrulama tarihi içindeki her link için geçerlidir.
- **Topluluk projelerinin detayları kayar.** Topluluk sanal ekran sürücülerinin yıldız sayıları,
  IddCx hedefleri ve lisansları doğrulama tarihinde doğruydu ve bunlardan birine dayanmadan önce
  yeniden kontrol edilmelidir.

Bu dokümanlarda yanlış veya kaynaksız bir iddia bulursanız, yapabileceğiniz en değerli şey bir
[research correction issue](https://github.com/raksix/DisplayBoost/issues/new?template=research_correction.yml)
açmaktır.
