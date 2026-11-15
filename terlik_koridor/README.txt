ANNE TERLIĞI - Koridor prototipi (Bolum 1)
Godot 4.7.2  |  Project > Import > project.godot  |  F5

KONTROL
- Ekranin alt yarisina dokun, parmagini ASAGI cek (ne kadar cok cekersen o kadar guclu),
  saga/sola cekerek nisan al (sling: saga cekersen sola gider). Birak = firlat.
- Noktali cizgi = tahmini yol, sari halka = ilk yere dusme noktasi.

KAMERA AYARI
- Sol ustteki KAM dugmesi izgarayi acar. Yesil/mavi izgara + kirmizi kapi cercevesi
  arka plan resmiyle cakisana kadar Ufuk / Odak / Yuk / Orta dugmelerine bas (basili tut = surekli).
- Degerler ekranda ve Output konsolunda yazar; main.gd'deki vp_x, horizon, focal, cam_h
  degiskenlerine yaz, kalici olur.

AYAR SABITLERI (main.gd ustu)
START, ELEV, SPEED_MIN/MAX, AIM_RANGE, GRAV, MOM_* (anne konum/olcek), MEMO_* ...

ASSETS (assets/)
koridor.jpg, anne_idle.png, anne_firlat.png  (anne iki sprite ayni ayak noktasina hizali)
Memo simdilik kodla cizilen placeholder, sprite gelince _draw_memo() degisecek.

--- v2: SONSUZ BOLUM ---
- (v4'te degisti, asagiya bak) Bolum 1-8 elle tasarli, 9+ uretilir.
- Zorluk 60. bolumde tavan yapar; her 5. bolum ZOR, ardindan bir rahat bolum.
- Uretilen bolum cozulebilir mi diye _solvable() ile simule edilir; olmazsa yeni tohum denenir.
- Kazaninca "Sonraki Bolum" butonu; ilerleme user://terlik_save.cfg dosyasinda saklanir.

--- v3: YENI GORSELLER ---
- 7 oda: Aile Koridoru, Saatler, Gunesli Oda, Kirmizi Salon, Mavi Salon, Mutfak, Cilgin Koridor.
  Her 3 bolumde oda degisir (LEVEL_THEMES / LEVELS_PER_THEME). Kamera degerleri THEMES listesinde.
- Memo artik koltugun ARKASINA saklaniyor (iterek saga-sola kayiyor). Dil cikarir (NANIK!),
  terlik yaklasinca / guclu cekince gergin (YAPMA!), vurulunca sersem + beyaz bayrak.
  Terligi koltugun USTUNDEN asirip kafasina dusurmen lazim.
- Vazo ve avize kirilir (kirik cam efekti, "Kirdigin esya" sayaci). Vitrin/koltuk sert engel.
- Cozulebilirlik testi engelleri de hesaba katar.
- KAM'a basinca TEMA dugmesi cikar: odalari tek tek gezip izgarayi kontrol edebilirsin.
  Curvy odalar (Mutfak, Cilgin Koridor) egri oldugu icin yaklasik; Ufuk/Odak/Orta ile ince ayar yap,
  konsoldaki "TEMA n vp=.. hz=.. f=.. ch=.." satirini THEMES'e yaz.

--- v4: COKLU HEDEF ---
- Artik her bolumde BIRDEN FAZLA Memo var; hepsini vurunca bolum biter. Ustte "Memo: 1 / 3" sayaci.
- Bolum 1 = ogretici (tek, sabit hedef, 8 hak, ok isareti + ipucu kutusu; iskalayinca farkli ipucu).
- Hedef tipleri (rengiyle ayirt edilir, ustunde etiket yazar):
    memo  : normal
    HIZLI : sari, kucuk, 1.8x hizli salinir
    KACAK : mavi, koltugun arkasina egilir; egikken vurulamaz (kafasini cikarinca vur)
    KALIN : kirmizi, buyuk, 2 vurus ister (ilkinde "HIC ACIMADI!")
- Elle tasarli bolumler: 1 ogretici | 2 iki sabit hedef | 3 iki hedef + vazo | 4 uc hedef (biri kayar)
  | 5 KACAK tanitimi | 6 HIZLI tanitimi | 7 karisik | 8 KALIN tanitimi. 9+ uretilir (sabit tohum).
- Uretilen bolumlerde hedef sayisi 3'ten 5'e, tip cesitliligi ve salinim hizi zorlukla artar.
  Dar odalarda (Aile Koridoru, Mutfak) en fazla 2 hedef, orta odalarda 3-4, Saatler Koridoru'nda 5.
  _target_cap() odanin genisligine gore belirler. Her 5. bolum ZOR (+1 hedef, -1 hak), ardindan rahat bolum.
- Yildiz: hedef sayisi kadar atista bitirirsen 3, +2 israfa kadar 2, fazlasi 1.
- Cozulebilirlik testi artik HER hedefin vurulabilir oldugunu kontrol eder.
- TYPE_INFO sabitinden tip renklerini/boyutlarini/vurus sayisini degistirebilirsin.
- Duzeltme: Memo'nun "korkma" pozu artik terligi ASAGI cekerken tetiklenir (eskiden yukari cekince oluyordu).

--- v5: EL + NISAN ---
- Anne yerine sadece terligi tutan EL (main.gd: USE_HAND). false yaparsan eski Anne geri gelir.
  El artik assets/el.png (cizim yumruk, kol asagi uzanir; sprite'in ustten %18'i = yumruk merkezi, genislik 330px'e olceklenir).
  Terlik yumrugun ustunden cikar (main.gd _draw_hand). el.png silinirse kodla cizilen yer tutucu kullanilir.
  El, parmagi cekerken geri gelir, birakinca ileri savrulur.
- Nisan gorseli: daha kucuk ve solan noktalar, ince sapan cizgisi, yuvarlak guc cubugu, kucuk inis halkasi.
- Duvar: terlik yan duvara carpinca "TAK!" yazisi + hafif sarsinti. Noktali yolda duvar sekme noktalari
  acik mavi halkayla gosterilir (tahmin cizgisi sekmeyi zaten hesaplar). Sekme sertligi 0.75.

--- v6 ---
- Sari inis halkasi ve sapan cizgisi kaldirildi; sadece nisan cizgisi (noktalar) ve guc cubugu var.
- Sekme atisi: parmagi yana %60'tan fazla cekince hedef duvarin otesine kayar, terlik duvara carpip seker
  (_aim_offset). Sekme noktalari acik mavi halkayla gosterilir.

--- v7: REKLAM (LevelPlay) ---
- ads.gd (autoload "Ads"): LevelPlay'e Android eklentisi (addons/LevelPlayAds) uzerinden baglanir.
  Editorde / PC'de eklenti yok -> "stub": reklam hemen izlenmis sayilir, ustte gri TEST BANNER cizilir.
- BANNER: ekranin en ustunde, tam genislik, adaptive. Yuksekligi cihaza gore degisir (50 dp sabit degil);
  gercek yukseklik eklentiden gelir, ads.gd oyun koordinatina cevirir (ad_off) ve HUD, ipucu kutusu ve ust
  butonlar o kadar asagi kayar. Uzun ekranlarda ustteki siyah bant banner'i karsilar, oyuna binmez.
- TERLIK BITINCE: "Reklam Izle +3 Terlik" butonu (main.gd: REWARD_SHOTS, MAX_REWARD_CONTINUES = bolum basina 2).
  Odul gelince bolum KALDIGI YERDEN devam eder (Memo'lar sifirlanmaz). Reklam hazir degilse buton soluk.
- GECIS REKLAMI: 2 kazanilan bolumde bir, "Sonraki Bolum"e basinca (main.gd: INTERSTITIAL_EVERY).
  Reklam hazir degilse beklemeden devam eder, bir sonraki bolumde tekrar dener.
- KAM/TEMA debug dugmeleri artik sadece debug build'de gorunur (yayinda banner yaninda buton olmasin).

KURULUM (Android Studio YOK, sadece Godot)
1) Godot: Project > Install Android Build Template.
2) Project > Project Settings > Plugins: "LevelPlayAds" ACIK (project.godot'ta zaten acik gelir).
3) Project > Export > Android: "Use Gradle Build" ACIK, Min SDK 21+, Permissions: Internet.
4) ads.gd icine LevelPlay APP_KEY ve 3 ad unit id (banner, interstitial, rewarded) yaz.
5) LevelPlay panelinde ironSource Ads + Unity Ads aglarini ac. Baska ag eklersen adaptorunu
   addons/LevelPlayAds/export_plugin.gd icindeki _get_android_dependencies listesine ekle.
6) Telefonu USB ile baglayip Godot'un sag ustundeki Android simgesiyle (Remote Debug) calistir.
   Export sirasinda eklenti Java dosyasini android/build/src'ye KENDISI kopyalar, manifest ve
   Gradle bagimliliklarini ekler. Kopyalama hatasi verirse android_src/com klasorunu elle
   android/build/src/ icine at.
7) Sadece GERCEK CIHAZDA test et (editorde eklenti calismaz, sahte banner gorursun).
   LevelPlay'de test cihazi ekle, kendi reklamina tiklama.

--- v9: SPLASH + ANA MENU ---
- Acilis sirasi: splash.tscn (3 sn) -> menu.tscn -> main.tscn (oyun). project.godot'ta main_scene artik splash.tscn.
- SPLASH (splash.gd): terlik ucar, TAK! patlamasi, baslik carpar, KORIDOR seridi kayar, Memo dil cikarir,
  ikinci terlik Memo'yu vurur, kararip menuye gecer. Ekrana dokunursan (0.7 sn sonra) kararmaya atlar.
  Sure: splash.gd ustundeki DURATION (FADE_START'i de buna gore ayarla).
- ANA MENU (menu.gd): dalgali baslik, dusen terlikler, donen isinlar, OYNA (kayitli bolumden devam eder),
  NASIL OYNANIR penceresi. Memo'ya dokunursan sersemler :) OYNA'ya basinca terlik Memo'ya ucar, sonra oyun acilir.
  Banner yuksekligine (Ads.banner_h) gore ust kisim asagi kayar.
- Oyunda sol ustte "Menu" butonu var (KAM butonu 150'ye, TEMA 280'e kaydi; ikisi de sadece debug build).
- fx_util.gd: ortak yardimcilar (easing, yildiz, konturlu yazi). Baslik fontu: assets/fonts/Poppins-Bold.ttf (OFL lisansli).
- Ses dosyasi yok; eklersen splash'ta HIT1 / HIT2 anlarina "TAK" sesi koyabilirsin.

--- v9b: TESTERE DISI ZORLUK ---
- main.gd _saw_targets(): 9+ bolumlerde her 5 bolumluk dongude hedef sayisi yukselir, 5'in kati (ZOR) tepe yapar,
  sonraki dongu dusuk baslar; dongu tabani 15 bolumde bir +1 artar (SAW_GROW). Sayi odanin kapasitesine (_target_cap) gore kirpilir.
- Uretici artik yerlesim tutmazsa hedefi bire azaltip tekrar dener (eskiden hepsi basarisiz olunca tek hedefe dusuyordu = 89. bolum hatasi).

--- v9c: AYARLAR + UYGULAMALARIMIZ ---
- Ana menude sag ustte disli ikonu -> Secenekler sayfasi (menu.gd). Sirasi: Oyunlarimiz ve Uygulamalarimiz, SES (Muzik, Ses Efektleri),
  CIHAZ (Titresim, Ekran Efektleri), ILERLEME, DIL, YARDIM (Nasil Oynanir), GIZLILIK (Reklam Rizasini Yonet), HAKKINDA (Kullanim Sartlari, Gizlilik Politikasi).
- Sayfalar parmakla kaydirilir. Ayarlar user://terlik_settings.cfg dosyasinda (fx_util.gd get_setting/set_setting).
- Titresim ve Ekran Efektleri oyunda calisir (main.gd: vib_on / fx_on). Muzik/Ses ayari kaydedilir ama projede ses yok; ses eklenince U.get_setting("music"/"sfx", true) ile oku.
- DOLDUR: menu.gd ustundeki GAMES listesi (paket adlari), TERMS_URL, PRIVACY_URL, VERSION.
- Titresim icin Export > Android > Permissions > Vibrate isaretli olmali.
- Reklam rizasi: ads.gd show_privacy_options() eklentide showPrivacyOptions() metodu varsa onu cagirir, yoksa "yok" der.

--- v10: COKLU DIL ---
- Yeni autoload "Loc" (loc.gd): Turkce, Ingilizce, Ispanyolca, Portekizce (Brezilya), Endonezce.
  Ilk acilista telefon dilini kullanir (desteklenmiyorsa Ingilizce). Ayarlar > DIL butonuna basinca siradaki dile gecer ve kaydeder.
- Tum yazilar (menu, splash, oyun ici, ipuclari, oda adlari, ayarlar) loc.gd icindeki S sozlugunde. Kullanim: Loc.t("anahtar").
  "|" ile ayrilmis degerler liste: Loc.l("anahtar"), rastgele kelime: Loc.pick("anahtar").
- Yeni dil eklemek: LANGS ve NAMES'e ekle, S'deki HER satira bir deger daha yaz (sira: tr, en, es, pt, id).
  Latin harfli olmayan diller (Rusca, Arapca, Hintce) icin Poppins yerine o alfabeyi iceren bir font da eklemek gerekir.
- Baslik 3 satir: t1/t2/t3 anahtarlari. Uzun 1. satir icin Loc.k1() kucultme carpani.
- project.godot'ta config/name_localized ile uygulama adi dile gore degisir (Android).
- NOT: Godot'ta calistirip her dilde taşma kontrolu yapilmadi; en uzun metinler (yardim, ipuclari) Ayarlar'dan dil degistirilip kontrol edilmeli.

--- v10b: OKEY'IN YERINE GUNCELLEME (com.astrofelyx.pro) ---
- ads.gd: LevelPlay App Key, Banner ve Rewarded kimlikleri Okey (Yuzbir Arena) projesinden alindi. Okey'de interstitial YOK:
  INTERSTITIAL_ID bos; bos iken gecis reklami kapali (Java eklentisi de olusturmaz). LevelPlay panelinde ayni uygulamaya
  Interstitial birimi eklersen ads.gd'deki INTERSTITIAL_ID'ye yaz.
- export_presets.cfg eklendi: paket adi com.astrofelyx.pro, AAB, Gradle build, min SDK 24, version/code=1000 (Play'deki son kodundan BUYUK olmali; kucukse artir).
  Keystore alanlari bos: Project > Export > Android > Keystore > Release'e Okey'de kullandigin .jks, alias ve sifreyi gir (sifreyi dosyaya yazma).
- Imza ayni anahtarla atilmazsa Play guncellemeyi reddeder. Godot surumu: Play'in hedef API seviyesi sartini 4.2 karsilamayabilir (hata verirse Godot 4.3+).

--- v10c: BASTAN BASLA ---
- OYNA zaten kayitli bolumden devam eder (tasarim geregi). Test ederken 1. bolumden baslamak icin:
  Ayarlar > ILERLEME > "Bastan Basla (1. Bolum)" (2 kez dokun, 3 sn icinde onay).

--- v10d: YEDEKLEME ---
- export_presets.cfg: user_data_backup/allow=true (Android Auto Backup). Silip tekrar kuran / ayni Google hesabiyla yeni telefona gecen oyuncunun bolum ilerlemesi ve ayarlari geri gelir.
- Test ederken silip kursan bile ilerleme gelebilir: Ayarlar > Ilerleme > Bastan Basla.

--- v11: SES ---
- Yeni autoload "Sfx" (sfx.gd) + assets/audio/*.ogg (Pixabay'dan; mp3'ler ogg'ye cevrildi, -3 dB'ye normalize edildi, muzik kenarlarina fade).
- Sesler: throw (firlatma), hit (Memo'ya carpma), ouch (Memo vurulunca), bounce (duvar/koltuk), vase, glass (avize), scared (guclu cekince Memo "hoh"),
  win, lose, click (butonlar). Muzik tek parca, dongu; menuden oyuna kesintisiz devam eder.
- Ayarlar > Muzik / Ses Efektleri anahtarlari artik gercekten calisir. Uygulama arka plana gidince ses durur.
- Yeni ses eklemek: dosyayi assets/audio/ADI.ogg yap, sfx.gd icindeki BASE_DB'ye ADI: dB yaz, Sfx.play("ADI") ile cal.
- Eksik: "nanik" (Memo dil cikarma), yildiz kazanma sesi. Dosyalari ekleyince taunt.ogg / star.ogg diye BASE_DB'ye yaz.
- Pixabay lisansi: her dosyanin sayfasinda lisansi kontrol et; ses dosyalarini tek basina dagitma.

--- v15: SIRA OLCEGI + KUCUK HEDEFLER ---
- Hedefler (ve koltuklari) siralara gore olceklenir: EN ON sira en kucuk, her arka sira bir oncekinden buyuk
  (main.gd: TARGET_SHRINK, ROW_STEP, ROW_GAP, MAX_ROWS). Boylece arka siradaki hedefler on siranin ardinda kaybolmaz.
- Genel kucultme TARGET_SHRINK = 0.74 (1.0 = eski boyut). Oda basina sigan hedef sayisi artti (_per_row / _target_cap, en fazla 3 sira).
- Uretilen bolumlerde hedefler 1-3 siraya dagitilir, farkli siralar yatayda kaydirilir (SLOT_W).
- Testere disi korunur: hedef sayisi ayni dongu mantigiyla (lo lo lo+1 lo+1 lo+2), terlik sayisi hala hedef sayisina bagli
  (nt + 3 - zorluk, ZOR -1, rahat +1). Sadece baslangic 2 -> 3 ve SAW_GROW 3.0 -> 2.5 oldu (daha cok hedef).

--- v16: 4 SIRA + DAHA COK KAYAN HEDEF ---
- Derin odalarda en fazla 4 sira (MAX_ROWS), sig/dar odalarda _max_rows() 2-3'e dusurur. ROW_STEP 0.15 (x1.0, 1.15, 1.30, 1.45).
- Kayan (saga-sola giden) hedef orani bolumle artar: 9. bolumde %55, 60. bolumde %95 (MOVE_START / MOVE_END).
  ZOR bolumde +%10, rahat bolumde x0.7. Sallanma mesafesi ve hizi zaten zorlukla artiyordu.

--- v17: TAK! YAZISI ---
- Duvara carpinca TAK! yazisi bir atista en fazla 1 kez cikar (ses + sarsinti her carpmada devam eder).
- Yazi solarken kontur (siyah cizgi) de soluyor; eskiden kontur solmadigi icin ust uste binince ekran siyahlasiyordu.

--- v18: DOLU ODALAR + 250 BOLUM + SONSUZ DONGU ---
- Hedefler artik SLOT SLOT dizilir (_generate_level): once sira sayisi ve her siradaki hedef sayisi (_row_counts), sonra
  her hedefe kendi slotu verilir; kayma mesafesi komsu hedefle cakismayacak sekilde sinirlanir. Eskiden yerlesim
  tutmayinca hedef sayisi 2'ye dusuyordu (bolum 103/104 bos gorunumu). Artik sayi dusmez, oda kapasitesi kadar dolar.
- Testere disi: lo, lo, lo+1, lo+1, lo+2 (5'in kati = ZOR). lo, 6. bolumden 250. bolume 3'ten 8'e yavasca artar.
  Genis odalar ayni zorlukta +1/+2 hedef alir. Kayan hedef orani 0.35 -> 0.95 (p_move).
- Terlik sayisi: hedef + 4 - int(zorluk*3) + KALIN sayisi (ZOR -1, rahat +1). Erken bolumde bol, gec bolumde hedef+1:
  "reklam izle +3 terlik" daha cok anlam kazanir.
- Vitrin: atis seridinin disinda (elin oldugu tarafin karsisi), duvara yasli, hicbir hedefin onunu kapatmaz.
  Eskiden elin hemen onune gelebiliyordu (bolum 104).
- Bolum 1-250 uretilir (1-8 elle tasarli ogretici: 1-5 temel, 6 HIZLI, 7 karisik, 8 KALIN). 250'den sonra 101-250
  arasi 5'li bloklar her turda farkli karisik sirayla doner (_eff_level); blok ici sira ayni kalir, testere disi bozulmaz.
  Ekranda yazan bolum numarasi artmaya devam eder.
- Yerlesim yine de cozulemezse sirayla: ayni sayi farkli tohum -> engelsiz -> 1-2 hedef az -> en son 2 sabit hedef.

--- v19: BOING! ---
- Koltuga/vitrine carpinca BOING! yazisi bir atista en fazla 1 kez cikar; ses ve sarsinti de en fazla 0.35 sn'de bir
  (eskiden terlik koltuga yapisinca her kare yeni yazi + ses + sarsinti uretiyordu, ekran siyahlasiyordu).

--- v20: EKRAN TASMASI ---
- Genis odalarda (Saatler, Kirmizi Salon) on siradaki hedefler ekranin disina dusebiliyordu (oda ±2.3 m ama ekran
  on sirada sadece ~±1.5 m gosterir). _row_range(z, h) artik her sira icin oda ∩ EKRAN araligini hesaplar;
  hedefler, kayma mesafeleri, vazo, avize ve vitrin bu araligin icinde kalir. Oda kapasitesi de buna gore hesaplanir.
- Yeni: _add_target_abs (mutlak konumla hedef ekle).

--- v21: NISAN CIZGISI ---
- Nisan noktalari buyudu (yaricap 5-11 px, eskiden 2.5-6), koyu kenarli ve sonuna kadar belirgin (opaklik 1.0 -> 0.6),
  daha sik (her 6 alt adimda bir). Sekme halkasi kalinlasti. Ayarlar: _draw_aim ve _preview (i % 6).

--- v22: DIL LISTESI + ILERLEME YAZISI ---
- Ayarlar > DIL butonu artik siradaki dile gecmiyor: basinca liste acilir (5 dil, secili olanda tik), dile dokununca secilir ve liste kapanir.
  Liste disina dokunmak kapatir. Butonun sagindaki ok isareti acilir liste oldugunu gosterir. Yeni dil eklersen liste kendiliginden uzar (Loc.LANGS / NAMES).
- Ayarlar > ILERLEME altindaki yesil "ilerlemen bu cihazda kaydediliyor" yazisi kaldirildi (Android yedekleme ile ilerleme yeni telefona da gelebildigi icin yanilticiydi). loc.gd'den progress_note silindi.
- loc.gd: Loc.set_lang(i) eklendi (cycle() artik bunu kullanir).
- NOT: ironSource Ads agi LevelPlay SDK'nin icinde, ayri adaptor gerekmez; export_plugin.gd'de sadece Unity Ads adaptoru olmasi dogru.

--- v23: YEDEKLEME BUTONU ---
- Ayarlar > ILERLEME altina "Yedekleme nasil yapilir?" butonu eklendi (yesil yazinin yerine). Basinca 4 maddelik bilgi penceresi acilir
  (Google yedeklemeyi ac, yedek otomatik ve garanti degil, yeni telefonda ayni hesapla geri gelir). Metinler loc.gd: backup_btn, bk_title, bk1-bk4.
- Pencere TAMAM ya da disina dokununca kapanir (menu.gd: backup_open, _draw_backup).

--- v24: GODOT 4.7.2 + ACILIS ONAYI ---
- Proje Godot 4.7.2 icin ayarlandi (project.godot features "4.7"). Google Play 31 Agustos 2026'dan beri API 36 hedefi istiyor:
  export_presets.cfg gradle_build/target_sdk="36". Ilk acista Godot dosyalari yeni surume cevirir; projenin kopyasini alip ac.
  Export'tan sonra AAB'nin manifest'inde targetSdkVersion=36 yazdigini kontrol et. JDK 17 + Android SDK platform 36 / build-tools 36.1.0 gerekir.
- ACILIS ONAYI (consent.tscn / consent.gd, artik ilk sahne): Kullanim Sartlari + Gizlilik Politikasi, KABUL ET / REDDET.
  Kabul -> "terms_ok" kaydedilir, splash acilir, bir daha sorulmaz. Reddet (ya da Android geri tusu) -> oyun kapanir, her acista tekrar sorar.
  Reklam SDK'si (LevelPlay) onay verilmeden BASLATILMAZ: ads.gd Ads.start() sadece kabulden sonra (ya da daha once kabul edildiyse acilista) calisir.
- TERMS_URL / PRIVACY_URL artik fx_util.gd icinde (menu.gd'den tasindi). Yayindan once gercek bağlantilari yaz; BURAYA_... iken butona basinca "Baglanti henuz eklenmedi" cikar.
- Onayi sifirlayip tekrar test etmek icin: telefonda uygulama verilerini sil (user://terlik_settings.cfg icindeki terms_ok).

--- v25: LINKLER ---
- fx_util.gd: TERMS_URL ve PRIVACY_URL dolduruldu (filinta01453-ui.github.io/AstroFelyx-legal/...). Acilis onayi ve Ayarlar > Hakkinda ayni adresleri kullanir.
- DIKKAT: bu sayfalar "101 Okey" icin yazilmis ve icinde [GELISTIRICI ADI / SIRKET UNVANI], [ADRES], [E-POSTA ADRESI] bos alanlari var. Anne Terligi'ne gore guncelle.

--- v26: GECIS REKLAMI ---
- ads.gd INTERSTITIAL_ID dolduruldu (LevelPlay > Ad units > Interstitial). Ad unit'e Unity Ads + ironSource instance'lari bagli (Networks: 2).
- Geçiş reklami her INTERSTITIAL_EVERY (2) kazanilan bolumde bir, "Sonraki Bolum"e basinca gosterilir. Hazir degilse beklemeden devam eder.

--- v27: OYUN IKONU ---
- Memo + terlik ikonu: assets/icon_512.png (512x512, Play Store listeleme ikonu ve proje ikonu), launcher icin icon_main_192.png,
  adaptive icon icin icon_adaptive_fg_432.png + icon_adaptive_bg_432.png (export_presets.cfg launcher_icons alanlarina baglandi).
- project.godot config/icon artik assets/icon_512.png.
- Play Console > Magaza ayarlari > Uygulama simgesi icin ayni icon_512.png dosyasini yukle (ayri kopya paketin disinda da verildi).

--- v28: SURUM ---
- export_presets.cfg: version/name="2.6.1", version/code=145 (2.6.1+145). Play ayni kodu iki kez kabul etmez; 145 Play'e daha once yuklendiyse 146 ve uzeri yaz.
- package/signed=false (imzasiz AAB; imzayi jarsigner ile sen atiyorsun). menu.gd VERSION = "v2.6.1".

--- v29: GRADLE HATASI DUZELTMESI ---
- android/build/gradle.properties: android.enableJetifier=false (adquality-sdk Jetifier hatasi).
- Not: "Android Build Sablonunu Kur" yapilirsa bu dosya sifirlanir, tekrar false yap.

--- v30: OTOMATIK GRADLE YAMASI ---
- addons/LevelPlayAds/export_plugin.gd: export baslarken android/build/build.gradle e adquality-sdk exclude ekler, gradle.properties te Jetifier kapatir (sablon sifirlansa bile tekrar uygular).

--- v31: android/ klasoru zipten cikarildi (sablona dokunmaz); yama sadece export_plugin.gd uzerinden ---

--- v32: RELEASE IMZA ---
- keys/astrofelyx.keystore (alias astrofelyx-key) eklendi, export_presets.cfg release keystore e baglandi; keys/ ve build/ oyuna paketlenmez.
- Export penceresinde "Hata Ayiklamayla Disa Aktar" KAPALI olmali, Release Password alanina sifreyi bir kere gir (zipte sifre yok).
- Cikti: build/terlik_koridor.aab

--- v33: GITHUB ACTIONS ---
- .github/workflows/android.yml: debug APK + imzasiz AAB uretir (sir/base64 yok).
- Repo kokune .github ve terlik_koridor klasorunu koy; workflow project.godot'u kendisi bulur.
- Actions > "Android (debug APK + imzasiz AAB)" > Run workflow. Ciktilar: terlik_debug.apk, terlik_unsigned.aab
- AAB'yi PC'de imzala: jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore astrofelyx.keystore terlik_unsigned.aab astrofelyx-key
- keys/ klasoru ve keystore zipten cikarildi (GitHub'a yuklenmesin diye).
