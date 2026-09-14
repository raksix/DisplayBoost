# DisplayBoost — Araştırma Dokümantasyonu

Bu klasör DisplayBoost'un arkasındaki fizibilite çalışmasını içeriyor. **Kanonik dil İngilizce;
Türkçe çeviriler [`docs/`](../README.md) altındaki dokümanları birebir yansıtır.**

API'ler, sürüm numaraları, lisanslar ve performans rakamları hakkındaki her olgusal iddia
[`07-kaynaklar.md`](07-kaynaklar.md) içinde bir kaynağa dayanıyor. Kaynaklandırılamayan iddialar
metinde tahmin olarak etiketlenmiş, gerçek gibi sunulmamıştır.

<div align="center">

[English](../README.md) | **Türkçe**

</div>

## Dokümanlar

| # | Doküman | Ne anlatıyor |
|---|---|---|
| 00 | [Genel bakış](00-genel-bakis.md) | DisplayBoost nedir, hedef mimari, tasarım ilkeleri, hedef olmayanlar ve sözlük |
| 01 | [Sanal ekran sürücüsü](01-sanal-ekran-surucusu.md) | IddCx indirect display driver nasıl çalışır, hangi Windows hangi IddCx sürümünü destekler, hangi projelerden öğrenilir ve sürücü nasıl imzalanır |
| 02 | [Yakalama ve sunum](02-yakalama-ve-sunum.md) | Kareler sanal ekrandan nasıl çıkarılıp minimum gecikmeyle fiziksel monitöre nasıl gönderilir |
| 03 | [Ölçekleme](03-olcekleme.md) | Hangi upscaler'lar teknik olarak kullanılabilir ve yasal olarak dağıtılabilir, ünlüleri neden kullanılamaz |
| 04 | [Benzer projeler](04-benzer-projeler.md) | Magpie, Lossless Scaling, Automatic Super Resolution, AMD RSR — ve DisplayBoost neyi farklı yapıyor |
| 05 | [Riskler ve sınırlar](05-riskler-ve-sinirlar.md) | Risk kaydı. **Heyecanlanmadan önce okuyun.** |
| 06 | [Yol haritası](06-yol-haritasi.md) | Başarı kriterleri ve ölçüm metodolojisiyle fazlı plan |
| 07 | [Kaynaklar](07-kaynaklar.md) | Kullanılan her kaynak, konuya göre gruplanmış |

## Önerilen okuma sırası

**Beş dakikanız varsa:** [00 — Genel bakış](00-genel-bakis.md), ardından "Dürüst anlatım"
bölümü, sonra [05 — Riskler](05-riskler-ve-sinirlar.md) dosyasının başı.

**Fikri değerlendirmek istiyorsanız:** 00 → 05 → 04. Fizibilite kararı 05'te, rekabet
konumlandırması 04'te.

**İnşa etmek istiyorsanız:** 00 → 01 → 02 → 03, ve 05'i başka bir sekmede açık tutun. Nereden
başlayacağınız için [06 — Yol haritası](06-yol-haritasi.md).

**Kaynakları denetlemek istiyorsanız:** [07 — Kaynaklar](07-kaynaklar.md), sonra hangi dokümanın
hangi iddiada bulunduğunu takip edin.

## Bu dokümanlarda kullanılan kurallar

- **Güven düzeyi belirtilir.** Birincil kaynağa dayanmayan her şey metinde *tahmin*, *doğrulanmamış*
  veya *anekdot* olarak işaretlenmiştir.
- **Kaynaklı olgular link taşır.** Satır içi linkler, birincil kaynak mevcut olduğunda onu özetleyen
  bir blog yazısına değil, doğrudan kaynağın kendisine işaret eder.
- **Ölçüm, iddiadan üstündür.** Projenin kendi rakamları olmadığı yerde bu açıkça söylenir.
  DisplayBoost'un kendi benchmark'ları V1 ile gelecek.
- **Teknik terimler her iki dilde İngilizce kalır** — `IddCx`, `DXGI Desktop Duplication`,
  `swapchain`, `flip model`, `fill-rate`. Bunları çevirmek metni hem aranması zor hem de üretici
  dokümantasyonuyla karşılaştırılamaz hale getirir.

## Araştırmaya katkı

Bu aşamada en değerli katkı **düzeltmelerdir**. Bkz. [../CONTRIBUTING.md](../CONTRIBUTING.md) ve
[research correction issue şablonu](https://github.com/raksix/DisplayBoost/issues/new?template=research_correction.yml).

Bir İngilizce dokümanı düzenlerseniz, aynı pull request içinde `docs/tr/` altındaki Türkçe
karşılığını da güncelleyin — dosya eşleşme listesi
[`../scripts/check-doc-parity.sh`](../scripts/check-doc-parity.sh) içinde ve CI tarafından
zorunlu tutuluyor.
