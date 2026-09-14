# 03 — Ölçekleme

> [English](../03-upscaling.md) | **Türkçe**

DisplayBoost'un hattı **tamamlanmış bir framebuffer** görür. Motion vector yok, depth buffer yok,
kare başına jitter offset'i yok, motor işbirliği yok. Bu tek kısıt, bilinen tüm temporal
upscaler'ları eliyor ve çok daha kısa bir spatial filtre listesi bırakıyor.

Bu doküman hangilerinin gerçekten kullanılabileceğini, hangilerinin kullanılamayacağını ve —
önemlisi — hangilerinin MIT lisanslı bir projede **yasal olarak dağıtılabileceğini** ortaya koyuyor.

## Kısıt, tam olarak

| Upscaler'ın istediği veri | DisplayBoost'ta mevcut mu? |
|---|---|
| Düşük çözünürlüklü renk tamponu | ✅ Evet — yakalama zaten bu |
| Motion vector'lar | ❌ Yalnızca renderer'da var |
| Depth buffer | ❌ Aynı |
| Kare başına alt piksel jitter offset'leri | ❌ Aynı |
| Pozlama / tone-mapping durumu | ❌ Yalnızca tone mapping sonrası |
| Temporal geçmiş | ⚠️ Proje kendi geçmişini biriktirebilir, ama motion vector olmadan bunu güvenilir yapamaz |

Bunu takip eden her şey bu tablonun bir sonucu.

## Kullanılabilir upscaler'lar

### AMD FSR 1 — EASU + RCAS

**Durum: önerilen varsayılan.**

FSR 1 (FidelityFX Super Resolution 1), iki geçişten oluşan bir **spatial** upscaler:

- **EASU** — Edge Adaptive Spatial Upsampling. Bilinear filtrenin kenarları bulandırdığı yerde
  kenarları yeniden kurmaya çalışan, yön farkındalıklı bir interpolasyon.
- **RCAS** — Robust Contrast Adaptive Sharpening. Gücünü yerel kontrasta uyarlayan bir
  keskinleştirme geçişi; tekdüze bir unsharp mask'ın ürettiği haleleri önler.

AMD tarafından **MIT lisansı** altında `FidelityFX-FSR` reposunda `ffx_fsr1.h` olarak dağıtılıyor;
bu dosya shader implementasyonunu HLSL ve GLSL olarak içeriyor ve güncel FidelityFX SDK'nın da
parçası. Her GPU'da çalışır: bir donanım özelliği değil, sadece bir shader.

Bu hat için önemli gereksinimler:

- Giriş **display-referred** renk uzayında, tone mapping sonrası olmalı. Oluşturulmuş bir masaüstü
  zaten tam olarak bu durumda, bu da FSR 1'i iyi bir eşleşme yapıyor.
- İki geçiş bağımsız, yani keskinleştirme istenmiyorsa veya başka bir filtre tercih edilirse RCAS
  atlanabilir.

Kaynaklar: [AMD GPUOpen — FSR](https://gpuopen.com/fidelityfx-superresolution/),
[GPUOpen-Effects/FidelityFX-FSR](https://github.com/GPUOpen-Effects/FidelityFX-FSR),
[EASU and RCAS algorithms](https://deepwiki.com/GPUOpen-Effects/FidelityFX-FSR/2.1-easu-and-rcas-algorithms).

### NVIDIA Image Scaling — NVScaler / NVSharpen

**Durum: önerilen alternatif.**

NVIDIA, görüntü ölçekleme algoritmasını **MIT lisansı** altında açık kaynak SDK olarak yayınladı
(`NVIDIAImageScaling`, v1.0.3). Sağladıkları:

- **NVScaler** — 6 tap'lı bir ölçekleme filtresi ile dört yönlü ölçekleme ve uyarlanabilir
  keskinleştirme filtresinin tek bir compute shader geçişinde birleşimi. Ölçekleme ve
  keskinleştirme birlikte.
- **NVSharpen** — ölçekleme gerekmediğinde yalnızca uyarlanabilir yönlü keskinleştirme. Zaten
  keskinleştirme yapan NVScaler ile birlikte kullanılmamalı.

D3D11 implementasyonunu kısıtladığı için şimdiden kaydetmeye değer entegrasyon detayları:

| Gereksinim | Değer |
|---|---|
| Shader giriş noktaları | `NIS_Scaler.h`, veya `NIS_Main.hlsl` / `NIS_Main.glsl` örnekleri |
| Dispatch yapılandırması | `NIS_Config.h`; `NISOptimizer` üzerinden mimariye özel block ve thread group boyutları |
| Varsayılan shader sabitleri | NVScaler: block `32×24`, 256 thread. NVSharpen: block `32×32`, 256 thread |
| Giriş | Shader Resource View |
| Çıkış | Unordered Access View |
| Katsayılar | İki SRV dokusu (`coef_scaler`, `coef_USM`), fp32 veya fp16 |
| Sampler | Linear filtre, clamp-to-edge |
| Yapılandırma | Constant buffer; boyut veya keskinlik değiştiğinde güncellenir |
| Renk uzayı | LDR `[0,1]`, HDR PQ `[0,1]` veya HDR Linear `[0,12.5]`; `NIS_HDR_MODE` ile seçilir |
| Giriş formatları | `DXGI_FORMAT_R8G8B8A8_UNORM` veya `DXGI_FORMAT_NV12` |

SDK açıkça shader'larının tone mapping sonrası LDR ve HDR içeriği işlediğini ve keskinleştirmenin
gürültüyü güçlendirdiğini belirtiyor — film grain ölçekleyiciden *sonra*, motion blur gibi düşük
geçiren efektler *önce* uygulanmalı. Bir masaüstü hattı için bu çoğunlukla ekranda video olduğunda
önemli.

Kaynaklar: [NVIDIAImageScaling README](https://github.com/NVIDIAGameWorks/NVIDIAImageScaling/blob/main/README.md),
[NVIDIA Image Scaling](https://developer.nvidia.com/rtx/image-scaling).

### Birinci parti filtreler

Ucuz, öngörülebilir ve öğrenilmiş bir filtrenin yanlış seçim olduğu durumlar için faydalı:

| Filtre | Kullanım |
|---|---|
| **Lanczos** | 1366×768 → 1920×1080 gibi tam sayı olmayan oranlar için en yüksek kaliteli genel amaçlı resampling. Anti-ringing clamp ile halkalanma yönetilebilir. |
| **Bicubic** (Catmull-Rom, Mitchell, B-Spline) | Lanczos'tan daha yumuşak, daha az artefakt. Arayüz ağırlıklı içerik için güvenli bir varsayılan. |
| **Bilinear + CAS** | En ucuz faydalı kombinasyon. Ölçek için bilinear, kenar tanımını geri kazanmak için Contrast Adaptive Sharpening. |
| **Nearest / integer** | Yalnızca tam sayı katları için; varsayılan hedefimiz tam sayı değil. |

### Değerlendirme aşamasında

Anime4K, FSRCNNX, NNEDI3, ACNet ve benzeri sinir ağı filtreleri HLSL implementasyonları olarak
mevcut ve doğru içerikte çarpıcı sonuçlar üretebiliyorlar. V1 planında **değiller**: her birinin
kendi lisansı, kendi performans profili ve fotoğrafik veya arayüz içeriğinde kendi başarısızlık
modları var. Çekirdek hat ölçüldükten sonra olası bir V3 eklemesi.

## Kullanılamayan upscaler'lar

| Teknoloji | Burada neden kullanılamıyor |
|---|---|
| **FSR 2 / FSR 3 / FSR 3.1** | Temporal upscaler'lar. Renderer'dan motion vector, depth buffer ve jitter gerektirirler. MIT lisanslılar, ama yakalanmış bir framebuffer için yapısal olarak kullanılamazlar. |
| **DLSS** | NVIDIA'nın NGX SDK'sını ve render motorunun içinde entegrasyonu gerektirir. Genel bir görüntü filtresi olarak sunulmuyor. |
| **Intel XeSS** | Yüksek kaliteli modlar motion vector ve motor entegrasyonu gerektiriyor; DP4a fallback yolu da hâlâ bir temporal upscaler. |
| **NVIDIA RTX Video Super Resolution** | Video'ya özel bir hat (tarayıcı ve medya oynatıcı entegrasyonu, kısıtlı SDK), genel amaçlı bir masaüstü filtresi değil. |
| **GPU sürücüsü integer scaling** | Yalnızca tam sayıdan tam sayıya. 1366×768 → 1920×1080 **1.40625×**, tam sayı bir katsayı değil, dolayısıyla varsayılan hedefi ifade edemiyor. Tam sayı ilişkisi olan yerde (960×540 → 1920×1080) nearest-neighbour zaten birinci parti filtre listesinde mevcut. |

## Lisanslama

Bu bölüm var çünkü algoritmaların kendisinden çok implementasyonu kısıtlıyor.

### Kural

DisplayBoost **MIT lisanslı**. Ağaca yalnızca MIT altında yeniden dağıtılabilen kod — veya açıkça
ayrılmış ve doğru şekilde atıf yapılmış kod — girebilir. Pratikte:

| Kaynak | Lisans | Kullanılabilir mi? |
|---|---|---|
| AMD `FidelityFX-FSR` (`ffx_fsr1.h`) | **MIT** | ✅ Alın, telif bildirimini koruyun |
| AMD FidelityFX SDK (FSR 1 tekniği) | **MIT** | ✅ Aynı |
| NVIDIA `NVIDIAImageScaling` SDK | **MIT** | ✅ Alın, bildirimi koruyun |
| Bu proje için yazılan birinci parti HLSL | MIT | ✅ |
| `microsoft/Windows-driver-samples` (`video/IndirectDisplay`) | **MS-PL** | ⚠️ Aşağıya bakın |
| **Magpie** (Blinue/Magpie) | **GPL-3.0** | ❌ **Hiçbir biçimde kopyalanamaz** |
| Special K | Özel, source-available | ❌ MIT dağıtımıyla uyumlu değil |

Kaynaklar: [NVIDIAImageScaling README](https://github.com/NVIDIAGameWorks/NVIDIAImageScaling/blob/main/README.md),
[Magpie](https://github.com/Blinue/Magpie),
[Windows-driver-samples LICENSE](https://github.com/microsoft/Windows-driver-samples/blob/main/LICENSE).

### Magpie tuzağı

Magpie, Windows'ta yakalama ve ölçeklemenin en kapsamlı açık incelemesi ve FSR, NIS, Anime4K,
FSRCNNX, NNEDI3, Lanczos, CAS ve daha fazlasının HLSL portlarını içeriyor. **GPL-3.0.**

Magpie'den bir shader dosyasını MIT bir projeye kopyalamak lisans ihlalidir; algoritmanın üst
kaynağı MIT olsa bile — çünkü *dosya* GPL altında dağıtılan bir Magpie katkısıdır. Doğru yaklaşım
FSR 1'i GPUOpen'dan, NIS'i NVIDIA GameWorks'ten almak ve Magpie'yi kesinlikle mimari ve problem
çözme referansı olarak kullanmaktır.

Bu, etrafından dolaşılacak bir formalite değil. Gelecekte hiçbir katkıcının yanlışlıkla bu hatayı
yapmaması için burada belgelenmiştir.

### Sürücü için MS-PL sorusu

Microsoft Indirect Display Driver örneği — herhangi bir IddCx sanal ekranı için kanonik başlangıç
noktası — **Microsoft Public License (MS-PL)** altında, MIT değil. MS-PL izin vericidir ve
OSI onaylıdır, ama belirli bir koşulu var:

> Yazılımın herhangi bir bölümünü kaynak kod biçiminde dağıtırsanız, bunu yalnızca bu lisans
> altında, dağıtımınızla birlikte lisansın tam bir kopyasını ekleyerek yapabilirsiniz.

Tek lisanslı bir repo için pratik sonuç: **Microsoft örneğinden türetilmiş sürücü kaynağı MS-PL
altında kalmak zorunda olurdu** ve repo karma lisanslı hale gelirdi — uygulama için MIT, türetilmiş
sürücü dosyaları için MS-PL. Bu yasal ve yaygın, ama açık olmak zorunda; dizin başına lisans
dosyaları ve README'de bir not gerektirir.

İki dürüst seçenek var ve proje henüz aralarında seçim yapmadı:

1. **Örnekten türetin ve karma lisansı kabul edin.** Daha hızlı, daha iyi test edilmiş kod ve
   IddCx programlama modeli üzerine çalışılmış bir örneğin gerçek değeri var.
2. **Sürücüyü belgelenmiş IddCx API'sine karşı sıfırdan yazın.** API'nin kendisi Microsoft
   Learn'de belgelenmiştir ve örneğin lisansı kapsamında değildir. Daha yavaş ve daha riskli, ama
   repo tartışmasız MIT kalır.

Bu, [06 — Yol haritası](06-yol-haritasi.md) içinde bir karar noktası ve V2 başlamadan önce
netleşmeli.

## Önerilen varsayılanlar

| Ayar | Seçim | Gerekçe |
|---|---|---|
| Varsayılan filtre | **FSR 1 (EASU + RCAS)** | MIT, GPU bağımsız, tam bu tür bir giriş için tasarlanmış ve en iyi belgelenmiş spatial seçenek |
| Alternatif | **NVIDIA NIS** | MIT, tek geçişte ölçekleme artı keskinleştirme, tam sayı olmayan oranlarda güçlü ve V1'de FSR 1 ile karşılaştırmaya değer |
| Arayüz / metin modu | **Bicubic** veya hafif keskinleştirmeli Lanczos | FSR 1 ve NIS oyun görüntüsü için ayarlanmış; metinde aşırı keskin görünebilirler |
| Keskinleştirme | Açılıp kapatılabilir, arayüz modunda varsayılan kapalı | Keskinleştirme artefaktları metinde oyundan çok daha rahatsız edici |
| Otomatik mod | İçeriğe göre filtre seç | V3'e ertelendi, dayanacak ölçülmüş veri olduğunda |

V1 prototipi tam olarak FSR 1, NIS ve Lanczos'u 1366×768 → 1920×1080'de, hem oyun hem masaüstü
içeriğinde birbirine karşı ölçmek ve rakamları yayınlamak için var.

## Okumaya devam

- [02 — Yakalama ve sunum](02-yakalama-ve-sunum.md) — bu geçişlerin hattaki yeri
- [04 — Benzer projeler](04-benzer-projeler.md) — mevcut araçlar filtrelerini nasıl seçiyor
- [07 — Kaynaklar](07-kaynaklar.md) — bu dokümanın arkasındaki kaynaklar
