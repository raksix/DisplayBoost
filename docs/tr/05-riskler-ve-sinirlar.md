# 05 — Riskler ve sınırlar

> [English](../05-risks-and-limitations.md) | **Türkçe**

**Bu dokümanı proje hakkında heyecanlanmadan önce okuyun.** README'nin DisplayBoost'u performans
özelliği olarak değil kapsama ve kalite özelliği olarak tanımlamasının nedeni bu ve DisplayBoost'u
değerlendiren herkesin önce bakması gereken liste de bu.

Buradaki hiçbir şey varsayımsal el sallama değil: her madde ya belgelenmiş bir platform kısıtı ya
da mimarinin tasarımın etrafından dolaşmak zorunda olduğu bir sonucu.

## Özet

Her risk aşağıda kendi başlığı altında ayrıntılı olarak ele alınıyor.

| ID | Risk | Önem | Durum |
|---|---|---|---|
| `R-01` | Secure desktop yakalanamaz; olası kilitlenme | 🔴 Kritik | Tasarımla azaltıldı |
| `R-02` | İmleç işleme, eşleme ve gecikme | 🔴 Kritik | Açık — V1'de ele alınacak |
| `R-03` | Net performans sıklıkla sıfır veya negatif | 🔴 Kritik | **Doğası gereği — belgelendi, düzeltilmedi** |
| `R-04` | +1–3 kare gecikme; independent flip kaybı | 🟠 Yüksek | Kısmen azaltıldı |
| `R-05` | DRM korumalı içerik siyah görünür | 🟠 Yüksek | Kabul edilen sınır |
| `R-06` | Hibrit sistemlerde kare başına adaptörler arası kopya | 🟠 Yüksek | Azaltma planlandı |
| `R-07` | 1.40625× oranında metin ve arayüz bulanıklığı | 🟠 Yüksek | Preset planlandı |
| `R-08` | Exclusive fullscreen hattı atlar | 🟡 Orta | Kabul edilen sınır |
| `R-09` | Anti-cheat etkileşimi doğrulanmamış | 🟡 Orta | Açık |
| `R-10` | Topoloji değişimleri yakalama oturumunu bozar | 🟡 Orta | Kurtarma tasarlandı |
| `R-11` | Sürücü imzalama, yönetici hakları, dağıtım | 🟡 Orta | Yol belirlendi |
| `R-12` | HDR ve wide color gamut | 🟡 Orta | V2 sonrasına ertelendi |
| `R-13` | GPU sürücüsü güncellemesinden sonra siyah ekran | 🟡 Orta | Prosedür belgelendi |
| `R-14` | VRR / G-Sync / FreeSync bozulması | 🟡 Orta | Açık |
| `R-15` | Sürücü lisansı: MS-PL mi, MIT mi | 🟡 Orta | Açık karar |
| `R-16` | Görev çubuğunu hangi ekran sahiplenir, pencere yerleşimi | 🟡 Orta | Açık |
| `R-17` | Henüz hiç ölçüm yok | 🟡 Orta | V1 ile ele alınıyor |

---

## R-01 — Secure desktop yakalanamaz

**Önem: kritik. Tüm güvenlik tasarımını belirleyen risk bu.**

UAC istemleri, Ctrl+Alt+Del ve giriş ekranı, kullanıcı modu yakalama API'lerinin ulaşamadığı
**secure desktop** üzerinde çalışır. `IDXGIOutputDuplication`, arayüzlerinin "işletim sistemi
masaüstü görüntüsünü üreten farklı bir bileşene geçtiğinde" geçersiz olduğunu belgeliyor ve tam
bu durumda `DXGI_ERROR_ACCESS_LOST` döndürüyor.

Sonuç siyah bir kareden daha kötü. Sanal ekran *tek* ekran yapılırsa, Windows secure desktop'ı
kimsenin göremediği bir monitörde sunabilir; kullanıcı ise gerçek monitöre bakar — bant içi hiçbir
çıkışı olmayan bir kilitlenme.

**Azaltma (zorunlu, isteğe bağlı değil):**

- Fiziksel monitör **her zaman Windows console display'i olarak kalır**. Sanal ekran hiçbir zaman
  tek ekran olmaz ve hiçbir zaman console display olmaz.
- Uygulama yakalama kaybını algılamalı ve donmuş veya siyah bir görüntü göstermek yerine
  passthrough'a düşmelidir.
- DisplayBoost'u tamamen devre dışı bırakan ve önceki ekran yapılandırmasını geri getiren global
  bir kaçış kısayolu olmalıdır.
- Kaldırma yolu Safe Mode'dan çalışabilmeli ve README'de belgelenmeli, wiki'ye gömülmemelidir.

Kaynaklar: [IDXGIOutputDuplication](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_2/nn-dxgi1_2-idxgioutputduplication),
[Capturing the Windows Secure Desktop with a uiAccess Process](https://etducky.com/blog/windows-uac-secure-desktop-capture).

---

## R-02 — İmleç işleme

**Önem: kritik, çünkü en görünür başarısızlık ve yanlış yapılması en kolay olan.**

Desktop Duplication imleci kareye dahil etmiyor: pointer şeklini ve konumunu ayrı döndürüyor ve
imleci çağıranın birleştirmesi gerekiyor. Windows.Graphics.Capture imleci dahil edebiliyor, ama o
zaman imleç her şeyle birlikte upscale ediliyor — bulanık ve yanlış boyutta bir pointer.

Burada üst üste üç ayrı problem var:

- **Birleştirme konumu.** İmleci düşük çözünürlüklü kareye çizip upscale etmek onu yumuşatır. En
  son, çıkış çözünürlüğünde çizilmesi gerekir.
- **Koordinat eşlemesi.** Pointer fiziksel monitör üzerinde native koordinatlarda hareket eder;
  yakalanan masaüstü sanal ekranın koordinatlarında yaşar. Eşleme yalnızca yerleşim temiz bir tam
  ekran ayna olduğunda basittir.
- **Gecikme.** 60 Hz'de bir kare bile geriden gelen bir imleç fark edilir ve anında rahatsız edici
  olur. Bu, imlecin yakalanan içeriğin parçası olarak değil, sunum yolunun upscale sonrası son
  adımı olarak birleştirilmesini gerektirir.

Magpie'nin `CursorManager`'ı — koordinat dönüşümü, tutarlı fare hissi için `SPI_SETMOUSESPEED`
ayarı ve touch-hole pencereleri — eşleme problemi için en iyi açık referans. GPL-3.0, yani
incelenebilir ama kopyalanamaz.

Kaynak: [Magpie — Cursor Mapping and Multi-Monitor Support](https://deepwiki.com/Blinue/Magpie/2.5-cursor-mapping-and-multi-monitor-support).

---

## R-03 — Net performans sıklıkla negatif

**Önem: kritik, çünkü tüm projenin sezgisel beklentisini çürütüyor.**

DisplayBoost'un bir şeyi hızlandırıp hızlandırmaması tamamen iş yüküne bağlı.

**Ucuzlayan şey.** Piksel başına iş. 1366×768 ≈1.05 MP, 1920×1080 ≈2.07 MP — piksel sayısıyla
ölçeklenen gölgeleme, depth ve raster işlemlerinde neredeyse yarı yarıya.

**Ucuzlamayan şey.** Geri kalan her şey: geometri, tessellation, compute, culling, draw gönderimi
ve tüm CPU tarafı maliyet. Draw-call bound bir iş yükü hiçbir şey kazanmaz.

**Pahalanan şey.** Sanal framebuffer'dan bir yakalama okuması, bir upscale geçişi, ekstra bir
sunum ve eklenen gecikme. İki ekran farklı adaptörlerdeyse kare başına bir de adaptörler arası
kopya — bkz. `R-06`.

**Dürüst sonuç.** Fill-rate bound bir oyunda aritmetik tutabilir. Masaüstü, arayüz ve video için —
piksel başına gölgelemenin ucuz olduğu ve compositor'ün zaten verimli çalıştığı yerlerde — sabit
ek yük kazancı yakalayabilir veya aşabilir. Gerçek kazancın olduğu durumlarda ise sürücü düzeyi
AMD RSR veya NVIDIA NIS bunu zaten present yolunun içinde, sanal ekran olmadan ve yakalama kopyası
olmadan sağlıyor.

**Azaltma: dürüstlük.** Proje bunu README'de ve burada açıkça söylüyor. Performans vaat etmiyor.
Değer önerisi kapsama ve filtre kalitesi ve V1, tartışma yerine rakam üretmek için var.

Kaynaklar: [AMD Radeon Super Resolution](https://www.amd.com/en/products/software/adrenalin/radeon-super-resolution.html),
[TechPowerUp — RSR quality and performance review](https://www.techpowerup.com/review/amd-radeon-super-resolution-rsr/).

---

## R-04 — Eklenen gecikme ve independent flip kaybı

**Önem: yüksek.**

Hat, sanal ekranın kompozisyonu için bir kare, yakalama ve upscale için kabaca bir milisaniye ve
sunumda bir ile iki kare ekliyor — **toplamda yaklaşık 2–3 kare, 60 Hz'de kabaca 33–50 ms
(tahmin, V1'de ölçülecek)**.

Değişken kısım sunum yolu. **Independent flip** düşük gecikmeli yol ve windowed olmayan bir
flip-model swapchain, borderless tam ekran bir pencere ve `SetFullScreenState(TRUE)` gerektiriyor.
Hat bunun yerine **composed flip**'e düşerse ekstra bir kompozisyon adımı ekleniyor; bir geliştirici
raporu farkı yaklaşık 25–30 ms olarak veriyor (**anekdot**, tek kaynak).

**Azaltmalar:**

- Baştan flip model kullanın; bitblt modeli bir sunum yolu asla sevk etmeyin.
- `DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT` ile `SetMaximumFrameLatency(1)` kullanın;
  bu, independent flip altında bir kare gecikmeye ulaştığı belgelenmiştir.
- V1'de gerçek sunum modunu varsaymak yerine ölçün ve tanılama arayüzünde gösterin.
- Gecikmeyi belgeleyin ki kullanıcılar ödünleşimin kendileri için değip değmeyeceğine kendileri
  karar versin.

Kaynaklar: [For best performance, use DXGI flip model](https://learn.microsoft.com/en-us/windows/win32/direct3ddxgi/for-best-performance--use-dxgi-flip-model),
[Enforce use of independent flip mode](https://stackoverflow.com/questions/72558096/enforce-use-of-independent-flip-mode-with-dxgi-flip-swapchain).

---

## R-05 — Korumalı içerik siyah görünür

**Önem: yüksek.**

HDCP korumalı bir yolda oynayan içerik yakalanamaz. Korumasız veya sanal bir ekran yolu algılayan
yayın servisleri hiç oynamayı reddedebilir ve `SetWindowDisplayAffinity(WDA_EXCLUDEFROMCAPTURE)`
ile yakalamadan çıkan her şey görünmez olur.

**Azaltma:** yok ve denenmiyor da. Doğru davranış bunu algılamak, belgelemek ve etkilenen pencereyi
kullanıcıya siyah bir dikdörtgen göstermek yerine değiştirmeden geçirmektir. Bu,
[00 — Genel bakış](00-genel-bakis.md) içinde açıkça hedef olmayanlar arasında listelenmiştir.

---

## R-06 — Hibrit sistemlerde adaptörler arası kopyalar

**Önem: yüksek ve tek başına tüm kazancı silmeye muktedir.**

MUX'lu bir dizüstünde — veya sanal ekranın bir GPU'da oluşturulup fiziksel monitörün başka bir
GPU'ya bağlı olduğu her sistemde — her karenin PCIe üzerinden, en kötü durumda sistem
belleğinden geçerek adaptörler arası geçmesi gerekir. 60 Hz'de 1080p 32-bit bir kare için bu, ek
yükten önce kabaca 500 MB/s (**tahmin**).

**Azaltma:** sanal ekranın render adaptörünü hedef monitörle aynı adaptöre sabitleyin;
`IddCxAdapterSetRenderAdapter` ve cihaz adı yerine PCI bus numarasından türetilmiş kararlı bir
`LUID` kullanarak. Bu uygulanıp ölçülene kadar **hibrit sistemler düşürülmüş yapılandırma olarak
değerlendirilmeli** ve öyle belgelenmelidir.

Kaynaklar: [IddCx versions](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/iddcx-versions),
[Virtual-Display-Driver](https://github.com/VirtualDrivers/Virtual-Display-Driver).

---

## R-07 — Tam sayı olmayan oranlarda metin ve arayüz bulanıklığı

**Önem: yüksek, çünkü sadece oyunu değil masaüstünü her gün etkiliyor.**

1366×768 → 1920×1080 = **1.40625×**, tam sayı değil. Her glif yeniden örnekleniyor. Alt piksel
antialiasing (ClearType) tam piksel hizalamasına bağlı olduğu için bozuluyor. Okuma ve yazma için
kullanılan bir masaüstünde bu sürekli ve görünür bir gerilemedir.

Bir DPI sonucu da var: Windows ve her uygulama ekranın 1366×768 olduğuna, o çözünürlüğün DPI'ına
inandığı için pencere yerleşimi, snapping ve monitör başına DPI davranışı sanal ekranı takip ediyor
ve ardından ölçekleyici tarafından bir kez daha ölçekleniyor.

**Azaltmalar:**

- Oranın tam olduğu **tam sayı dostu preset'ler** sunun — 2× ile 960×540 → 1920×1080, 2× ile
  1280×720 → 2560×1440 — her ne kadar 2× nearest-neighbour veya Lanczos ölçeklemesi FSR'dan
  farklı görünse de.
- Keskinleştirmenin kapalı olduğu bicubic veya Lanczos kullanan bir **arayüz modu** sunun; FSR 1
  ve NIS oyun görüntüsü için ayarlandığından metinde aşırı keskin görünebilirler.
- Dokümantasyonda masaüstü metin kalitesinin bu yaklaşımın bedeli olduğunu açıkça söyleyin.

---

## R-08 — Exclusive fullscreen hattı atlar

**Önem: orta.**

Exclusive fullscreen bir oyun ekran yolunu doğrudan tutar. Sanal ekranda görünmeyeceği için hiçbir
şey yakalanmaz ve hiçbir şey ölçeklenmez. Lossless Scaling'in dokümantasyonu da aynı kısıtı açıkça
belirtiyor.

**Azaltma:** belgeleyin. Desteklenen yapılandırma windowed veya borderless fullscreen. Borderless
çalışamayan uygulamalar kapsam dışı.

Kaynak: [Lossless Scaling scaler guide](https://sageinfinity.github.io/docs/FAQ/scalers).

---

## R-09 — Anti-cheat ve sanal ekranlar

**Önem: orta ve büyük ölçüde ölçülmemiş.**

DisplayBoost'un süreç dışı yakalaması, enjekte eden araçlara karşı gerçek bir avantaj: oyunun
sürecine dokunmuyor. Ama anti-cheat sistemleri yine de *sanal ekranlara*, sıra dışı adaptörlere
veya genel olarak ekran yakalamaya itiraz edebilir ve araştırma her iki yönde de güvenilir kanıt
bulamadı.

**Azaltma:** doğrulanmamış olarak belgeleyin, uyumluluk iddia etmeyin ve kullanıcılara rekabetçi
bir oyunu başlatmadan önce sanal ekranı hızlıca devre dışı bırakma yolu verin. Bu, spekülasyondan
çok topluluk raporlarının cevaplayacağı bir soru.

---

## R-10 — Ekran topolojisi değişimleri yakalama oturumunu bozar

**Önem: orta.**

`IDXGIOutputDuplication` örnekleri mod değişimlerinde, çoğaltılan masaüstünden uzaklaşan her
geçişte ve ekran cihazı değiştiğinde geçersiz olur. Monitör takma/çıkarma, DPMS uykusu ve uyanma
ve sürücü güncellemeleri, hattın tutuyor olabileceği tüm varsayımları geçersiz kılar.

**Azaltma:** yakalama oturumunu her an parçalanıp yeniden kurulabilen bir durum makinesi olarak
ele alın, asla kararlı bir döngü olarak değil. Adaptörleri ve output'ları her yeniden kurulumda
numaralandırın, önbelleğe almayın. `WM_DISPLAYCHANGE` ile adaptör/output geliş ve gidişlerini
izleyin.

Başarısızlık modu tablosu için bkz. [02 — Yakalama ve sunum](02-yakalama-ve-sunum.md).

---

## R-11 — Sürücü imzalama ve dağıtım

**Önem: orta.**

Bir ekran sürücüsü kurmak için yönetici hakları, yüklenmek için geçerli bir imza gerekir.
Kullanıcılardan test signing'i açmalarını beklemek gerçekçi değil ve bunu istemek bazı anti-cheat
yapılandırmalarını da bozar.

**Belirlenen yol:**

- **SignPath Foundation**, uygun açık kaynak projelere ücretsiz OV seviyesi kod imzalama sağlıyor;
  CI entegrasyonu var ve anahtarlar Foundation'ın HSM'inde tutuluyor. Hem Virtual Display Driver
  hem ParsecVDisplay bunu kullanıyor; bu da yolun bu sınıf bir proje için çalıştığının doğrudan
  kanıtı.
- Bir **EV kod imzalama sertifikası** ile Microsoft Partner Center üzerinden **attestation signing**
  fallback olarak kalıyor ve Partner Center'ın kendisinin imzalayacağı her yol için zorunlu.
- Kurulum uygulaması, açık ve bilgilendirilmiş onay olmadan asla sürücü kurmamalı ve kaldırma yolu
  ekran çalışmıyorken bile işlemeli.

Kaynaklar: [SignPath Foundation](https://signpath.org/),
[Attestation Sign Windows Drivers](https://learn.microsoft.com/en-us/windows-hardware/drivers/dashboard/code-signing-attestation).

---

## R-12 — HDR ve wide color gamut

**Önem: orta.**

HDR, sürücü tarafında IddCx 1.10 (Windows 11 23H2+), yakalama ve upscale tarafında HDR farkındalığı
olan bir renk hattı gerektiriyor. NVIDIA NIS HDR Linear ve PQ modlarını destekliyor, ama FSR 1
tone mapping sonrası display-referred SDR içerik için tasarlandı ve yakalama yolu, banding veya
yanlış transfer fonksiyonunu önlemek için dikkatli işlenmesi gereken FP16 yüzeyler döndürebilir.

**Azaltma:** **V1 yalnızca SDR sevk ediyor ve bunu söylüyor.** HDR, SDR yolu doğru ve ölçülmüş
hale geldikten sonra gelir. Windows Automatic Super Resolution'ın da HDR desteklemediğini not edin
— zorluk bu projeye özgü değil.

Kaynak: [Automatic Super Resolution](https://support.microsoft.com/en-us/windows/ai/ai-features/automatic-super-resolution).

---

## R-13 — GPU sürücüsü güncellemesinden sonra siyah ekran

**Önem: orta, ama kurtarma yolu bariz.**

Virtual Display Driver projesi tarafından belgelenmiş: büyük bir GPU veya chipset sürücüsü
güncellemesi sırasında Windows ekran cihazlarını yeniden sıralıyor ve sanal ekranı fizikselin
önüne alabiliyor. Sanal ekranın fiziksel bir görüntüsü olmadığı için sonuç, aslında çalışan bir
sistemde siyah ekran.

**Azaltma:** GPU sürücüsü güncellemesinden önce sanal ekranın kaldırılması gerektiğini belgeleyin.
Kurtarma için: Windows Recovery'ye ulaşmak için 2-3 kez zorla kapatın, Safe Mode'a önyükleyin ve
ekran adaptörünü kaldırın — veya sistem yalnızca yanlış ekranı gösteriyorsa `Win+P` ile seçenekleri
gezdirin.

Kaynak: [Virtual-Display-Driver troubleshooting](https://github.com/VirtualDrivers/Virtual-Display-Driver).

---

## R-14 — VRR ve adaptive sync bozulması

**Önem: orta.**

Değişken yenileme hızı GPU ile monitör arasında pazarlık edilir. Ekstra bir kompozisyon katmanı
eklemek, ekranın değişken yenileme durumuna hiç girmemesine, judder'ın geri gelmesine veya hattın
composed flip'e ve onun gecikme cezasına zorlanmasına sık sık neden olur. Sanal ekran ile fiziksel
monitör arasındaki karışık yenileme hızları problemi büyütüyor.

**Azaltma:** V1 sunum modunu ve kare temposunu doğrudan ölçüyor ve gerçekte ne elde ettiğini
bildiriyor. VRR'ye bağımlı kullanıcılara bunun onlara göre olmayabileceği açıkça söylenmeli.

---

## R-15 — Sürücü lisansı: MS-PL mi, MIT mi

**Önem: orta ve erken karar verilirse tamamen önlenebilir.**

`microsoft/Windows-driver-samples` içindeki kanonik IddCx örneği **Microsoft Public License
(MS-PL)** altında, MIT değil. MS-PL izin verici, ama yazılımın kaynak kod dağıtımlarının MS-PL
altında kalmasını şart koşuyor. DisplayBoost'un sürücüsünü bu örnekten türetmek, dolayısıyla
**karma lisanslı bir repo** yaratır: uygulama için MIT, türetilmiş sürücü kaynağı için MS-PL.

İki seçenek var ve proje henüz seçim yapmadı:

1. **Örnekten türetin ve karma lisansı kabul edin.** Teknik olarak daha hızlı ve daha düşük riskli,
   çünkü IddCx'in programlama modeli ince ve üzerinde çalışılmış bir örnek gerçekten değerli.
   Dizin başına lisans dosyaları ve açık dokümantasyon gerektirir.
2. **Sürücüyü belgelenmiş IddCx API'sine karşı sıfırdan yazın.** API dokümantasyonu örneğin
   lisansı kapsamında değil. Daha yavaş, daha riskli, ama repo tartışmasız MIT kalır.

Bu karar V2 başlamadan önce verilmeli; V2'nin açık kararlar tablosunda `R-15` olarak listelenmiştir.

Kaynaklar: [Windows-driver-samples LICENSE](https://github.com/microsoft/Windows-driver-samples/blob/main/LICENSE),
[Indirect display driver overview](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/indirect-display-driver-model-overview).

---

## R-16 — Ekran sahipliği ve pencere yönetimi

**Önem: orta.**

Sanal ekranı birincil yapmak ve mevcut pencereleri oraya taşımak resmî olarak desteklenen bir işlem
değil. Birincil monitör, sanal masaüstü orijininde konumlanmasıyla tanımlanır ve genellikle
`SetDisplayConfig` ile yeniden yapılandırılır; "tüm pencereleri taşı" ise üst düzey pencereleri
numaralandırıp yeniden konumlandırarak uygulanır — yükseltilmiş pencerelerin, tam ekran
pencerelerin ve başka masaüstlerindeki pencerelerin direneceği bir yaklaşım.

Ayrıca bariz doğru cevabı olmayan bir kullanıcı deneyimi sorusu var: ölçekleyici aktifken görev
çubuğu ve bildirim alanı hangi ekrana ait olmalı?

**Azaltma:** ilk iterasyonda sanal ekranı hiç birincil yapmamayı, bunun yerine DisplayBoost'u sanal
ekran üzerinde tek bir uygulama veya tek bir pencereye kapsamlandırmayı düşünün. Bu, topoloji
işini tamamen ortadan kaldırır ve secure desktop'ı, görev çubuğunu ve pencere yönetimini olduğu
gibi bırakır. Ürünü de daraltır — kazara değil, açıkça verilmesi gereken bir karar.

Kaynak: [ChangeDisplaySettingsEx](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-changedisplaysettingsexa).

---

## R-17 — Henüz hiç ölçüm yok

**Önem: orta.**

Bu dokümanlardaki her performans rakamı ya bir **tahmin** ya da **üçüncü taraflardan alınmış**.
DisplayBoost kendi hiçbir şeyini ölçmedi. Gecikme bütçesi, adaptörler arası maliyet ve upscale
geçiş maliyeti hep ilk ilkelerden ve yayınlanmış kaynaklardan çıkarıldı, bu projenin donanımından
değil.

**Azaltma:** V1 tam olarak bunu düzeltmek için var. Herhangi bir sürücü çalışması başlamadan önce,
1366×768 → 1920×1080'de FSR 1, NIS ve Lanczos için gecikme, GPU maliyeti ve görüntü kalitesini
belgelenmiş bir metodolojiyle yayınlayacak. O zamana kadar buradaki her rakamı geçici sayın.

---

## Bilinen sınırlar özeti

DisplayBoost'un yapmayacağı şeyler, açıkça:

- **Modern bir oyunu**, oyun içi upscaler'dan veya GPU sürücüsünün kendi ölçekleme seçeneğinden
  **daha hızlı yapmayacak.**
- **Exclusive fullscreen** uygulamalarla çalışmayacak.
- **Secure desktop'ı**, DRM korumalı videoyu veya yakalamadan çıkan pencereleri yakalamayacak.
- **Yönetici hakları olmadan çalışmayacak**, çünkü ekran sürücüsü kurmak bunu gerektiriyor.
- **Metin keskinliğini** native çözünürlükte çalışmak kadar iyi korumayacak. Temel ödünleşim bu.
- **GPU'nun işini ortadan kaldırmayacak**, yalnızca piksel başına olan kısmını.

## Okumaya devam

- [06 — Yol haritası](06-yol-haritasi.md) — bu risklerin planı nasıl şekillendirdiği
- [00 — Genel bakış](00-genel-bakis.md) — bu kayıttan çıkan tasarım ilkeleri
- [07 — Kaynaklar](07-kaynaklar.md) — yukarıdaki her iddianın arkasındaki kaynaklar
