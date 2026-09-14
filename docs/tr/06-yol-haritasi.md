# 06 — Yol haritası

> [English](../06-roadmap.md) | **Türkçe**

Plan bilinçli olarak şu sırayla kurgulandı: en riskli ve en geri döndürülemez iş — kullanıcının
ekranını devralabilecek bir ekran sürücüsü — hat kanıtlanıp ölçüldükten **sonra** geliyor.

## Faz özeti

| Faz | Kapsam | Durum |
|---|---|---|
| **V0 — Araştırma** | Fizibilite, IddCx, yakalama ve sunum, upscale lisansları, benzer projeler, riskler | ✅ Tamamlandı |
| **V1 — Sürücüsüz prototip** | Mevcut ekranda yakalama, upscale, sunum. Ölçümler. | 🔜 Sıradaki |
| **V2 — Sanal ekran** | Düşük çözünürlüklü render hedefi olarak IddCx sürücüsü | 📋 Planlandı |
| **V3 — Otomatik profiller** | Algılama, öneriler, tek tıkla kurulum | 💡 Fikir |

---

## V0 — Araştırma ✅

**Çıktı:** bu dokümanlar.

**Çıkış kriterleri, hepsi karşılandı:**

- Her mimari iddia [07 — Kaynaklar](07-kaynaklar.md) içinde birincil bir kaynağa dayanıyor veya
  açıkça tahmin olarak etiketlenmiş.
- IddCx sürüm-Windows matrisi Microsoft Learn'e karşı doğrulandı.
- Her aday upscaler'ın lisansı belirtildi ve kullanılabilirliği konusunda net bir karar var.
- [05 — Riskler ve sınırlar](05-riskler-ve-sinirlar.md) içindeki risk kaydı tam; projeye karşı
  çıkan riskler dahil.
- Ölçülebilir başarı kriterlerine sahip fazlı bir plan mevcut.

**Araştırmanın değiştirdiği şeyler.** Üç bulgu projeyi maddi olarak yeniden şekillendirdi:

1. **Performans varsayımı ilk göründüğünden çok daha zayıf.** Sürücü düzeyi AMD RSR ve NVIDIA NIS,
   aynı düşük çözünürlükten native'e numarasını zaten present yolunun içinde yapıyor. Proje
   "her şeyi hızlandır"dan "sürücülerin ulaşamadığını kapsa"ya taşındı.
2. **Microsoft IDD örneği MIT değil, MS-PL.** Bu, reponun lisans modeli üzerinde gerçek bir kısıt
   ve `R-15` olarak kaydedildi.
3. **Magpie GPL-3.0.** Shader koleksiyonu MIT bir projeye kopyalanamaz, dolayısıyla upscaler'lar
   doğrudan AMD ve NVIDIA'dan alınacak.

---

## V1 — Sürücüsüz prototip 🔜

**Amaç: hattı kanıtlamak ve rakamları üretmek — ekran topolojisine dokunmadan.**

Mevcut bir ekranı yakala, upscale et ve aynı ekranda tam ekran sun. Sanal ekran yok, sürücü yok,
yönetici hakları yok, kimseyi kilitleme riski yok. Çıktı işlevsel olarak çok süslü bir ayna — ve
tam olarak mesele de bu.

### Kapsam

- Birincil ekranı Windows.Graphics.Capture ile yakalayan, alternatif backend olarak DXGI Desktop
  Duplication kullanan bir D3D11 uygulaması.
- Üç upscale backend'i: **FSR 1 (EASU + RCAS)**, **NVIDIA NIS (NVScaler)** ve **Lanczos**.
- `DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT` ve `SetMaximumFrameLatency(1)` ile tam
  ekran, flip-model sunum.
- Çıkış çözünürlüğünde, son adım olarak birleştirilen imleç.
- Her aşamanın kare sürelerini bildiren bir benchmark modu.

### Başarı kriterleri

| Kriter | Hedef |
|---|---|
| DirectX 11 feature level 11 bir GPU'da 1366×768 → 1920×1080 çalışması | Zorunlu |
| Referans makinede sunum modunun **independent flip** olarak bildirilmesi | Zorunlu |
| Aşama başına zamanlamanın tahmin değil raporlanmış olması: yakalama, upscale, imleç, sunum | Zorunlu |
| FSR 1, NIS ve Lanczos'un **oyun ve masaüstü içeriğinde ayrı ayrı** karşılaştırılması | Zorunlu |
| Uçtan uca eklenen gecikmenin native bir referansa karşı ölçülmesi | Zorunlu |
| Metodolojinin üçüncü bir tarafça yeniden üretilebilecek kadar belgelenmesi | Zorunlu |
| GPU maliyetinin aynı sahnenin native render'ına karşı delta olarak ölçülmesi | Zorunlu |

**V1'in açıkça yapmadıkları:** sürücü yok, sanal ekran yok, HDR yok, VRR iddiası yok, anti-cheat
iddiası yok, masaüstü metin kalitesi iddiası yok.

### Bu sıralama neden önemli

V1 ucuz, tamamen geri döndürülebilir ve aksi halde bir sürücünün içinde tahminle cevaplanacak
soruları ölçümle cevaplıyor. Ölçülen ek yük her gerçekçi durumda kazancı aşıyorsa bu da bir
sonuçtur — ve prototip dışında hiçbir maliyeti yoktur.

---

## V2 — Sanal ekran 📋

**Amaç: düşük çözünürlüklü render hedefini gerçek yapmak.**

### V2 başlamadan önce netleşmesi gereken açık kararlar

| Karar | Seçenekler | Eğilim |
|---|---|---|
| **Sürücü kaynağı** | MS-PL örneğinden türetmek (karma lisans, daha hızlı) mu, belgelenmiş IddCx API'sine karşı clean-room yazmak (tartışmasız MIT, daha yavaş) mı | Belirsiz — `R-15` |
| **Kare teslimi** | Sanal output'u kullanıcı modundan yakalamak (basit, bir ekstra kopya) mi, IddCx swapchain dokusunu sunum sürecine vermek (daha hızlı, çok daha incelikli) mi | Kullanıcı modu yakalamayla başla, ölç, sonra optimize et |
| **IddCx hedefi** | Windows 11 23H2+'da HDR için 1.10 mu, daha geniş Windows 10 erişimi için 1.5 mi | 1.10, ve 1.5 fallback yolu |
| **Ekran kapsamı** | Sanal ekranda tüm masaüstü mü, tek bir uygulama penceresi mi | **Dar başla.** Sanal ekranı birincil yapmak, hiçbir ek içgörü getirmeden pencere yönetimini, görev çubuğu sahipliğini ve secure desktop'ı işin içine sokuyor — bkz. `R-16` |
| **İmzalama yolu** | SignPath Foundation mı, EV sertifikalı attestation signing mi | Önce SignPath |

### Kapsam

- Kasıtlı, küçük bir mod listesi duyuran bir IddCx indirect display driver.
- Render adaptörünün, `IddCxAdapterSetRenderAdapter` ve PCI'dan türetilmiş bir `LUID` ile fiziksel
  monitörün adaptörüne sabitlenmesi.
- Güvenli kurulum, kaldırma ve kurtarma akışı; normal durumda Safe Mode gerektirmeden geri
  döndürülebilir ve gerektirdiği durumlar için belgelenmiş.
- Sanal output'un yakalanması ve V1'in hattı yeniden kullanılarak fiziksel monitörde sunulması.

### Başarı kriterleri

| Kriter | Hedef |
|---|---|
| Yapılandırılabilir çözünürlükte, Windows tarafından normal bir monitör olarak görülen sanal ekran | Zorunlu |
| Karelerin uçtan uca yakalanıp sunulması, V1 ile aynı gecikmede ±1 kare | Zorunlu |
| Kurulum ve kaldırmanın geri döndürülebilir olması, geride ekran yapılandırması bırakmaması | Zorunlu |
| Safe Mode'dan kurtarmanın belgelenmiş ve test edilmiş olması | Zorunlu |
| Fiziksel monitörün her zaman console display olarak kalması | Zorunlu |
| Kaçış kısayolunun DisplayBoost'u kapatıp önceki yapılandırmayı geri getirmesi | Zorunlu |
| Hibrit bir sistemde adaptörler arası maliyetin ölçülmesi veya yapılandırmanın desteklenmiyor ilan edilmesi | Zorunlu |

---

## V3 — Otomatik profiller 💡

**Amaç: kendini doğru yapılandıran bir ilk çalıştırma deneyimi.**

- Fiziksel monitörü numaralandır ve native modunu oku.
- Ölçülen V1 verisinden en iyi render çözünürlüğü ve filtre kombinasyonunu öner; ölçek oranını ve
  içerik türünü hesaba katarak.
- Tek tıkla, önizlemeli uygula.
- Uygulama başına geçersiz kılmaları hatırla.
- Risk kaydındaki yapılandırmaları algıla ve uyar: hibrit adaptörler, HDR ekranlar, VRR ekranlar,
  DRM oynatımı.

Proje burada, bu dokümanların hiçbirini okumamış biri tarafından kullanılabilir hale geliyor —
ki "bitti"nin önemi olan tek tanımı bu.

---

## Açıkça kapsam dışı

Bunlar ertelemeler değil kararlar ve gerekçeleri [00 — Genel bakış](00-genel-bakis.md) içinde:

| Kapsam dışı | Neden |
|---|---|
| Frame generation | Farklı problem, farklı gecikme bütçesi ve render maliyetini düşürmüyor |
| DLL enjeksiyonu, hook'lar, overlay'ler | Anti-cheat riski, güncellemeler arası kırılganlık ve başka uygulamaların çökmelerinden sorumluluk |
| DRM korumalı oynatımı yakalamak | Mevcut API'lerle mümkün değil |
| Secure desktop'ı kapsamak | Kullanıcı modundan mümkün değil |
| Native üstü supersampling | Projenin amacının tersi yön |
| Linux, macOS | Farklı bir compositor modeli ve farklı bir proje |

---

## Ölçüm metodolojisi

V1'in rakamlarının bir anlam taşıması için:

- **Referans donanım tam olarak belirtilmeli:** CPU, GPU, sürücü sürümü, monitör native modu ve
  yenileme hızı ve Windows derlemesi.
- **Gecikme ölçülür, çıkarılmaz:** girdiden fotonlara eklenen gecikme, aynı içerikte native render
  ile DisplayBoost hattı karşılaştırılarak ölçülür. Kare sayarak akıl yürütmek ölçüm değildir.
- **GPU maliyeti**, aynı sahnenin native render'ına karşı bir deltadır, mutlak bir rakam değil.
- **Görüntü kalitesi** iki içerik sınıfında ayrı ayrı karşılaştırılır — oyun benzeri görüntü ve
  masaüstü metni — çünkü filtreler bu ikisi için çok farklı ayarlanmıştır ve toplu bir skor tam
  olarak kullanıcıların bilmesi gereken ödünleşimi gizler.
- **Sunum modu varsayılmaz, bildirilir:** swapchain'in independent flip'e ulaşıp ulaşmadığı,
  gecikme sonucunu hattın geri kalanının toplamından daha fazla değiştirir.
- **Her olumsuz sonuç yayınlanır.** Yalnızca projenin kazandığı durumları raporlayan bir benchmark
  seti benchmark değildir.

---

## Planı nasıl etkileyebilirsiniz

Şu anda en faydalı katkılar [CONTRIBUTING.md](../../CONTRIBUTING.md) içinde listelenenler: araştırmaya
düzeltmeler, projenin gözden kaçırdığı benzer projeler, buradaki tahminlerle çelişen ölçümler ve
ekran sürücüsü veya yakalama overlay'i sevk etmiş kişilerden gelen başarısızlık modları.
