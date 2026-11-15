extends Node
## REKLAM KÖPRÜSÜ (autoload: "Ads")  |  LevelPlay (ironSource + Unity Ads mediation)
## Android'de LevelPlayAds eklentisini kullanır. Editörde / PC'de eklenti yoktur,
## bu yüzden "stub" modunda çalışır: reklam hemen "izlenmiş" sayılır, sahte banner çizilir.

signal banner_height_changed(h: float)   # banner'ın oyunun üstüne bindiği yükseklik (720 genişlikli oyun koordinatı)
signal rewarded_earned                   # oyuncu ödüllü reklamı tamamladı (kapanıştan SONRA da gelebilir)
signal rewarded_closed                   # ödüllü reklam kapandı ya da gösterilemedi
signal interstitial_done                 # geçiş reklamı kapandı (ya da gösterilemedi) -> oyun devam etsin

const U = preload("res://fx_util.gd")
const PLUGIN_NAME := "LevelPlayAds"

# >>> LevelPlay panelinden al: Setup > Ad Units (app key ve 3 ad unit id) <<<
const APP_KEY := "2734447fd"
const BANNER_ID := "49c6c5wjz2gagjlb"
# Geçiş reklamı (Interstitial ad unit). Boş bırakılırsa geçiş reklamı kapanır.
const INTERSTITIAL_ID := "b4n74kzvfdds7wls"
const REWARDED_ID := "2eiwf0yysehblsw1"

const STUB_BANNER_PX := 100.0            # editörde sahte banner yüksekliği (oyun koordinatı)
const GAME_W := 720.0
const GAME_H := 1280.0

var is_stub := true
var banner_h := 0.0
var rewarded_ready := false
var interstitial_ready := false

var _p: Object = null
var _started := false


func _ready() -> void:
	if OS.get_name() == "Android" and Engine.has_singleton(PLUGIN_NAME):
		is_stub = false
		_p = Engine.get_singleton(PLUGIN_NAME)
		_p.connect("init_failed", func(msg: String): push_warning("LevelPlay init hatası: " + msg))
		_p.connect("banner_loaded", _on_banner_loaded)
		_p.connect("rewarded_ready", func(): rewarded_ready = true)
		_p.connect("rewarded_unavailable", func(): rewarded_ready = false)
		_p.connect("rewarded_earned", func(): rewarded_earned.emit())
		_p.connect("rewarded_closed", func(): rewarded_closed.emit())
		_p.connect("interstitial_ready", func(): interstitial_ready = true)
		_p.connect("interstitial_unavailable", func(): interstitial_ready = false)
		_p.connect("interstitial_closed", _on_interstitial_closed)
		# Reklam SDK'sı kullanıcı Kullanım Şartları/Gizlilik'i kabul edene kadar BAŞLATILMAZ (consent.gd -> Ads.start()).
		if U.get_setting("terms_ok", false):
			start()
	else:
		is_stub = true
		rewarded_ready = true
		interstitial_ready = INTERSTITIAL_ID != ""
		banner_h = STUB_BANNER_PX


# Reklam SDK'sını başlat (onay verildikten sonra çağrılır; birden fazla çağrılsa da bir kez çalışır).
func start() -> void:
	if _started or is_stub or _p == null:
		return
	_started = true
	_p.initAds(APP_KEY, BANNER_ID, INTERSTITIAL_ID, REWARDED_ID)


# Banner piksel yüksekliğini oyun koordinatına çevirir.
# Proje 720x1280 + aspect "keep": ekran daha uzunsa üstte siyah bant olur,
# banner önce o banda biner; sadece bandı aşan kısım oyunu kapatır.
func _on_banner_loaded(h_px: int) -> void:
	var s := DisplayServer.window_get_size()
	var sc := minf(s.x / GAME_W, s.y / GAME_H)
	var bar := (s.y - GAME_H * sc) * 0.5
	banner_h = maxf(0.0, float(h_px) - bar) / sc
	banner_height_changed.emit(banner_h)


func _on_interstitial_closed() -> void:
	interstitial_ready = false
	interstitial_done.emit()


# Ödüllü reklamı göster. true = gösteriliyor (sonucu rewarded_earned sinyali bildirir).
func show_rewarded() -> bool:
	if is_stub:
		get_tree().create_timer(0.6).timeout.connect(func():
			rewarded_earned.emit()
			rewarded_closed.emit())
		return true
	if not rewarded_ready:
		return false
	rewarded_ready = false
	_p.showRewarded()
	return true


# Geçiş reklamını göster. true = gösteriliyor (bitince interstitial_done gelir).
# false = hazır değil, oyun beklemeden devam etsin.
func show_interstitial() -> bool:
	if INTERSTITIAL_ID == "":
		return false
	if is_stub:
		get_tree().create_timer(0.6).timeout.connect(func(): interstitial_done.emit())
		return true
	if not interstitial_ready:
		return false
	interstitial_ready = false
	_p.showInterstitial()
	return true


# Reklam rızası (GDPR/UMP) formunu aç. Eklentide showPrivacyOptions() yoksa false döner.
func show_privacy_options() -> bool:
	if is_stub or _p == null or not _p.has_method("showPrivacyOptions"):
		return false
	_p.showPrivacyOptions()
	return true
