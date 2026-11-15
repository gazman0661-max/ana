extends Node
## SES (autoload "Sfx"): efektler + döngüye giren arka plan müziği.
## Kullanım:  Sfx.play("hit")   |   Sfx.play("hit", 1.1, -3.0)  (ses perdesi, ek dB)
## Ayarlar > Müzik / Ses Efektleri anahtarları U.get_setting("music" / "sfx") ile okunur; menü değişince Sfx.apply_settings() çağırır.
## Dosyalar assets/audio/*.ogg. Dosya yoksa o ses sessizce atlanır.

const U = preload("res://fx_util.gd")
const DIR := "res://assets/audio/"
const POOL := 8
const MUSIC_DB := -15.0

# ad -> temel ses seviyesi (dB). Dosyalar -3 dB tepeye normalize edildi; burada dengeleniyor.
const BASE_DB = {
	"throw": -6.0, "hit": -2.0, "bounce": -4.0, "vase": -2.0, "glass": -3.0,
	"scared": -3.0, "ouch": -3.0, "win": -4.0, "lose": -4.0, "click": -4.0,
}

var streams := {}
var pool: Array = []
var music: AudioStreamPlayer
var sfx_on := true
var music_on := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n: String in BASE_DB.keys():
		var p: String = DIR + n + ".ogg"
		if ResourceLoader.exists(p):
			streams[n] = load(p)
	for i in POOL:
		var pl := AudioStreamPlayer.new()
		add_child(pl)
		pool.append(pl)
	music = AudioStreamPlayer.new()
	music.volume_db = MUSIC_DB
	add_child(music)
	var mp: String = DIR + "music.ogg"
	if ResourceLoader.exists(mp):
		var ms = load(mp)
		if ms != null and "loop" in ms:
			ms.loop = true
		music.stream = ms
	apply_settings()


func apply_settings() -> void:
	sfx_on = U.get_setting("sfx", true)
	music_on = U.get_setting("music", true)
	if music.stream == null:
		return
	if music_on and not music.playing:
		music.play()
	elif not music_on and music.playing:
		music.stop()


func play(sound: String, pitch: float = 1.0, extra_db: float = 0.0) -> void:
	if not sfx_on or not streams.has(sound):
		return
	var pl: AudioStreamPlayer = null
	for p in pool:
		if not p.playing:
			pl = p
			break
	if pl == null:
		pl = pool[0]
	pl.stream = streams[sound]
	pl.volume_db = float(BASE_DB[sound]) + extra_db
	pl.pitch_scale = pitch
	pl.play()


# Telefonda uygulama arka plana gidince ses dursun, dönünce devam etsin.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		music.stream_paused = true
		for p in pool:
			p.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		music.stream_paused = false
		for p in pool:
			p.stream_paused = false
