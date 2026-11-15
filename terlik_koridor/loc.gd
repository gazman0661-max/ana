extends Node
## ÇEVİRİ (autoload "Loc"). Kullanım:  Loc.t("play")   |   Loc.t("level") % 5   |   Loc.l("poke") -> Array
## Diller: tr, en, es, pt (Brezilya), id. Seçim user://terlik_settings.cfg içinde "lang" olarak saklanır.
## İlk açılışta telefonun diline bakar; desteklenmiyorsa İngilizce.
## Yeni dil eklemek: LANGS ve NAMES'e ekle, S içindeki her satıra bir değer daha yaz.
## "|" ile ayrılmış değerler liste olarak alınır (Loc.l).

signal changed

const SETTINGS_PATH := "user://terlik_settings.cfg"
const LANGS := ["tr", "en", "es", "pt", "id"]
const NAMES := ["TÜRKÇE", "ENGLISH", "ESPAÑOL", "PORTUGUÊS", "INDONESIA"]

var idx := 1

# Sıra: tr, en, es, pt, id
const S = {
	# --- başlık ---
	"t1": ["ANNE", "MOM'S", "LA", "CHINELO", "SANDAL"],
	"t2": ["TERLİĞİ", "SLIPPER", "CHANCLA", "DA MÃE", "IBU"],
	"t3": ["KORİDOR", "HALLWAY", "PASILLO", "CORREDOR", "LORONG"],
	"title_full": ["Anne Terliği", "Mom's Slipper", "La Chancla", "Chinelo da Mãe", "Sandal Ibu"],
	# --- ana menü ---
	"play": ["OYNA", "PLAY", "JUGAR", "JOGAR", "MAIN"],
	"new_game": ["Yeni oyun", "New game", "Juego nuevo", "Novo jogo", "Game baru"],
	"continue": ["Bölüm %d'den devam", "Continue from level %d", "Seguir en nivel %d", "Continuar na fase %d", "Lanjut dari level %d"],
	"how_to": ["NASIL OYNANIR?", "HOW TO PLAY", "¿CÓMO SE JUEGA?", "COMO JOGAR?", "CARA BERMAIN?"],
	"how_to_s": ["Nasıl Oynanır?", "How to Play", "Cómo se juega", "Como jogar", "Cara Bermain"],
	"ok": ["TAMAM!", "OK!", "¡LISTO!", "OK!", "OKE!"],
	"h1": [
		"1. Ekranın alt yarısına dokun, parmağını AŞAĞI çek. Ne kadar çok çekersen terlik o kadar güçlü gider.",
		"1. Touch the lower half of the screen and drag your finger DOWN. The more you pull, the harder the slipper flies.",
		"1. Toca la mitad inferior de la pantalla y arrastra el dedo HACIA ABAJO. Cuanto más tires, más fuerte sale la chancla.",
		"1. Toque na metade de baixo da tela e arraste o dedo para BAIXO. Quanto mais puxar, mais forte o chinelo voa.",
		"1. Sentuh separuh layar bagian bawah dan tarik jari ke BAWAH. Makin jauh ditarik, makin kuat sandal melesat."],
	"h2": [
		"2. Sağa-sola çekerek nişan al. Sapan gibi: sağa çekersen terlik sola gider.",
		"2. Drag sideways to aim. Like a slingshot: pull right and the slipper goes left.",
		"2. Arrastra a los lados para apuntar. Como una resortera: si tiras a la derecha, va a la izquierda.",
		"2. Arraste para os lados para mirar. Como um estilingue: puxe para a direita e o chinelo vai para a esquerda.",
		"2. Geser ke samping untuk membidik. Seperti ketapel: tarik ke kanan, sandal ke kiri."],
	"h3": [
		"3. Bırak = fırlat! Terliği koltuğun ÜSTÜNDEN aşırıp Memo'nun kafasına düşür.",
		"3. Release to throw! Lob the slipper OVER the couch and onto Memo's head.",
		"3. ¡Suelta para lanzar! Pasa la chancla POR ENCIMA del sofá hasta la cabeza de Memo.",
		"3. Solte para lançar! Passe o chinelo POR CIMA do sofá e acerte a cabeça do Memo.",
		"3. Lepas untuk melempar! Lempar sandal MELEWATI sofa dan kenai kepala Memo."],
	"h4": [
		"4. Duvardan sektirebilirsin. Ama vazo ve avize kırarsan Anne duyar!",
		"4. You can bounce it off walls. But if you break a vase or chandelier, Mom will hear!",
		"4. Puedes rebotar en las paredes. ¡Pero si rompes un jarrón o una lámpara, mamá lo oye!",
		"4. Dá para ricochetear nas paredes. Mas se quebrar um vaso ou lustre, a mamãe ouve!",
		"4. Kamu bisa memantulkan ke dinding. Tapi kalau memecahkan vas atau lampu gantung, Ibu dengar!"],
	"h5": [
		"5. Bölümdeki bütün Memo'ları vur, yıldızları topla. Terlik az: boşa atma!",
		"5. Hit every Memo in the level and collect stars. Slippers are limited: don't waste them!",
		"5. Acierta a todos los Memo del nivel y gana estrellas. Hay pocas chanclas: ¡no las desperdicies!",
		"5. Acerte todos os Memos da fase e ganhe estrelas. Os chinelos são poucos: não desperdice!",
		"5. Kenai semua Memo di level ini dan kumpulkan bintang. Sandal terbatas: jangan dibuang!"],
	# --- Memo'nun repliği ve efekt yazıları ---
	"stop": ["YAPMA!", "DON'T!", "¡NO!", "NÃO!", "JANGAN!"],
	"nanik": ["NANİK!", "NYAH NYAH!", "¡BLEH!", "BLÉ!", "WEEK!"],
	"enough": ["BIKTIM ARTIK!", "I'M DONE!", "¡YA BASTA!", "CHEGA!", "CUKUP!"],
	"poke": [
		"AY!|BURNUM!|ANNE!|YAPMADIM!|ÇAT!",
		"OUCH!|MY NOSE!|MOM!|NOT ME!|BONK!",
		"¡AY!|¡MI NARIZ!|¡MAMÁ!|¡YO NO FUI!|¡PAF!",
		"AI!|MEU NARIZ!|MÃE!|NÃO FUI EU!|POW!",
		"AW!|HIDUNGKU!|IBU!|BUKAN AKU!|DUK!"],
	"tak": ["TAK!", "WHACK!", "¡PLAF!", "PLAC!", "TAK!"],
	"wall": [
		"TAK!|TOK!|BOİNG!",
		"WHACK!|THWACK!|BOING!",
		"¡PLAF!|¡TOC!|¡BOING!",
		"PLAC!|TOC!|BOING!",
		"TAK!|DUK!|BOING!"],
	"smash": [
		"ŞANGIR!|ÇANGIR ÇUNGUR!|ANNEM DUYMASIN!",
		"CRASH!|SMASH!|MOM CAN'T KNOW!",
		"¡CRASH!|¡PLAS!|¡MAMÁ NO LO SEPA!",
		"CRASH!|PLÁ!|MAMÃE NÃO VIU!",
		"PRANG!|PYAR!|IBU JANGAN TAHU!"],
	"nopain": ["HİÇ ACIMADI!", "DIDN'T HURT!", "¡NO DOLIÓ!", "NEM DOEU!", "TIDAK SAKIT!"],
	# --- hedef etiketleri ---
	"tag_hizli": ["HIZLI", "FAST", "RÁPIDO", "RÁPIDO", "CEPAT"],
	"tag_kacak": ["KAÇAK", "SNEAKY", "ESQUIVO", "ESQUIVO", "LICIN"],
	"tag_kalin": ["KALIN", "TOUGH", "DURO", "DURO", "TANGGUH"],
	# --- oyun içi ---
	"menu": ["Menü", "Menu", "Menú", "Menu", "Menu"],
	"retry_s": ["Yeniden", "Retry", "Otra vez", "Repetir", "Ulang"],
	"retry": ["Tekrar Oyna", "Play Again", "Jugar otra vez", "Jogar de novo", "Main lagi"],
	"next": ["Sonraki Bölüm", "Next Level", "Siguiente nivel", "Próxima fase", "Level berikutnya"],
	"reward": ["Reklam İzle  +%d Terlik", "Watch Ad  +%d Slippers", "Ver anuncio  +%d chanclas", "Ver anúncio  +%d chinelos", "Tonton Iklan  +%d Sandal"],
	"ad_loading": ["Reklam yükleniyor...", "Loading ad...", "Cargando anuncio...", "Carregando anúncio...", "Memuat iklan..."],
	"level": ["Bölüm %d", "Level %d", "Nivel %d", "Fase %d", "Level %d"],
	"hard": ["ZOR", "HARD", "DIFÍCIL", "DIFÍCIL", "SULIT"],
	"all_hit": ["HEPSİ VURULDU!", "ALL HIT!", "¡TODOS CAÍDOS!", "TODOS NO CHÃO!", "SEMUA KENA!"],
	"memo_hit": ["MEMO VURULDU!", "MEMO HIT!", "¡MEMO CAÍDO!", "MEMO ACERTADO!", "MEMO KENA!"],
	"level_done": ["Bölüm %d tamam", "Level %d complete", "Nivel %d completado", "Fase %d concluída", "Level %d selesai"],
	"out": ["TERLİK BİTTİ!", "SLIPPERS GONE!", "¡SIN CHANCLAS!", "SEM CHINELOS!", "SANDAL HABIS!"],
	"escaped": ["Memo yine yırttı...", "Memo got away again...", "Memo se escapó otra vez...", "O Memo escapou de novo...", "Memo kabur lagi..."],
	"smashed": [
		"Kırdığın eşya: %d  (Anne duymasın!)",
		"Things broken: %d  (Don't tell Mom!)",
		"Cosas rotas: %d  (¡Que mamá no se entere!)",
		"Quebrou: %d  (Que a mamãe não saiba!)",
		"Barang pecah: %d  (Jangan sampai Ibu tahu!)"],
	"rooms": [
		"Aile Koridoru|Mutfak Koridoru|Çılgın Koridor|Kırmızı Salon|Mavi Salon|Saatler Koridoru|Güneşli Oda",
		"Family Hallway|Kitchen Hallway|Crazy Corridor|Red Lounge|Blue Lounge|Clock Hallway|Sunny Room",
		"Pasillo Familiar|Pasillo de la Cocina|Pasillo Loco|Salón Rojo|Salón Azul|Pasillo de Relojes|Cuarto Soleado",
		"Corredor da Família|Corredor da Cozinha|Corredor Maluco|Sala Vermelha|Sala Azul|Corredor dos Relógios|Quarto Ensolarado",
		"Lorong Keluarga|Lorong Dapur|Lorong Gila|Ruang Merah|Ruang Biru|Lorong Jam|Kamar Cerah"],
	# --- öğretici ipuçları (satırlar "|" ile ayrılır) ---
	"hint1": [
		"Parmağını AŞAĞI çek, bırak ve fırlat!|Sağa-sola çekersen nişan alırsın.|Terlik koltuğun ÜSTÜNDEN aşmalı!",
		"Pull your finger DOWN, release to throw!|Drag sideways to aim.|The slipper must fly OVER the couch!",
		"¡Desliza el dedo ABAJO y suelta!|Arrastra a los lados para apuntar.|¡La chancla debe pasar POR ENCIMA del sofá!",
		"Puxe o dedo para BAIXO e solte!|Arraste para os lados para mirar.|O chinelo deve passar POR CIMA do sofá!",
		"Tarik jari ke BAWAH, lepas untuk lempar!|Geser ke samping untuk membidik.|Sandal harus terbang DI ATAS sofa!"],
	"hint1b": [
		"Olmadı, sorun değil!|Daha güçlü çek ya da yönü değiştir.|Noktalı çizgi terliğin yolunu gösterir.",
		"Missed, no problem!|Pull harder or change direction.|The dotted line shows the slipper's path.",
		"¡No pasa nada!|Tira más fuerte o cambia la dirección.|La línea punteada muestra el recorrido.",
		"Errou, sem problema!|Puxe mais forte ou mude a direção.|A linha pontilhada mostra o trajeto.",
		"Meleset, tidak apa-apa!|Tarik lebih kuat atau ganti arah.|Garis titik-titik menunjukkan jalur sandal."],
	"hint2": [
		"2 Memo var!|İkisini de vurman lazım.",
		"2 Memos!|Hit them both.",
		"¡Hay 2 Memos!|Tienes que darles a los dos.",
		"São 2 Memos!|Acerte os dois.",
		"Ada 2 Memo!|Kenai keduanya."],
	"hint3": [
		"Vazo yoluna çıkarsa kırılır!|Üstünden aşırmayı dene.",
		"A vase in the way will break!|Try to lob it over.",
		"¡Si chocas con el jarrón, se rompe!|Intenta pasar por encima.",
		"Se bater no vaso, ele quebra!|Tente passar por cima.",
		"Vas di jalur akan pecah!|Coba lempar melewatinya."],
	"hint4": [
		"3 Memo! Atışlarını boşa harcama.|Ortadaki kayıyor, zamanla.",
		"3 Memos! Don't waste your shots.|The middle one slides, time it.",
		"¡3 Memos! No desperdicies tiros.|El del medio se mueve, calcula.",
		"3 Memos! Não desperdice tiros.|O do meio desliza, cronometre.",
		"3 Memo! Jangan buang lemparan.|Yang tengah bergeser, atur waktunya."],
	"hint5": [
		"MAVİ Memo KAÇAK: koltuğa eğilir.|Kafasını çıkarınca vur!",
		"BLUE Memo is SNEAKY: he ducks down.|Hit him when he pops up!",
		"Memo AZUL ESQUIVA: se agacha tras el sofá.|¡Dale cuando asome la cabeza!",
		"Memo AZUL é ESCORREGADIO: se abaixa.|Acerte quando ele levantar a cabeça!",
		"Memo BIRU LICIN: dia menunduk di sofa.|Kenai saat kepalanya muncul!"],
	"hint6": [
		"SARI Memo HIZLI ve küçük.|Gideceği yeri tahmin et!",
		"YELLOW Memo is FAST and small.|Predict where he's going!",
		"Memo AMARILLO: RÁPIDO y pequeño.|¡Predice hacia dónde va!",
		"Memo AMARELO: RÁPIDO e pequeno.|Preveja para onde ele vai!",
		"Memo KUNING CEPAT dan kecil.|Tebak ke mana dia bergerak!"],
	"hint8": [
		"KIRMIZI Memo KALIN:|2 kere vurman lazım!",
		"RED Memo is TOUGH:|it takes 2 hits!",
		"Memo ROJO es DURO:|¡hay que darle 2 veces!",
		"Memo VERMELHO é DURO:|precisa de 2 acertos!",
		"Memo MERAH TANGGUH:|butuh 2 kali kena!"],
	# --- ayarlar ---
	"settings": ["Seçenekler", "Settings", "Ajustes", "Opções", "Pengaturan"],
	"our_apps": ["Uygulamalarımız", "Our Apps", "Nuestras apps", "Nossos apps", "Aplikasi Kami"],
	"games_btn": ["Oyunlarımız ve Uygulamalarımız", "Our Games & Apps", "Nuestros juegos y apps", "Nossos jogos e apps", "Game & Aplikasi Kami"],
	"apps_note": [
		"Bizim yaptığımız diğer oyunlar ve uygulamalar:",
		"Other games and apps we made:",
		"Otros juegos y apps que hicimos:",
		"Outros jogos e apps que criamos:",
		"Game dan aplikasi lain buatan kami:"],
	"sec_sound": ["SES", "SOUND", "SONIDO", "SOM", "SUARA"],
	"music": ["Müzik", "Music", "Música", "Música", "Musik"],
	"sfx": ["Ses Efektleri", "Sound Effects", "Efectos de sonido", "Efeitos sonoros", "Efek Suara"],
	"sec_device": ["CİHAZ", "DEVICE", "DISPOSITIVO", "DISPOSITIVO", "PERANGKAT"],
	"vib": ["Titreşim", "Vibration", "Vibración", "Vibração", "Getar"],
	"fxs": ["Ekran Efektleri", "Screen Effects", "Efectos de pantalla", "Efeitos de tela", "Efek Layar"],
	"sec_progress": ["İLERLEME", "PROGRESS", "PROGRESO", "PROGRESSO", "KEMAJUAN"],
	"reset": ["Baştan Başla (1. Bölüm)", "Start Over (Level 1)", "Empezar de nuevo (nivel 1)", "Recomeçar (fase 1)", "Mulai Ulang (Level 1)"],
	"reset_ask": ["Emin misin? Tekrar dokun", "Are you sure? Tap again", "¿Seguro? Toca otra vez", "Tem certeza? Toque de novo", "Yakin? Ketuk lagi"],
	"reset_done": ["İlerleme sıfırlandı", "Progress reset", "Progreso reiniciado", "Progresso reiniciado", "Kemajuan direset"],
	"backup_btn": ["Yedekleme nasıl yapılır?", "How to back up progress", "¿Cómo guardar mi progreso?", "Como salvar meu progresso?", "Cara mencadangkan data?"],
	"bk_title": ["YEDEKLEME", "BACKUP", "COPIA", "BACKUP", "CADANGAN"],
	"bk1": [
		"1) Telefonda Ayarlar > Google > Yedekleme bölümünden yedeklemeyi aç. (Menü adı marka ve sürüme göre biraz değişebilir.)",
		"1) On your phone open Settings > Google > Backup and turn backup on. (Menu names may differ slightly by brand and version.)",
		"1) En el teléfono abre Ajustes > Google > Copia de seguridad y actívala. (Los nombres del menú pueden variar según la marca y la versión.)",
		"1) No celular abra Configurações > Google > Backup e ative o backup. (Os nomes dos menus podem variar conforme a marca e a versão.)",
		"1) Di ponsel buka Setelan > Google > Pencadangan lalu aktifkan. (Nama menu bisa sedikit berbeda tergantung merek dan versi.)"],
	"bk2": [
		"2) Yedek otomatik alınır; genelde günde bir kez, telefon şarjdayken ve Wi-Fi'a bağlıyken. Oyunu silmeden önce telefonu bir süre şarjda ve Wi-Fi'da bırak.",
		"2) Backups run automatically, usually about once a day while the phone is charging on Wi-Fi. Before deleting the game, leave the phone charging on Wi-Fi for a while.",
		"2) La copia es automática, normalmente una vez al día con el teléfono cargando y con Wi-Fi. Antes de borrar el juego, deja el teléfono cargando con Wi-Fi un rato.",
		"2) O backup é automático, geralmente uma vez por dia com o celular carregando e no Wi-Fi. Antes de apagar o jogo, deixe o celular carregando no Wi-Fi por um tempo.",
		"2) Pencadangan berjalan otomatis, biasanya sekali sehari saat ponsel mengisi daya dan terhubung Wi-Fi. Sebelum menghapus game, biarkan ponsel mengisi daya di Wi-Fi beberapa saat."],
	"bk3": [
		"3) Yeni telefonda aynı Google hesabıyla giriş yap ve oyunu Play Store'dan yükle; ilerleme kendiliğinden geri gelebilir.",
		"3) On the new phone sign in with the same Google account and install the game from Google Play; your progress can come back automatically.",
		"3) En el teléfono nuevo inicia sesión con la misma cuenta de Google e instala el juego desde Google Play; tu progreso puede volver automáticamente.",
		"3) No celular novo entre com a mesma conta Google e instale o jogo pela Google Play; seu progresso pode voltar automaticamente.",
		"3) Di ponsel baru masuk dengan akun Google yang sama dan instal game dari Google Play; kemajuanmu bisa kembali otomatis."],
	"bk4": [
		"Not: Yedekleme Google/Android tarafından yapılır, garanti edilemez.",
		"Note: Backup is handled by Google/Android and can't be guaranteed.",
		"Nota: La copia depende de Google/Android y no se puede garantizar.",
		"Obs.: O backup depende do Google/Android e não pode ser garantido.",
		"Catatan: Pencadangan dikelola Google/Android dan tidak dapat dijamin."],
	"cs_title": ["HOŞ GELDİN!", "WELCOME!", "¡BIENVENIDO!", "BEM-VINDO!", "SELAMAT DATANG!"],
	"cs_body": [
		"Oyuna başlamadan önce Kullanım Şartları'nı ve Gizlilik Politikası'nı okuyup kabul etmen gerekiyor. Oyunda reklamlar gösterilir. Kabul etmezsen oyun açılmaz.",
		"Before you start, please read and accept the Terms of Use and the Privacy Policy. The game shows ads. If you decline, the game will close.",
		"Antes de empezar, lee y acepta los Términos de uso y la Política de privacidad. El juego muestra anuncios. Si rechazas, el juego se cerrará.",
		"Antes de começar, leia e aceite os Termos de uso e a Política de privacidade. O jogo exibe anúncios. Se recusar, o jogo será fechado.",
		"Sebelum mulai, baca dan setujui Ketentuan Penggunaan dan Kebijakan Privasi. Game ini menampilkan iklan. Jika kamu menolak, game akan ditutup."],
	"cs_accept": ["KABUL ET", "ACCEPT", "ACEPTAR", "ACEITAR", "TERIMA"],
	"cs_reject": ["REDDET", "DECLINE", "RECHAZAR", "RECUSAR", "TOLAK"],
	"sec_lang": ["DİL", "LANGUAGE", "IDIOMA", "IDIOMA", "BAHASA"],
	"sec_help": ["YARDIM", "HELP", "AYUDA", "AJUDA", "BANTUAN"],
	"sec_privacy": ["GİZLİLİK", "PRIVACY", "PRIVACIDAD", "PRIVACIDADE", "PRIVASI"],
	"consent": ["Reklam Rızasını Yönet", "Manage Ad Consent", "Consentimiento de anuncios", "Consentimento de anúncios", "Kelola Persetujuan Iklan"],
	"sec_about": ["HAKKINDA", "ABOUT", "ACERCA DE", "SOBRE", "TENTANG"],
	"terms": ["Kullanım Şartları", "Terms of Use", "Términos de uso", "Termos de uso", "Ketentuan Penggunaan"],
	"privacy": ["Gizlilik Politikası", "Privacy Policy", "Política de privacidad", "Política de privacidade", "Kebijakan Privasi"],
	"download": ["İNDİR", "GET", "BAJAR", "BAIXAR", "UNDUH"],
	"gdesc0": [
		"Gezegenleri birleştir, yeni dünyalar keşfet!",
		"Merge planets and discover new worlds!",
		"¡Une planetas y descubre nuevos mundos!",
		"Una planetas e descubra novos mundos!",
		"Gabungkan planet, temukan dunia baru!"],
	"gdesc1": [
		"Klasik 101 okey keyfi, hemen oyna!",
		"Classic Okey 101 fun, play now!",
		"El clásico Okey 101, ¡juega ya!",
		"O clássico Okey 101, jogue agora!",
		"Serunya Okey 101 klasik, main sekarang!"],
	"gdesc2": [
		"Yapay zekâ ile sohbet et, uygulamanı kur.",
		"Chat with AI and build your app.",
		"Chatea con IA y crea tu app.",
		"Converse com IA e crie seu app.",
		"Ngobrol dengan AI dan buat aplikasimu."],
	"toast_noconsent": [
		"Bu cihazda reklam rızası formu yok",
		"No ad consent form on this device",
		"No hay formulario de consentimiento",
		"Sem formulário de consentimento",
		"Tidak ada formulir persetujuan"],
	"toast_nolink": ["Bağlantı henüz eklenmedi", "Link not added yet", "Enlace aún no disponible", "Link ainda não adicionado", "Tautan belum ditambahkan"],
	"toast_nopkg": ["Paket adı henüz eklenmedi", "Package not added yet", "Paquete aún no disponible", "Pacote ainda não adicionado", "Paket belum ditambahkan"],
}


func _ready() -> void:
	var cf := ConfigFile.new()
	var saved := ""
	if cf.load(SETTINGS_PATH) == OK:
		saved = String(cf.get_value("s", "lang", ""))
	if saved in LANGS:
		idx = LANGS.find(saved)
	else:
		var sys := OS.get_locale_language()
		if sys == "in":
			sys = "id"
		idx = LANGS.find(sys) if sys in LANGS else 1
	_apply_title()


func lang() -> String:
	return LANGS[idx]


func lang_name() -> String:
	return NAMES[idx]


# Sıradaki dile geç ve kaydet.
func cycle() -> void:
	set_lang((idx + 1) % LANGS.size())


# Verilen sıradaki dile geç ve kaydet (dil listesinden seçim).
func set_lang(i: int) -> void:
	idx = clampi(i, 0, LANGS.size() - 1)
	var cf := ConfigFile.new()
	cf.load(SETTINGS_PATH)
	cf.set_value("s", "lang", LANGS[idx])
	cf.save(SETTINGS_PATH)
	_apply_title()
	changed.emit()


func t(key: String) -> String:
	if not S.has(key):
		return key
	return String(S[key][idx])


# "|" ile ayrılmış değeri liste olarak döndürür.
func l(key: String) -> PackedStringArray:
	return t(key).split("|")


# Rastgele bir kelime (efekt yazıları için).
func pick(key: String) -> String:
	var a := l(key)
	return a[randi() % a.size()]


# Oda adı (THEMES içindeki "bg" numarasına göre).
func room(bg: int) -> String:
	var a := l("rooms")
	return a[bg] if bg < a.size() else ""


# Başlığın 1. satırı uzun dillerde (CHINELO, SANDAL) taşmasın diye küçültme çarpanı.
func k1() -> float:
	return [1.0, 0.95, 1.0, 0.8, 0.9][idx]


func _apply_title() -> void:
	DisplayServer.window_set_title(t("title_full"))
