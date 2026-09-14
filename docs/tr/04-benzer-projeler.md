# 04 — Benzer projeler

> [English](../04-prior-art.md) | **Türkçe**

DisplayBoost'un her bileşeni bir yerde zaten var. Var olmayan şey, spesifik kombinasyon:
Windows'un render ettiğini düşüren **tüm masaüstü, ekran düzeyinde** bir ölçekleme zinciri.
Komşuların tam olarak nasıl farklılaştığını bilmek, bu projenin ne kattığı konusunda dürüst
kalmasını sağlayan şey.

## Araçlar

### Magpie — `Blinue/Magpie`

| | |
|---|---|
| **Lisans** | **GPL-3.0** |
| **Popülerlik** | ~14.9k yıldız, ~666 fork |
| **Yığın** | C++/WinRT, Direct3D 11, WinUI |
| **Gereksinimler** | Windows 10 v1903+, DirectX feature level 11 |
| **Ne olduğu** | MagpieFX shader formatı ve geniş bir efekt kütüphanesi olan genel amaçlı bir **pencere** upscaler'ı: FSR, NIS, Anime4K, FSRCNNX, NNEDI3, ACNet, CRT shader'ları, SMAA/FXAA, CAS, Lanczos, bicubic, bilinear, nearest |

**İyi yaptığı şey.** Magpie, Windows'ta yakalama ve ölçekleme probleminin en kapsamlı açık
ele alınışı. Kare kaynağı soyutlaması (`GraphicsCaptureFrameSource`,
`DesktopDuplicationFrameSource`, `GDIFrameSource`, `DwmSharedSurfaceFrameSource`) platformun
değişkenliğini yönetmek için iyi bir model. Bir compute shader ile yaptığı duplicate-frame tespiti
(`DuplicateFrameCS.hlsl`), değişmeyen içeriği yeniden render etmemek için zarif bir numara.
`CursorManager`'ı imleç eşlemesi konusundaki en ciddi açık girişim.

**DisplayBoost nasıl farklılaşıyor.** Magpie **kendi çözünürlüğünde zaten render etmiş bir
pencereyi büyütür**. Piksellerin nasıl gerildiğini değiştirir, kaç tane render edildiğini asla.
Dolayısıyla hiçbir render maliyeti kazandırmaz — bir kalite aracıdır ve bunu dürüstçe söyler.
DisplayBoost, masaüstünün hangi çözünürlükte *oluşturulduğunu* düşürür ve (koşullu) kazanç buradan
gelir.

**Ondan aldığımız.** Sadece mimari dersler. Lisans hiçbir şeyin kopyalanmasına izin vermiyor ve
özellikle shader dosyaları, üst kaynak algoritması MIT olsa bile GPL-3.0 katkılarıdır. Bkz.
[03 — Ölçekleme](03-olcekleme.md).

### Lossless Scaling

| | |
|---|---|
| **Lisans** | Kapalı kaynak, Steam'de satılıyor (yaklaşık US$7) |
| **Ne olduğu** | Yakalanan bir pencere için harici ölçekleme (LS1, FSR 1, NIS, integer), artı **LSFG** frame generation |

**Nasıl çalışıyor.** Bir pencereyi veya tam ekran bir uygulamayı yakalar ve ölçeklenmiş olarak
yeniden sunar. Uygulamanın **windowed veya borderless modda** çalışmasını gerektirir —
rehberler exclusive fullscreen'in çalışmadığını açıkça söylüyor. Frame generation, gerçek kareler
arasına sentetik kareler ekler; algılanan akıcılığı artırır, render hızını artırmaz ve tasarım
gereği gecikme ekler.

**DisplayBoost nasıl farklılaşıyor.** Lossless Scaling uygulama bazlıdır ve uygulamanın render
çözünürlüğünü düşürmez; bunu kullanıcı kendisi oyun içinde yapar. DisplayBoost ekran düzeyindedir.
Frame generation açıkça DisplayBoost'un kapsamı dışında — farklı bir problem, farklı bir gecikme
bütçesi.

**Bize söylediği.** Kullanıcıların bu kategorideki bir araç için para ödeyeceğini ve uygulama
bazlı modelin yerleşik model olduğunu. Ayrıca yakalama gecikmesi ile frame generation
gecikmesinin *birleşiminin* zaten bilinen bir şikâyet olduğunu söylüyor; bu da ikisini birden
ekleyen her hat için bir uyarı.

### Windows Automatic Super Resolution (Auto SR)

| | |
|---|---|
| **Bulunabilirlik** | Windows 11 24H2+, Copilot+ PC'ler ve ROG Xbox Ally X |
| **Donanım** | Bir **NPU** gerektiriyor; çıkışta sıradan x86 oyun donanımında mevcut değil |
| **Kapsam** | DirectX 11 ve 12 oyunları, başlık bazında isteğe bağlı |

**Ne olduğu.** Microsoft'un işletim sistemi düzeyi super resolution'ı. Oyun daha düşük bir dahili
çözünürlükte render eder ve Auto SR onu geri getirir — DisplayBoost'un hedefine bugün sevk edilen
en yakın kavramsal şey.

**DisplayBoost nasıl farklılaşıyor.** Üç şekilde ve üçü de anlamaya değer:

1. **NPU kullanıyor**, GPU değil. DisplayBoost tasarım gereği yalnızca GPU ve dolayısıyla Auto
   SR'ın dokunamadığı donanımda çalışıyor.
2. **Compositor'ün içinde.** Sanal ekran yok, yakalama kopyası yok, ekstra sunum yok. Ek yükü
   yapısal olarak DisplayBoost'un ulaşabileceğinden düşük.
3. **Kısıtlı.** HDR desteklenmiyor, DirectX 9, OpenGL ve Vulkan desteklenmiyor ve ince HUD ve
   arayüz metninin çok düşük dahili çözünürlüklerde zarar gördüğü biliniyor.

**Bize söylediği.** Microsoft talebi doğruladı ve tam olarak stack içi yaklaşımı seçti, çünkü
yakalama tabanlı yaklaşımın gizlenmesi zor maliyetleri var. Bu, projenin kendi dürüst
konumlandırması için en güçlü kanıt: genel durum zor ve değer ham performanstan çok kapsamada.

### AMD Radeon Super Resolution (RSR)

| | |
|---|---|
| **Ne olduğu** | Herhangi bir tam ekran oyunun present yolu içinde uygulanan sürücü düzeyi **FSR 1 (EASU)** |
| **Gereksinimler** | Tam ekran, oyunun ekranın native çözünürlüğünün altında render etmesi |

**Burada neden önemli.** RSR, DisplayBoost'a en yakın işlevsel rakip ve kesinlikle daha ucuz:
sanal ekran yok, yakalama kopyası yok, ekstra kare yok. Aynı düşük çözünürlükten native'e numarasını
yapıyor ve kullanıcı bunun için bir sürücü kurmuyor.

**DisplayBoost nasıl farklılaşıyor.** RSR **tam ekran oyunlar** için devreye giriyor, başka hiçbir
şey için değil. Eski bir pencere modu uygulamaya, bir tarayıcıya veya masaüstünün kendisine asla
yardım etmeyecek. DisplayBoost'un hedeflediği boşluk bu ve "daha iyi performans"ın ima edeceğinden
daha dar bir boşluk.

### NVIDIA özellikleri

| Özellik | Ne yapıyor | İlgisi |
|---|---|---|
| **NVIDIA Image Scaling (sürücü özelliği)** | Sürücü düzeyi NIS spatial ölçekleme ve keskinleştirme | RSR ile aynı koşullarda doğrudan rakip |
| **DSR / DLDSR** | Native'in **üstünde** render edip aşağı örnekler — supersampling | Ters yön; performansla ilgisiz |
| **RTX Video Super Resolution** | Yalnızca video oynatımı için Tensor çekirdeği ölçekleme | Yakalanan bir yüzeyin GPU ile ölçeklenmesinin ölçekte pratik olduğunu doğruluyor, ama genel bir masaüstü filtresi değil |
| **Integer scaling** | Tam sayı katsayılarla nearest-neighbour | 1366×768 → 1920×1080 ifade edemiyor; bu 1.40625× |

### Bilmeye değer diğerleri

| Araç | Ne yapıyor | Bize neden önemli |
|---|---|---|
| **Intel XeSS** | DP4a fallback'i olan oyun bazlı temporal upscaler | Motor entegrasyonu gerektiriyor; genel bir filtre değil |
| **Special K** | Enjekte edilen oyun çerçevesi: flip-model zorlama, frame limiting, HDR retrofit, FSR enjeksiyonu | Enjeksiyon açıkça DisplayBoost'un tasarımı dışında ve anti-cheat riski taşıyor |
| **ReShade** | D3D9–12, OpenGL ve Vulkan için post-process shader enjeksiyonu | Shader tabanlı ölçeklemenin post-process olarak çalıştığını kanıtlıyor; yine de uygulamanın düşük çözünürlükte kendini render etmesi gerekiyor |
| **Borderless Gaming** | Pencere modu oyunları borderless tam ekrana zorlar | Ölçekleyici değil, ama faydalı bir öncül — birçok oyunun yakalama tabanlı herhangi bir ölçekleyiciden önce buna ihtiyacı var |
| **Gamescope (Linux/SteamOS)** | Compositor düzeyinde FSR 1 ile ölçekleme | Dünyada DisplayBoost'a mimari olarak en yakın şey: render çözünürlüğünü *compositor'de* düşürüyor. Fikri için incelenmeye değer, kodu için değil. |

## Konumlandırma

| Boyut | Magpie / Lossless Scaling | RSR / NIS (sürücü) | Auto SR | **DisplayBoost** |
|---|---|---|---|---|
| Yakalama kapsamı | Tek pencere | Oyunun present çağrısı | Oyunun swapchain'i, compositor içinde | **Tüm masaüstü** |
| Render çözünürlüğünü düşürür | Hayır | Evet | Evet | **Evet** |
| Uygulama başına destek gerektirir | Sadece yakalama desteği | Sadece tam ekran | Başlık bazında isteğe bağlı | **Hayır** |
| Kare başına ekstra kopya | Bir yakalama, bir sunum | Yok | Yok | **Bir yakalama, bir upscale, bir sunum** |
| Donanım gereksinimi | Herhangi bir D3D11 GPU | AMD / NVIDIA GPU | Copilot+ NPU | **Herhangi bir D3D11 GPU** |
| Ekran sürücüsü gerekir | Hayır | Hayır | Hayır | **Evet** |
| Eski sabit çözünürlüklü yazılımda çalışır | Kısmen | Hayır | Hayır | **Evet** |
| Gecikme ekler | Evet | Minimal | Bir miktar | **Evet, 1–3 kare** |

Son üç satırı birlikte okuyun, ödünleşim net: DisplayBoost, hiçbir alternatifin sağlamadığı
kapsama karşılığında bir sürücü kurulumu ve ek gecikme ödüyor.

## DisplayBoost'un gerçekten kazanabileceği yerler

1. **Asla upscaler'a kavuşmayacak yazılımlar.** Eski sabit çözünürlüklü oyunlar, eski CAD ve
   kurumsal araçlar, ölçekleme seçeneği olmayan emülatörler ve geliştiricisi tarafından terk
   edilmiş her şey.
2. **Tüm masaüstü kapsaması.** Amaç "her şeyi çizmek daha ucuz olsun" olduğunda alternatifler
   hiçbir mekanizma sunmuyor.
3. **Monitörün ölçekleyicisinden daha iyi filtre kalitesi.** Bir monitörün 768p'yi 1080p'ye
   germesi, ekran denetleyicisindeki hangi ucuz ölçekleyici varsa onu kullanır. Düzgün
   keskinleştirme kontrolüne sahip FSR 1, NIS veya Lanczos belirgin şekilde daha iyidir — ve bu,
   performans kazanılıp kazanılmadığından bağımsız olarak doğrudur.
4. **Deterministik, incelenebilir davranış.** Enjeksiyon yok, hook yok, oyun başına yama yok. Hat
   görünür ve maliyetleri ölçülebilir.

## DisplayBoost'un rekabet edemeyeceği yerler

1. **Modern bir oyunda frame rate.** Oyun içi upscaler her zaman kazanır: motion vector'ları ve
   depth'i var, yakalama için ödeme yapmıyor ve bir kare eklemiyor.
2. **Genel olarak tam ekran oyunlar.** Exclusive fullscreen zinciri tamamen atlar.
3. **Korumalı içerik.** HDCP içeriği yakalanamaz.
4. **Secure desktop.** UAC, Ctrl+Alt+Del ve giriş ekranı erişim dışında.

Dördü de [05 — Riskler ve sınırlar](05-riskler-ve-sinirlar.md) içinde belgelenmiştir; çünkü bunları
kurduktan sonra keşfeden bir okuyucu kendini haklı olarak yanıltılmış hisseder.

## Okumaya devam

- [03 — Ölçekleme](03-olcekleme.md) — bu araçların kullandığı filtreler ve lisansları
- [05 — Riskler ve sınırlar](05-riskler-ve-sinirlar.md) — tam risk kaydı
- [07 — Kaynaklar](07-kaynaklar.md) — kaynaklar
