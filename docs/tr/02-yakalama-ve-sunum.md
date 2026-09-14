# 02 — Yakalama ve sunum

> [English](../02-capture-and-present.md) | **Türkçe**

Bu doküman DisplayBoost'un kullanıcı modu yarısını kapsıyor: kareleri sanal ekrandan çıkarmak,
upscale etmek ve platformun izin verdiği en düşük gecikmeyle fiziksel monitöre göndermek.

Diğer her şeyi belirleyen iki tasarım sorusu var:

1. **Kareler nereden geliyor?** Sanal ekranın çıktısını okuyan bir yakalama API'si mi, yoksa
   IddCx sürücüsünün kendi swapchain tamponlarını bir yere teslim etmesi mi?
2. **Üç kare gecikme eklemeden monitöre nasıl ulaşıyorlar?** Sunum yolu, bu projenin
   kullanılabilir olup olmadığını belirliyor.

## Yakalama yöntemlerinin karşılaştırması

| Yöntem | Minimum OS | Kapsam | Model | İmleç | Notlar |
|---|---|---|---|---|---|
| **DXGI Desktop Duplication** (DDA) | Windows 8, WDDM 1.2 | Tüm monitör | Polling (`AcquireNextFrame`) | Kareye gömülü değil, ayrı pointer verisi olarak döner | En düşük seviye, tam kontrol. Mod değişimlerinde ve uygulamanın masaüstünden uzaklaşan her geçişinde geçersiz olur. |
| **Windows.Graphics.Capture** (WGC) | Windows 10 1903 | Pencere veya monitör | Event-driven, kareleri bir `Direct3D11CaptureFramePool`'a teslim eder | İsteğe bağlı, `IsCursorCaptureEnabled` ile | DDA ile aynı altyapı üzerine kurulu. Modern, GPU ve mod değişimlerinde daha iyi davranıyor. |
| **DWM shared surface** (`DwmGetDxSharedSurface`) | Tümü | Tüm masaüstü | Polling | Yakalanmaz | Belgelenmemiş; Magpie'nin kare kaynaklarından biri. Microsoft değiştirene kadar çalışır. |
| **GDI `BitBlt`** | Tümü | Pencere veya ekran | Polling | Yakalanmaz | CPU'ya bağlı, yavaş, compositor ile senkronize değil. Sadece uyumluluk fallback'i. |
| **IddCx sürücüsünün içinde** | Windows 10 1607+ | Sanal ekran | Sürücü callback'i, kopya yok | Sürücü karar verir | Sıfır ekstra yakalama adımı — aşağıya bakın. |

Kaynaklar: [IDXGIOutputDuplication](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_2/nn-dxgi1_2-idxgioutputduplication),
[Magpie — Frame Capture System](https://deepwiki.com/Blinue/Magpie/3.7-frame-capture-system).

### DDA'nın geçersizleşme problemi

`IDXGIOutputDuplication` şu durumlarda geçersiz olur ve `DXGI_ERROR_ACCESS_LOST` döndürür:

- Ekran modu değiştiğinde.
- İşletim sistemi farklı bir masaüstüne geçtiğinde — **UAC istemleri ve giriş ekranı için
  kullanılan secure desktop dahil.**
- Başka bir tam ekran DirectX veya OpenGL uygulaması output'un özel kontrolünü aldığında.

Belgelenen kurtarma yolu, duplication arayüzünü bırakıp yenisini oluşturmaktır. Pratikte bu,
yakalama oturumunun her an parçalanıp yeniden kurulabilen bir durum makinesi olması gerektiği
anlamına gelir; sabit bir output varsayan bir döngü değil. Bu sonradan eklenen bir hata yönetimi
değil, birinci sınıf bir tasarım kısıtı.

Kaynaklar: [IDXGIOutputDuplication remarks](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_2/nn-dxgi1_2-idxgioutputduplication),
[Capturing the Windows Secure Desktop](https://etducky.com/blog/windows-uac-secure-desktop-capture).

### Sürücünün içinden yakalama

Bir IddCx indirect display driver, oluşturulmuş masaüstü görüntüsünü doğrudan alır. İşletim
sistemi sürücüye `EvtIddCxMonitorAssignSwapChain` üzerinden bir swapchain atar ve sürücü
`EvtIddCxSwapChainReleaseAndAcquireBuffer` içinde `IddCxSwapChainReleaseAndAcquireBuffer`
çağırarak mevcut kareyi bir DXGI kaynağı olarak alır, ardından
`IddCxSwapChainFinishedProcessingFrame` ile tamamlandığını bildirir.

Bu teorik olarak mümkün olan en ucuz yakalama yolu — duplication arayüzü yok, ayrı kopya yok,
geçersizleşme yok. Zorluk sonrasında: sürücü **Session 0**'da, pencereleme olmadan çalışıyor;
oysa fiziksel monitöre sunum yapmak etkileşimli masaüstünde bir pencere gerektiriyor. Upscale
edilmiş dokuyu sürücüden sunum yapan uygulamaya taşımak, paylaşılan bir doku veya paylaşılan
bellek yüzeyi ve bunun gerektirdiği senkronizasyon anlamına geliyor.

Bu V2'ye bilinçli olarak ertelenmiş bir tasarım kararı. V1, sunum yolunu ve ölçüm metodolojisini
bir sürücü devreye girmeden önce doğrulamak için sıradan yakalamayı kullanıyor.

## Sunum yolu

### Flip model kullanın

Modern değerlendirmelerin hepsi şuradan çıkıyor: eski bitblt modeliyle değil, flip-model bir
swapchain (`DXGI_SWAP_EFFECT_FLIP_DISCARD`) ile sunum yapın. Pencere modu sunumu tam ekran
exclusive ile rekabet edebilir kılan ve multiplane overlay'i mümkün kılan şey flip model.

Flip model altında:

- **Independent flip** hızlı yoldur. Swapchain'in tamponu compositor'e uğramadan doğrudan ekrana
  gider; borderless bir pencerede tam ekrana yakın gecikme sağlar. `SetFullScreenState(TRUE)`,
  borderless tam ekran bir pencere ve windowed olmayan bir flip-model swapchain gerektirir.
- **Composed flip** fallback'tir. Compositor'ü yola geri sokan herhangi bir şey ekstra bir
  kompozisyon adımı ekler. Bildirilen ceza değişkenlik gösteriyor; bir geliştirici raporu etkilenen
  sistemlerde farkı yaklaşık **25–30 ms** olarak veriyor. Bu rakamı **anekdot** olarak alın — tek
  bir rapor, ölçülmüş bir benchmark değil. Projenin kendi rakamları V1'den gelecek.

Kaynaklar: [For best performance, use DXGI flip model](https://learn.microsoft.com/en-us/windows/win32/direct3ddxgi/for-best-performance--use-dxgi-flip-model),
[NVIDIA — Advanced API Performance: Swap Chains](https://developer.nvidia.com/blog/advanced-api-performance-swap-chains/),
[Stack Overflow: enforcing independent flip](https://stackoverflow.com/questions/72558096/enforce-use-of-independent-flip-mode-with-dxgi-flip-swapchain).

### Gecikmeyi daha da düşürmek

`DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT` artı `SetMaximumFrameLatency(1)`, independent
flip altında **bir kare gecikmeye** ulaştığı ve independent flip mevcut olmadığında düzgün şekilde
geri düştüğü belgelenmiştir. Bloklayan bir present yerine waitable object kullanmak, CPU'nun GPU'nun
önünde iş kuyruklamasını da engeller.

Kaynak: [For best performance, use DXGI flip model](https://learn.microsoft.com/en-us/windows/win32/direct3ddxgi/for-best-performance--use-dxgi-flip-model).

### VRR ve tearing ile ödünleşim

Vsync ile sunum tearing'i engeller ama sunum hızını monitörün yenileme hızına bağlar.
`DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING` ile sunum zorunlu beklemeyi ortadan kaldırır ama tearing
üretir. Genel amaçlı bir ölçekleyici için ikisi de bariz şekilde doğru değil ve ikisi de değişken
yenileme hızıyla kötü etkileşiyor: ekstra bir kompozisyon katmanı, ekranın değişken yenileme
durumuna hiç girmemesine sık sık neden oluyor. Bu, burada çözülmek yerine
[05 — Riskler ve sınırlar](05-riskler-ve-sinirlar.md) içinde açık risk olarak belgelenmiş durumda.

## Belirli bir monitöre sunum yapmak

Sunum yapan uygulama, fiziksel monitörü `DXGI_OUTPUT_DESC` cihaz adından bulmak için adaptörleri
ve output'ları numaralandırıp ardından swapchain'i o adaptör/output eşleşmesi üzerinde
oluşturmalıdır. Açıkça numaralandırıp bağlamak, tam ekran borderless bir pencerenin yanlış ekrana
veya sanal ekranın kendisine düşmesi şeklindeki yaygın hatayı önler.

## Adaptörler arası: en kötü durum

Sanal ekran bir GPU'da oluşturulup fiziksel monitör başka bir GPU'ya bağlıysa — MUX'lu bir
dizüstünde normal durum — her karenin adaptörler arası geçmesi gerekir. Modern Windows'ta bu,
bir dokuyu paylaşarak yapılır (`IDXGIResource1::CreateSharedHandle` ile keyed mutex, veya
`D3D11_RESOURCE_MISC_SHARED_NTHANDLE`) ve diğer cihazda açarak.

Maliyet gerçek: veri PCIe üzerinden, en kötü durumda sistem belleğinden geçiyor. 60 Hz'de
1920×1080 32-bit bir kare için bu, ek yükten önce kabaca **500 MB/s** — **tahmin**, ölçüm değil.
Kare başına tek bir adaptörler arası kopya, upscale'in kazandırdığı her şeyi kolayca aşabilir.

Çözüm, iki tarafı da aynı adaptöre sabitlemek. Bir IddCx sürücüsüne karelerini hangi adaptörün
işleyeceği `IddCxAdapterSetRenderAdapter` ile söylenebilir; topluluk sürücüleri hedef adaptörü
isim eşleştirmek yerine PCI bus numarasından kararlı bir `LUID` çözerek buluyor. DisplayBoost'un
izlemeyi planladığı yaklaşım bu ve hibrit sistemler ölçülene kadar düşürülmüş yapılandırma olarak
kalıyor.

Kaynaklar: [IddCx versions](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/iddcx-versions),
[Virtual-Display-Driver changelog](https://github.com/VirtualDrivers/Virtual-Display-Driver).

## İmleç işleme

Kullanıcı deneyimini yapan ya da bozan problem bu ve hafife alınması çok kolay.

Desktop Duplication imleci **kareye gömmez**. Pointer şeklini ve konumunu ayrı veri olarak döndürür
ve imleci çağıranın birleştirmesi gerekir. Windows.Graphics.Capture imleci dahil edebilir, ama o
zaman imleç her şeyle birlikte upscale edilir.

Doğru yapılması gereken üç şey var:

1. **İmleci giriş çözünürlüğünde değil, çıkış çözünürlüğünde birleştirin.** İmleç 1366×768 kareye
   birleştirilip sonra upscale edilirse bulanıklaşır ve boyutu biraz yanlış olur. En son, 1920×1080
   üzerinde çizmek onu piksel hassasiyetinde tutar.
2. **Koordinat uzayını eşleyin.** Pointer fiziksel monitör üzerinde native çözünürlükte hareket
   eder. Yakalanan masaüstü sanal ekranın koordinat uzayında yaşar. Ölçekleyici monitörü kaplıyorsa
   eşleme basit bir ölçek katsayısıdır; yerleşim temiz bir tam ekran ayna değilse değildir.
3. **İmlece bir kare gecikme eklemeyin.** 60 Hz'de fareyi bir kare bile geriden gelen bir imleç
   fark edilir. İmleci upscale geçişinden sonra, son adım olarak birleştirmek bunu yönetilebilir
   kılan şey.

Magpie'nin `CursorManager`'ı bu problemin en kapsamlı açık ele alınışı: kaynak-ölçeklenmiş
eşlemesiyle koordinat dönüşümü, fare hissinin tutarlı kalması için `SPI_SETMOUSESPEED` ile hız
ayarı ve dokunmatik giriş için ayrı "touch hole" pencereleri. GPL-3.0 olduğu için incelenecek ama
kopyalanmayacak bir referans — lisans gerekçesi için
[03 — Ölçekleme](03-olcekleme.md).

Kaynak: [Magpie — Cursor Mapping and Multi-Monitor Support](https://deepwiki.com/Blinue/Magpie/2.5-cursor-mapping-and-multi-monitor-support).

## Gecikme bütçesi

Aşağıdaki maliyetin şekli, ölçümü değil. İçindeki her rakam V1'in benchmark'ıyla değiştirilecek
bir **tahmin**.

| Aşama | Maliyet | Notlar |
|---|---|---|
| Kare üretimi | 1 kare | DWM, sanal ekranın yenileme hızında oluşturur |
| Yakalama | < 1 ms | GPU tarafı; paylaşılan bir doku okuması artı senkronizasyon |
| Upscale geçişi | ~0.2–2 ms | Tek compute geçişi; filtrenin ünüyle değil çıkış boyutuyla ölçeklenir |
| İmleç birleştirme | < 0.2 ms | Çıkış çözünürlüğünde küçük bir dokulu dörtgen |
| Sunum | 1–2 kare | Waitable object ile independent flip'te 1 kare; composed flip'te belirgin şekilde daha fazla |
| **Toplam** | **~2–3 kare** | 60 Hz'de kabaca 33–50 ms |

Karşılaştırma için bu, bir frame generation özelliğinin tasarım gereği eklediği gecikmeyle aynı
mertebede ve uygulamanın zaten sahip olduğu gecikmeye ekleniyor. Rekabetçi oyun için DisplayBoost
kullanmaya karşı en güçlü argüman bu ve projenin kendini kalite özelliği olarak belgelemesinin
nedeni de bu.

## Başarısızlık modları ve kurtarma

| Olay | Etkisi | Gereken tepki |
|---|---|---|
| Mod değişimi (çözünürlük veya yenileme) | Duplication geçersiz | Duplication arayüzünü yeniden oluşturun; eskisinin çalıştığını varsaymayın |
| Secure desktop (UAC, kilit, Ctrl+Alt+Del) | `DXGI_ERROR_ACCESS_LOST` | Bırakıp yeniden alın; fiziksel ekran secure desktop'ı zaten gösteriyor olmalı |
| Monitör takma/çıkarma veya geliş/gidiş | Output listesi değişir | Adaptörleri ve output'ları yeniden numaralandırın, swapchain'i yeniden kurun |
| DPMS uyku / monitör kapanması | Sunum durur | Hattı duraklatın; dönmeyin |
| TDR (GPU sıfırlaması) | Cihaz kaldırıldı | Tam cihaz yeniden oluşturma; bu kare başına kurtarılabilir bir hata değil |
| Sanal ekran kaldırıldı | Yakalayacak bir şey yok | Passthrough'a düşün ve net bir mesaj gösterin |

Kullanıcının tek görünür ekranını kaplayıp sonra başarısız olan bir ölçekleyici gerçek zarar
vermiştir. Bu yolların her biri için tanımlı bir kurtarma davranışı olmalı ve uygulama tamamen
yoldan çekilebilmeli.

## DisplayBoost için anlamları

1. **V1 hiç sürücü kullanmamalı.** Mevcut ekranı yakala, upscale et, aynı ekranda sun. Bu hattı
   doğrular, gecikme rakamlarını üretir ve kimseyi kilitleme riski taşımaz.
2. **Muhtemel varsayılan yakalama yolu WGC**, frame timestamp'leri veya dirty-region verisi
   faydalı olduğu yerde alt seviye seçenek olarak DDA ile birlikte. WGC'nin event-driven modeli,
   altındaki ekran yığını değişebilen bir hat için daha uygun.
3. **Independent flip bir gereksinim, güzel bir özellik değil.** Sunum yolu ona ulaşamıyorsa,
   gecikme cezası hattın geri kalanının tüm bütçesinden büyük olur.
4. **İmleç işleme kendi başına bir tasarım fazı**, sona eklenen bir detay değil.
5. **Adaptörler arası durum tasarımla ortadan kaldırılmalı, sonra optimize edilmemeli.** Sanal
   ekranın render adaptörünü baştan hedef monitörün adaptörüne sabitleyin.

## Okumaya devam

- [01 — Sanal ekran sürücüsü](01-sanal-ekran-surucusu.md) — karelerin kaynağı
- [03 — Ölçekleme](03-olcekleme.md) — yakalama ile sunum arasında ne oluyor
- [05 — Riskler ve sınırlar](05-riskler-ve-sinirlar.md) — tam risk kaydı
