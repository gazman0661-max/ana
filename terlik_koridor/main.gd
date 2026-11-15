extends Node2D
const U = preload("res://fx_util.gd")
## ANNE TERLİĞİ - v4  |  Godot 4.x
## Yeni: ÇOKLU HEDEF. Bölüm 1 öğretici (tek Memo), sonra hedef sayısı ve hedef tipleri artar:
## memo (normal), hizli (sarı), kacak (mavi, koltuğa eğilir), kalin (kırmızı, 2 vuruş).
## KAM düğmesi = kalibrasyon, TEMA düğmesi = odayı değiştir.

# ---------------- TEMALAR (oda başına kamera kalibrasyonu) ----------------
# vp = kaybolma noktası X, hz = ufuk Y, f = odak, ch = kamera yüksekliği (m)
# x0/x1 = odanın sol/sağ duvarı (m), ze = oda sonu (m)
const THEMES = [
	{"name": "Aile Koridoru", "bg": 0, "vp": 361.0, "hz": 437.0, "f": 1100.0, "ch": 1.186, "x0": -0.80, "x1": 0.66, "ze": 7.9},
	{"name": "Mutfak Koridoru", "bg": 1, "vp": 365.0, "hz": 501.0, "f": 1050.0, "ch": 1.186, "x0": -0.80, "x1": 0.78, "ze": 13.0},
	{"name": "Çılgın Koridor", "bg": 2, "vp": 300.0, "hz": 380.0, "f": 1050.0, "ch": 1.186, "x0": -1.30, "x1": 1.30, "ze": 12.0},
	{"name": "Kırmızı Salon", "bg": 3, "vp": 358.0, "hz": 556.0, "f": 1050.0, "ch": 1.186, "x0": -1.82, "x1": 1.82, "ze": 8.65},
	{"name": "Mavi Salon", "bg": 4, "vp": 362.0, "hz": 544.0, "f": 1050.0, "ch": 1.186, "x0": -1.34, "x1": 1.34, "ze": 6.5},
	{"name": "Saatler Koridoru", "bg": 5, "vp": 366.0, "hz": 446.0, "f": 1050.0, "ch": 1.186, "x0": -2.30, "x1": 2.30, "ze": 12.8},
	{"name": "Güneşli Oda", "bg": 6, "vp": 360.0, "hz": 436.0, "f": 1050.0, "ch": 1.186, "x0": -1.47, "x1": 1.47, "ze": 8.65},
]
const LEVEL_THEMES = [0, 5, 6, 3, 4, 1, 2]   # bölümler bu sırayla oda değiştirir
const LEVELS_PER_THEME := 3

# ---------------- ENGELLER ----------------
# dh = çizim yüksekliği, cw/d = çarpışma genişlik/derinlik, y0..y1 = çarpışma yüksekliği
const OBS = {
	"vazo": {"tex": "vazo", "dh": 0.55, "cw": 0.34, "d": 0.34, "y0": 0.0, "y1": 0.55, "frag": true, "shard_w": 0.55},
	"koltuk": {"tex": "koltuk", "dh": 0.78, "cw": 0.84, "d": 0.55, "y0": 0.0, "y1": 0.74, "frag": false, "shard_w": 0.0},
	"vitrin": {"tex": "vitrin", "dh": 1.9, "cw": 1.1, "d": 0.5, "y0": 0.0, "y1": 1.9, "frag": false, "shard_w": 0.0},
	"lust": {"tex": "lust", "dh": 0.80, "cw": 0.6, "d": 0.6, "y0": 1.15, "y1": 1.95, "frag": true, "shard_w": 1.0},
}
const TEX_NAMES = ["vazo", "koltuk", "vitrin", "lust", "kirik_cam", "terlik", "memo_dil", "memo_gergin", "memo_sersem"]

# ---------------- KAMERA (temadan gelir) ----------------
var theme_idx := 0
var theme_force := -1
var theme_name := ""
var vp_x := 361.0
var horizon := 437.0
var focal := 1100.0
var cam_h := 1.186
var x_min := -0.80
var x_max := 0.66
var z_end := 7.9
var aim_range := 0.7
var start_pos := Vector3(0.39, 0.57, 2.2)

const W := 720.0
const H := 1280.0
const CEIL := 2.4
const FLOOR_Y := 0.04

# ---------------- ATIŞ ----------------
const REL_SCREEN := Vector2(556, 745)     # terliğin elden çıktığı ekran noktası
const START_Z := 2.2
const HELD_POS := Vector2(467, 1030)
const USE_HAND := true                    # true: Anne yerine sadece terliği tutan el; false: eski Anne
const HAND_POS := Vector2(500, 1110)      # elin boşta durduğu nokta
const GRAV := 9.8
const SPEED_MIN := 4.0
const SPEED_MAX := 12.0
const ELEV := 0.35
const Z_REF := 7.0
const MAX_PULL := 220.0
const MIN_PULL := 30.0
const SL_R := 0.11
const SUB := 1.0 / 240.0
const SAVE_PATH := "user://terlik_save.cfg"

# ---------------- REKLAM (LevelPlay, bkz. ads.gd) ----------------
const REWARD_SHOTS := 3              # "Reklam izle" ile verilen terlik sayısı
const MAX_REWARD_CONTINUES := 2      # bir bölümde en fazla kaç kez "reklam izle, +3 terlik"
const INTERSTITIAL_EVERY := 2        # kaç bölümde bir geçiş reklamı

# ---------------- ANNE (sprite) ----------------
const MOM_X := 361.0
const MOM_FEET_Y := 1262.0
const MOM_SCALE := 0.5
const MOM_CANVAS := Vector2(960, 1260)
const MOM_PIVOT := Vector2(480, 1250)

# ---------------- MEMO ----------------
const MEMO_R := 0.20
const MEMO_TOP := 1.35        # koltuğun üstünden görünen kafa/el bölgesinin tepe yüksekliği
const MEMO_BEHIND := 0.55     # koltuğun ne kadar arkasında
const CHAIR_TOP := 0.74       # koltuğun üst kenarı (m)
# SIRA ÖLÇEĞİ: en öndeki sıra en küçük, her arka sıra bir öncekinden büyük (tüm hedefler görünsün).
# Genel küçültme = TARGET_SHRINK (hedef + koltuk birlikte küçülür, oda daha çok hedef alır).
const TARGET_SHRINK := 0.74   # 1.0 = eski boyut
const ROW_STEP := 0.15        # her arka sıra +%15 büyür (x1.0, x1.15, x1.30, x1.45)
const ROW_GAP := 0.40         # z farkı bundan küçükse aynı sıra sayılır
const MAX_ROWS := 4           # derin odalarda en fazla 4 sıra (dar/sığ odalarda _max_rows() düşürür)

# Hedef tipleri: tint = renk tonu, sc = boyut çarpanı, hp = kaç vuruşta düşer
const TYPE_INFO = {
	"memo": {"tint": Color(1, 1, 1), "sc": 1.0, "hp": 1, "tag": ""},
	"hizli": {"tint": Color(1.0, 0.92, 0.45), "sc": 0.85, "hp": 1, "tag": "hizli"},
	"kacak": {"tint": Color(0.70, 0.85, 1.0), "sc": 1.0, "hp": 1, "tag": "kacak"},
	"kalin": {"tint": Color(1.0, 0.68, 0.62), "sc": 1.2, "hp": 2, "tag": "kalin"},
}

enum Phase { AIM, FLY, WIN, LOSE }

var phase: Phase = Phase.AIM
var level := 1
var shots_total := 5
var shots_left := 5
var result_stars := 0
var smashed := 0
var bonus_shots := 0         # reklamla kazanılan terlikler (yıldız hesabı için)
var reward_used := 0         # bu bölümde kaç kez reklam izlendi
var wins_since_ad := 0       # son geçiş reklamından beri kazanılan bölüm
var ad_off := 0.0            # üstteki banner'ın oyunun üstüne bindiği yükseklik (oyun koordinatı)
var ad_busy := false         # ödüllü/geçiş reklamı açıkken tıklamaları yoksay
var pending_next := false    # geçiş reklamı kapanınca sonraki bölüme geçilecek

var targets: Array = []      # hedef Memo'lar (her biri kendi koltuğunun arkasında)
var obstacles: Array = []

var s_active := false
var s_pos := Vector3.ZERO
var s_vel := Vector3.ZERO
var spin := 0.0
var tumble := 0.0
var s_age := 0.0

var dragging := false
var drag_scared := false     # güçlü çekişte Memo bir kez "hoh!" der
var drag_start := Vector2.ZERO
var drag_cur := Vector2.ZERO
var throw_anim := 0.0

var debug_on := false
var held_id := ""
var held_t := 0.0

var buttons: Array = []
var fx: Array = []
var shake := 0.0
var t_global := 0.0
var overlay_t := 0.0
var intro_t := 0.0

var font: Font
var bgs: Array = []
var texs := {}
var mom_idle: Texture2D
var mom_throw: Texture2D
var btn_style: StyleBoxFlat
var btn_style_dark: StyleBoxFlat
var bar_bg: StyleBoxFlat
var bar_fill: StyleBoxFlat
var hand_tex: Texture2D          # assets/el.png varsa o kullanılır, yoksa kodla çizilir
var wall_cd := 0.0
var obs_cd := 0.0
var boing_done := false      # bir atışta koltuk/vitrin yazısı (BOING!) en fazla 1 kez
var wall_tak_done := false   # bir atışta duvar yazısı (TAK!) en fazla 1 kez çıkar
var fx_on := true             # Ayarlar > Ekran Efektleri (sarsıntı)
var vib_on := true            # Ayarlar > Titreşim
var fade_in := 1.0           # menüden gelince siyahtan açılır


func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	for i in THEMES.size():
		bgs.append(load("res://assets/bg%d.jpg" % i))
	for n in TEX_NAMES:
		texs[n] = load("res://assets/%s.png" % n)
	mom_idle = load("res://assets/anne_idle.png")
	mom_throw = load("res://assets/anne_firlat.png")
	btn_style = _make_style(Color(0.93, 0.45, 0.25))
	btn_style_dark = _make_style(Color(0.20, 0.13, 0.10, 0.85))
	bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0, 0, 0, 0.45)
	bar_bg.set_corner_radius_all(11)
	bar_fill = StyleBoxFlat.new()
	bar_fill.set_corner_radius_all(8)
	if ResourceLoader.exists("res://assets/el.png"):
		hand_tex = load("res://assets/el.png")
	fx_on = U.get_setting("fx", true)
	vib_on = U.get_setting("vib", true)
	_load_progress()
	ad_off = Ads.banner_h
	Ads.banner_height_changed.connect(_on_banner_height)
	Ads.rewarded_earned.connect(_on_reward_earned)
	Ads.rewarded_closed.connect(_on_reward_closed)
	Ads.interstitial_done.connect(_on_interstitial_done)
	_setup_level(level)


func _make_style(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(20)
	sb.border_color = Color(c.r * 0.6, c.g * 0.6, c.b * 0.6, c.a)
	sb.set_border_width_all(4)
	return sb


# ---------------- TEMA / KAMERA ----------------
func _theme_for(n: int) -> int:
	if theme_force >= 0:
		return theme_force
	var step := floori(float(n - 1) / float(LEVELS_PER_THEME))
	return LEVEL_THEMES[step % LEVEL_THEMES.size()]


func _apply_theme(i: int) -> void:
	theme_idx = i
	var t: Dictionary = THEMES[i]
	vp_x = t["vp"]
	horizon = t["hz"]
	focal = t["f"]
	cam_h = t["ch"]
	x_min = t["x0"]
	x_max = t["x1"]
	z_end = t["ze"]
	theme_name = Loc.room(int(t["bg"]))
	aim_range = (x_max - x_min) * 0.5 * 0.9
	_update_start()


func _update_start() -> void:
	start_pos = Vector3(
		(REL_SCREEN.x - vp_x) * START_Z / focal,
		cam_h - (REL_SCREEN.y - horizon) * START_Z / focal,
		START_Z)


func _room_w() -> float:
	return x_max - x_min


func _usable() -> float:
	return maxf(_room_w() * 0.5 - 0.36, 0.15)


func _fx_to_x(f: float) -> float:
	return (x_min + x_max) * 0.5 + f * _usable()


# ---------------- BÖLÜM ----------------
func _load_progress() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		level = maxi(1, int(cf.get_value("p", "level", 1)))


func _save_progress(n: int) -> void:
	var cf := ConfigFile.new()
	cf.set_value("p", "level", n)
	cf.save(SAVE_PATH)


func _is_hard(n: int) -> bool:
	return n > 5 and n % 5 == 0


func _is_relief(n: int) -> bool:
	return n > 6 and _is_hard(n - 1)


func _setup_level(n: int) -> void:
	level = n
	_configure_level(n)
	shots_left = shots_total
	bonus_shots = 0
	reward_used = 0
	smashed = 0
	s_active = false
	dragging = false
	throw_anim = 0.0
	overlay_t = 0.0
	intro_t = 2.6
	fx.clear()
	phase = Phase.AIM
	_build_buttons()


func _add_obs(t: String, x: float, z: float) -> Dictionary:
	var o := {"t": t, "x": x, "z": z, "alive": true, "wob": 0.0, "s": 1.0}
	obstacles.append(o)
	return o


# ---- HEDEFLER ----
# Her hedef kendi koltuğunun arkasında. fxp: odanın genişliğine göre -1..1 konum,
# sway_f: salınım payı (0..1), z: koltuğun derinliği, freq: salınım hızı, ph: faz.
func _begin_layout(shots: int) -> void:
	shots_total = shots
	targets.clear()
	obstacles.clear()


func _calc_bx(fxp: float, sway_f: float) -> float:
	return (x_min + x_max) * 0.5 + fxp * _usable() * (1.0 - sway_f)


func _add_target(kind: String, fxp: float, sway_f: float, z: float, freq: float, ph: float = 0.0) -> void:
	_add_target_abs(kind, _calc_bx(fxp, sway_f), sway_f * _usable(), z, freq, ph)


# bx = salınımın orta noktası (m), sw = salınım yarıçapı (m)
func _add_target_abs(kind: String, bx: float, sw: float, z: float, freq: float, ph: float = 0.0) -> void:
	var info: Dictionary = TYPE_INFO[kind]
	var fr := freq * (1.8 if kind == "hizli" else 1.0)
	var chair := _add_obs("koltuk", bx, z)
	targets.append({
		"kind": kind, "bx": bx, "sw": sw, "fr": fr, "z": z, "ph": ph,
		"x": bx, "hp": int(info["hp"]), "hp_max": int(info["hp"]), "sc": float(info["sc"]), "rs": 1.0,
		"vis": 1.0, "dead": false, "fall": 0.0, "cool": 0.0, "chair": chair})


# Hedef + koltuk ölçeği: sıralara göre (ön sıra küçük -> arka sıra büyük).
func _row_scale(r: int) -> float:
	return TARGET_SHRINK * (1.0 + ROW_STEP * float(r))


func _top_y(tg: Dictionary, vis: float) -> float:
	return CHAIR_TOP * float(tg["rs"]) + (MEMO_TOP - CHAIR_TOP) * float(tg["sc"]) * vis


# z'ye göre sıraları bulur (en küçük z = en ön = 0. sıra) ve ölçekleri uygular. Tekrar çağrılabilir.
func _apply_row_scales() -> void:
	var idx: Array = []
	for i in targets.size():
		idx.append(i)
	idx.sort_custom(func(a, b): return float(targets[a]["z"]) < float(targets[b]["z"]))
	var row := -1
	var ref_z := -100.0
	for i in idx:
		var tg: Dictionary = targets[i]
		if float(tg["z"]) - ref_z > ROW_GAP:
			row += 1
			ref_z = float(tg["z"])
		var rs := _row_scale(mini(row, MAX_ROWS - 1))
		tg["rs"] = rs
		tg["sc"] = float(TYPE_INFO[tg["kind"]]["sc"]) * rs
		tg["chair"]["s"] = rs


# Odanın derinliğine göre kaç sıra sığar (sıralar arası en az ~0.55 m).
func _max_rows() -> int:
	var span := minf(6.8, z_end - 0.9) - 4.4
	return clampi(int(span / 0.55) + 1, 2, MAX_ROWS)


# Bir sıradaki koltuk yarı genişliği (+ küçük boşluk)
func _row_h(r: int) -> float:
	return 0.42 * _row_scale(r) + 0.04


# Verilen derinlikte (z) bir koltuk MERKEZİNİN durabileceği [sol, sağ] aralık (m):
# hem oda duvarlarının hem EKRANIN içinde kalır (geniş odalarda ön sıra ekrandan taşmasın).
func _row_range(z: float, h: float) -> Vector2:
	var xc := (x_min + x_max) * 0.5
	var u := _usable()
	var k := focal / maxf(z, 0.1)
	var vl := (0.0 - vp_x) / k + h + 0.03
	var vr := (W - vp_x) / k - h - 0.03
	var lo := maxf(xc - u, vl)
	var hi := minf(xc + u, vr)
	if hi < lo:
		var mid := (lo + hi) * 0.5
		return Vector2(mid, mid)
	return Vector2(lo, hi)


# Sıra kapasitesi için kötümser z tahmini (ön sıraya yakın = ekran dar). Gerçek yerleşim daha geniş olur.
func _row_z_est(r: int) -> float:
	return minf(4.4 + 0.55 * float(r), minf(6.8, z_end - 0.9))


# r. sıraya yan yana en fazla kaç hedef sığar (koltuklar birbirine girmeden, ekranda kalarak).
func _row_max(r: int) -> int:
	var h := _row_h(r)
	var rg := _row_range(_row_z_est(r), h)
	return maxi(1, 1 + int(floor((rg.y - rg.x) / (h * 2.16))))


func _cap_rows(rows: int) -> int:
	var c := 0
	for r in rows:
		c += _row_max(r)
	return c


# Odanın kapasitesi: derinliğin izin verdiği sıra sayısı x her sıraya sığan hedef.
func _target_cap() -> int:
	return clampi(_cap_rows(_max_rows()), 3, 14)


# Hedefleri sıralara dağıt: doluluk oranı en düşük sıraya (eşitlikte arka sıraya) ekler.
func _row_counts(nt: int, rows: int) -> Array:
	var counts: Array = []
	for r in rows:
		counts.append(0)
	for i in nt:
		var best := -1
		var best_ratio := 99.0
		for r in range(rows - 1, -1, -1):
			var mx := _row_max(r)
			if int(counts[r]) >= mx:
				continue
			var ratio := float(counts[r]) / float(mx)
			if ratio < best_ratio:
				best_ratio = ratio
				best = r
		if best < 0:
			break
		counts[best] = int(counts[best]) + 1
	return counts


# ---- BÖLÜM SAYISI / SONSUZ DÖNGÜ ----
# 1-250 üretilir. 250'den sonra 101-250 arası 5'li bloklar (testere dişi bozulmasın diye blok içi sıra aynı)
# her turda farklı karışık sırayla tekrar döner. Ekranda yazan numara (level) artmaya devam eder.
const LEVELS_MAX := 250
const LOOP_FROM := 101


func _eff_level(n: int) -> int:
	if n <= LEVELS_MAX:
		return n
	var idx := n - LEVELS_MAX - 1
	var nb := floori(float(LEVELS_MAX - LOOP_FROM + 1) / 5.0)       # 30 blok
	var cyc := floori(float(idx) / float(nb * 5))
	var j := idx % (nb * 5)
	var order: Array = []
	for bi in nb:
		order.append(bi)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7777 + cyc * 31337
	for i in range(nb - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[k]
		order[k] = tmp
	return LOOP_FROM + int(order[floori(float(j) / 5.0)]) * 5 + (j % 5)


func _all_dead() -> bool:
	for tg in targets:
		if not bool(tg["dead"]):
			return false
	return true


func _first_alive() -> int:
	for i in targets.size():
		if not bool(targets[i]["dead"]):
			return i
	return -1


func _configure_level(n_real: int) -> void:
	var n := _eff_level(n_real)
	_apply_theme(_theme_for(n))
	match n:
		1:      # ÖĞRETİCİ: tek, hareketsiz hedef, bol hak
			_begin_layout(8)
			_add_target("memo", 0.0, 0.0, 5.4, 1.4)
		2:      # 2 hedef, ikisi de sabit
			_begin_layout(6)
			_add_target("memo", -1.0, 0.0, 4.7, 1.4)
			_add_target("memo", 1.0, 0.0, 6.0, 1.4)
		3:      # 2 hedef + kırılan vazo
			_begin_layout(6)
			_add_target("memo", 1.0, 0.0, 4.8, 1.4)
			_add_target("memo", -1.0, 0.0, 6.2, 1.4)
			_add_obs("vazo", _fx_to_x(-0.6), 3.3)
		4:      # 3 hedef, ortadaki kayıyor
			_begin_layout(7)
			_add_target("memo", -0.8, 0.0, 5.0, 1.4)
			_add_target("memo", 0.0, 0.4, 6.4, 1.2)
			_add_target("memo", 0.8, 0.0, 5.0, 1.4)
			_add_obs("vazo", _fx_to_x(0.0), 3.4)
		5:      # KAÇAK tanıtımı
			_begin_layout(6)
			_add_target("memo", -0.7, 0.0, 5.2, 1.4)
			_add_target("kacak", 0.5, 0.0, 6.2, 1.4, 0.0)
		6:      # HIZLI tanıtımı
			_begin_layout(7)
			_add_target("memo", -0.8, 0.0, 5.0, 1.2)
			_add_target("hizli", 0.0, 0.6, 6.3, 1.2)
			_add_target("memo", 0.8, 0.0, 5.0, 1.2)
		7:      # karışık
			_begin_layout(7)
			_add_target("kacak", -0.9, 0.0, 5.0, 1.4, 0.0)
			_add_target("hizli", 0.1, 0.5, 6.4, 1.2)
			_add_target("memo", 0.9, 0.0, 4.9, 1.4)
			_add_obs("vazo", _fx_to_x(-0.3), 3.3)
		8:      # KALIN tanıtımı
			_begin_layout(7)
			_add_target("kalin", 0.0, 0.3, 5.9, 1.2)
			_add_target("memo", -0.8, 0.0, 4.8, 1.4)
			_add_target("memo", 0.8, 0.0, 4.8, 1.4)
		_:
			_generate_level(n)
	_apply_row_scales()
	if n <= 8 and not _solvable():
		print("UYARI: bölüm %d çözülemeyebilir, yerleşimi kontrol et" % n)


func _try_place(t: String, rng: RandomNumberGenerator, z_lo: float, z_hi: float) -> void:
	for k in 6:
		var z := rng.randf_range(z_lo, z_hi)
		var rg := _row_range(z, 0.3)
		var x := clampf(_fx_to_x(rng.randf_range(-1.0, 1.0)), rg.x, rg.y)
		var ok := true
		for o in obstacles:
			if absf(float(o["x"]) - x) < 0.7 and absf(float(o["z"]) - z) < 0.7:
				ok = false
		if ok:
			_add_obs(t, x, z)
			return


# TESTERE DİŞİ ZORLUK: her 5 bölümlük döngüde hedef sayısı lo, lo, lo+1, lo+1, lo+2 (5'in katı = ZOR, tepe).
# Sonraki döngü tekrar lo'dan başlar. lo, 6. bölümden 250. bölüme doğru 3'ten 8'e yavaşça yükselir.
# Geniş odalar aynı zorlukta biraz daha fazla hedef alır (oda boş görünmesin). Oda kapasitesine kırpılır.
func _progress(n: int) -> float:
	return clampf(float(n - 6) / float(LEVELS_MAX - 6), 0.0, 1.0)


func _saw_targets(n: int) -> int:
	var pos := (n - 1) % 5
	var lo := 3 + int(floor(_progress(n) * 5.0))
	return lo + int(floor(float(pos) * 3.0 / 5.0))


# Aynı bölüm numarası her zaman aynı bölümü verir (sabit tohum).
func _generate_level(n: int) -> void:
	var p := _progress(n)
	var saw := float((n - 1) % 5) / 4.0
	var t := clampf(0.1 + p * 0.6 + saw * 0.3, 0.0, 1.0)
	var hard := _is_hard(n)
	var relief := _is_relief(n)
	var cap := _target_cap()
	var over := maxi(_saw_targets(n) - cap, 0)
	t = clampf(t + 0.08 * over, 0.0, 1.0)
	var z_lo := 4.4
	var z_hi := minf(6.8, z_end - 0.9)
	var u := _usable()
	var xc := (x_min + x_max) * 0.5
	var bonus := (1 if _row_max(0) >= 3 else 0) + (1 if _row_max(0) >= 5 else 0)
	var nt0 := clampi(_saw_targets(n) + bonus, 2, cap)
	# Yerleşim kuralı: hedefler sıralara slot slot dizilir, çakışma/başarısızlık olmaz.
	# Hâlâ çözülemezse (vitrin/avize yüzünden) sırayla: aynı sayı farklı tohum -> engelsiz -> 1-2 hedef az.
	for reduce in range(0, 3):
		var nt := maxi(nt0 - reduce, 2)
		for attempt in 4:
			var rng := RandomNumberGenerator.new()
			rng.seed = n * 7919 + 13 + attempt * 104729 + reduce * 1299709
			var sway_max := lerpf(0.30, 0.85, t)
			var base_freq := lerpf(1.2, 2.0, t)
			var p_move := lerpf(0.35, 0.95, p)
			if hard:
				sway_max += 0.1
				base_freq += 0.3
				p_move = minf(p_move + 0.1, 1.0)
			if relief:
				sway_max *= 0.5
				p_move *= 0.7
			sway_max = minf(sway_max, 0.95)
			_begin_layout(0)
			var extra := 0
			var rows := clampi(ceili(float(nt) / 3.0), 2 if nt >= 3 else 1, _max_rows())
			while rows < _max_rows() and _cap_rows(rows) < nt:
				rows += 1
			var counts := _row_counts(nt, rows)
			for r in rows:
				var m: int = counts[r]
				if m == 0:
					continue
				var rs := _row_scale(r)
				var h := _row_h(r)
				var zr := (z_lo + z_hi) * 0.5 if rows == 1 else lerpf(z_lo, z_hi, float(r) / float(rows - 1))
				zr += rng.randf_range(-0.05, 0.05)
				# slot merkezleri (soldan sağa); aralık = oda ∩ ekran, boşluk varsa hafif oynatılır
				var rg := _row_range(zr, h)
				var L := rg.x
				var R := rg.y
				var cs: Array = []
				if m == 1:
					cs.append((L + R) * 0.5 + rng.randf_range(-0.6, 0.6) * (R - L) * 0.5)
				else:
					var sp := (R - L) / float(m - 1)
					var spare := maxf(sp - 2.16 * h, 0.0)
					for j in m:
						var c := L + sp * float(j) + rng.randf_range(-0.4, 0.4) * spare
						cs.append(clampf(c, L, R))
				for j in m:
					var c: float = cs[j]
					var gap := 99.0
					if j > 0:
						gap = minf(gap, c - float(cs[j - 1]))
					if j < m - 1:
						gap = minf(gap, float(cs[j + 1]) - c)
					var cap_gap := (gap - 2.0 * h) * 0.5 if gap < 90.0 else 99.0
					var cap_wall := minf(c - L, R - c)
					var sw := 0.0
					if rng.randf() < p_move:
						sw = minf(rng.randf_range(0.3, 1.0) * sway_max * (R - L) * 0.5, minf(cap_gap, cap_wall))
					if sw < 0.06:
						sw = 0.0
					var rk := rng.randf()
					var p_kalin := 0.10 + 0.20 * t
					var p_kacak := 0.12 + 0.20 * t
					var p_hizli := 0.12 + 0.18 * t
					var kind := "memo"
					if rk < p_kalin:
						kind = "kalin"
						extra += 1
					elif rk < p_kalin + p_kacak:
						kind = "kacak"
					elif rk < p_kalin + p_kacak + p_hizli:
						kind = "hizli"
					var fq := base_freq * rng.randf_range(0.85, 1.15)
					_add_target_abs(kind, c, sw, zr, fq, rng.randf() * TAU)
			var shots := nt + 4 - int(t * 3.0) + extra
			if hard:
				shots -= 1
			if relief:
				shots += 1
			shots_total = clampi(shots, nt + 1, nt + 5)
			if attempt < 3:
				var nv := rng.randi_range(1, 2 + int(t * 2.0))
				for i in nv:
					_try_place("vazo", rng, 2.6, 4.2)
				# Vitrin: atış şeridinin DIŞINDA (eli tuttuğun tarafın karşısı), duvara yaslı, hedeflerin önünü kapatmaz.
				if _room_w() >= 2.4 and rng.randf() < 0.3 + 0.4 * t:
					var side := -1.0 if start_pos.x > xc else 1.0
					var cz := rng.randf_range(3.0, 4.2)
					var kv := focal / cz
					var cx := maxf(x_min + 0.55, (0.0 - vp_x) / kv + 0.6) if side < 0.0 else minf(x_max - 0.55, (W - vp_x) / kv - 0.6)
					var vclear := absf(start_pos.x - cx) - 0.55 > 0.35
					for tg in targets:
						if absf(float(tg["bx"]) - cx) < 0.55 + 0.45 * _row_scale(0) + float(tg["sw"]) + 0.15:
							vclear = false
					for o in obstacles:
						if absf(float(o["x"]) - cx) < 1.0 and absf(float(o["z"]) - cz) < 0.8:
							vclear = false
					if vclear:
						_add_obs("vitrin", cx, cz)
				if rng.randf() < 0.25 + 0.35 * t:
					_try_place("lust", rng, 3.0, 4.6)
			_apply_row_scales()
			if _solvable():
				return
	_begin_layout(6)                           # yedek: 2 sabit hedef
	_add_target("memo", -1.0, 0.0, 4.7, 1.4)
	_add_target("memo", 1.0, 0.0, 6.0, 1.4)


# Çözülebilirlik: her hedefe ızgaradan en az bir atış değmeli (hedefler orta konumda).


func _solvable() -> bool:
	var found: Array = []
	found.resize(targets.size())
	found.fill(false)
	var cnt := 0
	var px := -MAX_PULL
	while px <= MAX_PULL:
		var py := MIN_PULL + 6.0
		while py <= MAX_PULL:
			var hit := _test_shot(Vector2(px, -py))
			if hit >= 0 and not bool(found[hit]):
				found[hit] = true
				cnt += 1
				if cnt == targets.size():
					return true
			py += 14.0
		px += 24.0
	return false


func _in_box(o: Dictionary, p: Vector3) -> bool:
	var od: Dictionary = OBS[o["t"]]
	var os := float(o["s"])
	if absf(p.x - float(o["x"])) > float(od["cw"]) * os * 0.5 + SL_R:
		return false
	if absf(p.z - float(o["z"])) > float(od["d"]) * os * 0.5 + SL_R:
		return false
	var y1 := float(od["y1"]) * (os if float(od["y0"]) <= 0.1 else 1.0)
	return p.y >= float(od["y0"]) - SL_R and p.y <= y1 + SL_R


func _test_shot(pull: Vector2) -> int:
	var p := start_pos
	var v := _launch_velocity(pull)
	for i in 200:
		var r := _sim(p, v, 1.0 / 90.0)
		p = r["p"]
		v = r["v"]
		for o in obstacles:
			if o["alive"] and _in_box(o, p):
				return -1
		for ti in targets.size():
			var tg: Dictionary = targets[ti]
			var rr := MEMO_R * float(tg["sc"]) + SL_R
			var dx := p.x - float(tg["bx"])
			var dz := p.z - (float(tg["z"]) + MEMO_BEHIND)
			var top := _top_y(tg, 1.0)
			if dx * dx + dz * dz <= rr * rr and p.y < top + SL_R:
				return ti
		if r["ev"] == "floor" or p.z < 0.3:
			return -1
	return -1


# ---------------- BUTONLAR ----------------
func _build_buttons() -> void:
	buttons.clear()
	var o := ad_off
	buttons.append({"r": Rect2(20, 20 + o, 120, 60), "id": "menu", "text": Loc.t("menu")})
	if OS.is_debug_build():
		buttons.append({"r": Rect2(150, 20 + o, 120, 60), "id": "kam", "text": "KAM"})
	buttons.append({"r": Rect2(580, 20 + o, 120, 60), "id": "retry", "text": Loc.t("retry_s")})
	if debug_on:
		buttons.append({"r": Rect2(280, 20 + o, 120, 60), "id": "theme", "text": "TEMA"})
		var rows := [["h", "Ufuk"], ["f", "Odak"], ["c", "Yük"], ["x", "Orta"]]
		for i in rows.size():
			var y := 110.0 + o + i * 58.0
			buttons.append({"r": Rect2(20, y, 110, 50), "id": rows[i][0] + "-", "text": rows[i][1] + " -", "small": true})
			buttons.append({"r": Rect2(140, y, 110, 50), "id": rows[i][0] + "+", "text": rows[i][1] + " +", "small": true})
	if phase == Phase.WIN:
		buttons.append({"r": Rect2(140, 780, 440, 100), "id": "next", "text": Loc.t("next"), "result": true})
	elif phase == Phase.LOSE:
		if reward_used < MAX_REWARD_CONTINUES:
			buttons.append({"r": Rect2(110, 770, 500, 100), "id": "reward", "text": Loc.t("reward") % REWARD_SHOTS, "result": true})
			buttons.append({"r": Rect2(160, 890, 400, 90), "id": "retry", "text": Loc.t("retry"), "result": true})
		else:
			buttons.append({"r": Rect2(160, 780, 400, 100), "id": "retry", "text": Loc.t("retry"), "result": true})


func _click_button(pos: Vector2) -> bool:
	if ad_busy:
		return false
	for b in buttons:
		var r: Rect2 = b["r"]
		if not r.has_point(pos):
			continue
		if b.get("result", false) and overlay_t < 0.9:
			continue
		if not (String(b["id"]).length() == 2 and (String(b["id"]).ends_with("+") or String(b["id"]).ends_with("-"))):
			Sfx.play("click")
		_on_button(b["id"])
		return true
	return false


func _go_menu() -> void:
	if ad_busy:
		return
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_button(id: String) -> void:
	if id == "menu":
		_go_menu()
	elif id == "kam":
		debug_on = not debug_on
		if not debug_on and theme_force >= 0:
			theme_force = -1
			_setup_level(level)
		else:
			_build_buttons()
	elif id == "theme":
		theme_force = (theme_idx + 1) % THEMES.size()
		_setup_level(level)
	elif id == "retry":
		_setup_level(level)
	elif id == "reward":
		_watch_ad_for_shots()
	elif id == "next":
		theme_force = -1
		_go_next_level()
	elif id.length() == 2 and (id.ends_with("+") or id.ends_with("-")):
		_nudge(id)
		held_id = id
		held_t = 0.35


# ---------------- REKLAM AKIŞI ----------------
# Terlik bitince: ödüllü reklam izle -> +REWARD_SHOTS terlik, bölüm kaldığı yerden devam eder.
func _watch_ad_for_shots() -> void:
	if ad_busy or phase != Phase.LOSE or not Ads.rewarded_ready:
		return
	if Ads.show_rewarded():
		ad_busy = true


func _on_reward_earned() -> void:
	ad_busy = false
	if phase != Phase.LOSE:
		return
	reward_used += 1
	bonus_shots += REWARD_SHOTS
	shots_left += REWARD_SHOTS
	s_active = false
	dragging = false
	overlay_t = 0.0
	phase = Phase.AIM
	_build_buttons()


func _on_reward_closed() -> void:
	ad_busy = false


# Her INTERSTITIAL_EVERY kazanılan bölümde bir, "Sonraki Bölüm"e basınca geçiş reklamı.
# Reklam hazır değilse beklemeden devam eder, sayaç korunur (bir sonraki fırsatta gösterilir).
func _go_next_level() -> void:
	if wins_since_ad >= INTERSTITIAL_EVERY and not ad_busy and Ads.show_interstitial():
		wins_since_ad = 0
		ad_busy = true
		pending_next = true
		return
	_setup_level(level + 1)


func _on_interstitial_done() -> void:
	ad_busy = false
	if pending_next:
		pending_next = false
		_setup_level(level + 1)


func _on_banner_height(h: float) -> void:
	ad_off = h
	_build_buttons()


func _nudge(id: String) -> void:
	match id:
		"h-":
			horizon -= 2.0
		"h+":
			horizon += 2.0
		"f-":
			focal -= 15.0
		"f+":
			focal += 15.0
		"c-":
			cam_h -= 0.02
		"c+":
			cam_h += 0.02
		"x-":
			vp_x -= 2.0
		"x+":
			vp_x += 2.0
	_update_start()
	print("TEMA %d (%s)  vp=%.1f  hz=%.1f  f=%.0f  ch=%.3f   -> THEMES listesine yaz" % [theme_idx, theme_name, vp_x, horizon, focal, cam_h])


# ---------------- GİRDİ ----------------
func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		var pos := get_global_mouse_position()
		if mb.pressed:
			if _click_button(pos):
				return
			if phase == Phase.AIM and pos.y > 400.0:
				dragging = true
				drag_scared = false
				drag_start = pos
				drag_cur = pos
		else:
			held_id = ""
			if dragging:
				dragging = false
				_try_launch()
		return
	var mm := event as InputEventMouseMotion
	if mm != null and dragging:
		drag_cur = get_global_mouse_position()
		if not drag_scared and (drag_cur - drag_start).y > MAX_PULL * 0.7 and not targets.is_empty():
			drag_scared = true
			Sfx.play("scared", 1.0, -3.0)


# Parmağı ilk %60 çekince oda içine nişan alınır; daha fazla çekince hedef
# duvarın ötesine kayar ve terlik duvara çarpıp seker (sekme atışı).
func _aim_offset(n: float) -> float:
	var a := clampf(absf(n), 0.0, 1.0)
	var half := _room_w() * 0.5
	var off := 0.0
	if a <= 0.6:
		off = a / 0.6 * aim_range
	else:
		off = aim_range + (a - 0.6) / 0.4 * half * 2.0
	return off * signf(n)


func _launch_velocity(pull: Vector2) -> Vector3:
	var t := clampf(-pull.y / MAX_PULL, 0.0, 1.0)
	var spd := lerpf(SPEED_MIN, SPEED_MAX, t)
	var mid := (x_min + x_max) * 0.5
	var tx := mid + _aim_offset(pull.x / MAX_PULL)
	var dir_h := Vector2(tx - start_pos.x, Z_REF - start_pos.z).normalized()
	var vh := spd * cos(ELEV)
	return Vector3(dir_h.x * vh, spd * sin(ELEV), dir_h.y * vh)


func _try_launch() -> void:
	if phase != Phase.AIM:
		return
	var pull := drag_start - drag_cur
	if -pull.y < MIN_PULL:
		return
	s_pos = start_pos
	s_vel = _launch_velocity(pull)
	s_active = true
	s_age = 0.0
	wall_tak_done = false
	boing_done = false
	obs_cd = 0.0
	spin = -0.4
	tumble = 0.0
	shots_left -= 1
	throw_anim = 0.45
	phase = Phase.FLY
	Sfx.play("throw", randf_range(0.95, 1.08))


# ---------------- SİMÜLASYON ----------------
func _sim(p: Vector3, v: Vector3, dt: float) -> Dictionary:
	var ev := ""
	v.y -= GRAV * dt
	p += v * dt
	if p.x < x_min + SL_R:
		p.x = x_min + SL_R
		v.x = absf(v.x) * 0.75
		ev = "side"
	elif p.x > x_max - SL_R:
		p.x = x_max - SL_R
		v.x = -absf(v.x) * 0.75
		ev = "side"
	if p.z > z_end - SL_R:
		p.z = z_end - SL_R
		v.z = -absf(v.z) * 0.45
		ev = "wall"
	if p.y > CEIL - SL_R:
		p.y = CEIL - SL_R
		v.y = -absf(v.y) * 0.5
		ev = "wall"
	if p.y < FLOOR_Y:
		p.y = FLOOR_Y
		if v.y < -0.8:
			v.y = -v.y * 0.42
			v.x *= 0.85
			v.z *= 0.85
			ev = "floor"
		else:
			v.y = 0.0
			v.x *= 1.0 - 2.5 * dt
			v.z *= 1.0 - 2.5 * dt
	return {"p": p, "v": v, "ev": ev}


func _memo_touch(tg: Dictionary, p: Vector3) -> bool:
	if bool(tg["dead"]) or float(tg["cool"]) > 0.0:
		return false
	var dx := p.x - float(tg["x"])
	var dz := p.z - (float(tg["z"]) + MEMO_BEHIND)
	var rr := MEMO_R * float(tg["sc"]) + SL_R
	if dx * dx + dz * dz > rr * rr:
		return false
	# kaçak Memo eğilince kafası alçalır, vurulamaz hale gelir
	var top := _top_y(tg, float(tg["vis"]))
	return p.y < top + SL_R


func _check_obstacles() -> void:
	for o in obstacles:
		if o["alive"] and _in_box(o, s_pos):
			_obstacle_hit(o)
			return


func _obstacle_hit(o: Dictionary) -> void:
	var od: Dictionary = OBS[o["t"]]
	var oz := float(o["z"])
	var mid_y := (float(od["y0"]) + float(od["y1"])) * 0.5
	var c := proj(Vector3(float(o["x"]), mid_y, oz))
	if od["frag"]:
		o["alive"] = false
		smashed += 1
		Sfx.play("glass" if o["t"] == "lust" else "vase")
		fx.append({"pos": Vector2(c.x, c.y), "text": Loc.pick("smash"), "t": 0.0})
		fx.append({"pos": Vector2(c.x, c.y), "shards": true, "w": float(od["shard_w"]) * c.z * 1.5, "t": 0.0})
		s_vel = Vector3(s_vel.x * 0.6, s_vel.y * 0.6, s_vel.z * 0.55)
		shake = maxf(shake, 0.15)
	else:
		o["wob"] = 1.0
		if s_pos.z < oz:
			s_pos.z = oz - float(od["d"]) * float(o["s"]) * 0.5 - SL_R - 0.002
		s_vel = Vector3(s_vel.x * 0.6, absf(s_vel.y) * 0.3, -absf(s_vel.z) * 0.3)
		if obs_cd > 0.0:
			return                      # ses/sarsıntı/yazı her alt adımda değil, en fazla 0.35 sn'de bir
		obs_cd = 0.35
		Sfx.play("bounce", 0.8, -2.0)
		shake = maxf(shake, 0.12)
		if boing_done:
			return                      # yazı bir atışta tek sefer
		boing_done = true
		fx.append({"pos": Vector2(c.x, c.y), "text": Loc.pick("wall"), "t": 0.0})


func _preview(pull: Vector2) -> Array:
	var pts: Array = []
	var p := start_pos
	var v := _launch_velocity(pull)
	var floors := 0
	var has_land := false
	var land := Vector3.ZERO
	var bounces: Array = []
	for i in 480:
		var r := _sim(p, v, SUB)
		p = r["p"]
		v = r["v"]
		if r["ev"] == "side":
			bounces.append(p)
		if r["ev"] == "floor":
			floors += 1
			if not has_land:
				has_land = true
				land = p
			if floors >= 2:
				break
		if i % 6 == 0:
			pts.append(p)
	return [pts, has_land, land, bounces]


func proj(p: Vector3) -> Vector3:
	var k := focal / maxf(p.z, 0.1)
	return Vector3(vp_x + p.x * k, horizon + (cam_h - p.y) * k, k)


# ---------------- DÖNGÜ ----------------
func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	t_global += delta
	if fade_in > 0.0:
		fade_in = maxf(fade_in - delta * 3.0, 0.0)
	wall_cd = maxf(wall_cd - delta, 0.0)
	obs_cd = maxf(obs_cd - delta, 0.0)
	if not fx_on:
		shake = 0.0
	if shake > 0.0:
		shake = maxf(shake - delta, 0.0)
		position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake * 36.0
	else:
		position = Vector2.ZERO
	for f in fx:
		f["t"] = float(f["t"]) + delta
	fx = fx.filter(func(f): return float(f["t"]) < 1.0)
	if throw_anim > 0.0:
		throw_anim -= delta
	if intro_t > 0.0:
		intro_t -= delta
	if held_id != "":
		held_t -= delta
		if held_t <= 0.0:
			_nudge(held_id)
			held_t = 0.06
	for tg in targets:
		var tx := float(tg["bx"]) + sin(t_global * float(tg["fr"]) + float(tg["ph"])) * float(tg["sw"])
		tg["x"] = tx
		var ch: Dictionary = tg["chair"]
		ch["x"] = tx
		if float(tg["cool"]) > 0.0:
			tg["cool"] = float(tg["cool"]) - delta
		if bool(tg["dead"]):
			tg["fall"] = float(tg["fall"]) + delta * 2.5
		elif tg["kind"] == "kacak":
			tg["vis"] = clampf(0.65 + sin(t_global * 1.6 + float(tg["ph"])) * 0.8, 0.0, 1.0)
	for o in obstacles:
		if float(o["wob"]) > 0.0:
			o["wob"] = maxf(float(o["wob"]) - delta * 2.5, 0.0)
	if s_active:
		_update_fly(delta)
	if phase == Phase.WIN or phase == Phase.LOSE:
		overlay_t += delta
	queue_redraw()


func _update_fly(delta: float) -> void:
	s_age += delta
	spin += delta * 9.0
	tumble += delta * 11.0
	var steps := maxi(1, int(ceil(delta / SUB)))
	var dt := delta / float(steps)
	for i in steps:
		var r := _sim(s_pos, s_vel, dt)
		s_pos = r["p"]
		s_vel = r["v"]
		if r["ev"] == "side" and wall_cd <= 0.0:
			_wall_fx()
		_check_obstacles()
		for ti in targets.size():
			if _memo_touch(targets[ti], s_pos):
				_hit_target(ti)
				break
	if phase != Phase.FLY:
		if s_pos.y <= FLOOR_Y + 0.002 and s_vel.length() < 0.6:
			s_active = false
		return
	var done := false
	if s_pos.y <= FLOOR_Y + 0.002 and s_vel.length() < 0.6:
		done = true
	elif s_age > 6.0 or s_pos.z < 0.3:
		done = true
	if done:
		s_active = false
		if shots_left <= 0:
			phase = Phase.LOSE
			Sfx.play("lose")
			overlay_t = 0.0
			_build_buttons()
		else:
			phase = Phase.AIM


func _hit_target(i: int) -> void:
	var tg: Dictionary = targets[i]
	tg["hp"] = int(tg["hp"]) - 1
	Sfx.play("hit", randf_range(0.95, 1.05))
	s_vel = Vector3(s_vel.x * 0.3, 2.0, -absf(s_vel.z) * 0.25)
	var hpos := proj(Vector3(float(tg["x"]), 1.2, float(tg["z"])))
	if int(tg["hp"]) > 0:
		tg["cool"] = 0.9
		shake = maxf(shake, 0.2)
		fx.append({"pos": Vector2(hpos.x, hpos.y), "text": Loc.t("nopain"), "t": 0.0})
		return
	tg["dead"] = true
	tg["fall"] = 0.0
	get_tree().create_timer(0.12).timeout.connect(func(): Sfx.play("ouch", randf_range(0.95, 1.1)))
	if vib_on:
		Input.vibrate_handheld(60)
	shake = 0.25
	fx.append({"pos": Vector2(hpos.x, hpos.y), "text": Loc.pick("poke"), "t": 0.0})
	if not _all_dead():
		return
	wins_since_ad += 1
	var used := shots_total + bonus_shots - shots_left
	var waste := used - targets.size()
	if waste <= 0:
		result_stars = 3
	elif waste <= 2:
		result_stars = 2
	else:
		result_stars = 1
	phase = Phase.WIN
	get_tree().create_timer(0.55).timeout.connect(func(): Sfx.play("win"))
	overlay_t = 0.0
	_save_progress(level + 1)
	_build_buttons()


# ---------------- ÇİZİM ----------------
func _draw() -> void:
	var bg: Texture2D = bgs[int(THEMES[theme_idx]["bg"])]
	if bg != null:
		draw_texture_rect(bg, Rect2(0, 0, W, H), false)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.9, 0.8, 0.5))
	if debug_on:
		_draw_debug_grid()
	# uzaktan yakına sıralı çizim
	var items: Array = []
	for i in obstacles.size():
		items.append({"z": float(obstacles[i]["z"]), "k": "obs", "i": i})
	for ti in targets.size():
		items.append({"z": float(targets[ti]["z"]) - 0.001, "k": "memo", "i": ti})
	if s_active:
		items.append({"z": s_pos.z, "k": "slip", "i": 0})
	items.sort_custom(func(a, b): return a["z"] > b["z"])
	for it in items:
		match it["k"]:
			"obs":
				_draw_obstacle(obstacles[int(it["i"])])
			"memo":
				_draw_memo(int(it["i"]))
			"slip":
				_draw_slipper_3d(s_pos, spin, tumble)
	if level == 1 and phase == Phase.AIM:
		for tg in targets:
			if bool(tg["dead"]):
				continue
			var ap := proj(Vector3(float(tg["x"]), 1.55, float(tg["z"])))
			var by := ap.y + sin(t_global * 5.0) * 5.0
			draw_colored_polygon(PackedVector2Array([Vector2(ap.x - 20, by - 30), Vector2(ap.x + 20, by - 30), Vector2(ap.x, by)]), Color(1, 0.85, 0.2))
	if USE_HAND:
		_draw_hand()
	else:
		_draw_mom()
		if not s_active and phase == Phase.AIM:
			_draw_slipper_screen(HELD_POS, 380.0, -0.35)
	_draw_aim()
	_draw_fx()
	_draw_hud()
	if phase == Phase.WIN or phase == Phase.LOSE:
		if overlay_t > 0.9:
			_draw_result()
	_draw_buttons()
	if Ads.is_stub:
		_draw_fake_banner()
	if fade_in > 0.0:
		draw_rect(Rect2(-40, -40, W + 80, H + 80), Color(0, 0, 0, fade_in))


func _draw_debug_grid() -> void:
	var gc := Color(0, 1, 0.3, 0.8)
	var lc := Color(0, 0.8, 1, 0.8)
	draw_line(Vector2(0, horizon), Vector2(W, horizon), Color(1, 0, 1, 0.9), 3.0)
	for z in [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, z_end]:
		var a := proj(Vector3(x_min, 0, z))
		var b := proj(Vector3(x_max, 0, z))
		draw_line(Vector2(a.x, a.y), Vector2(b.x, b.y), gc, 2.0)
		_ltext("%.0f m" % z, b.x + 6.0, b.y - 4.0, 18, gc)
	for x in [x_min, (x_min + x_max) * 0.5, x_max]:
		var a := proj(Vector3(x, 0, 2.0))
		var b := proj(Vector3(x, 0, z_end))
		draw_line(Vector2(a.x, a.y), Vector2(b.x, b.y), lc, 2.0)
	var d1 := proj(Vector3(x_min, CEIL, z_end))
	var d2 := proj(Vector3(x_max, 0.0, z_end))
	draw_rect(Rect2(d1.x, d1.y, d2.x - d1.x, d2.y - d1.y), Color(1, 0, 0, 0.9), false, 3.0)
	for i in 4:
		var y := 146.0 + i * 58.0
		var txt := ""
		match i:
			0:
				txt = "ufuk = %.0f" % horizon
			1:
				txt = "odak = %.0f" % focal
			2:
				txt = "kam.yük = %.2f" % cam_h
			3:
				txt = "orta = %.0f" % vp_x
		_ltext(txt, 262.0, y, 24, Color.WHITE)
	_ltext("TEMA %d: %s" % [theme_idx, theme_name], 290.0, 62.0, 24, Color.WHITE)
	_text("Izgara resimle çakışana kadar ayarla", 360, 372, 22, Color(1, 1, 1, 0.9))


func _draw_obstacle(o: Dictionary) -> void:
	var od: Dictionary = OBS[o["t"]]
	var ox := float(o["x"])
	var oz := float(o["z"])
	if not o["alive"]:
		var kt: Texture2D = texs["kirik_cam"]
		var gf := proj(Vector3(ox, 0.0, oz))
		var kw := float(od["shard_w"]) * gf.z
		var kh := kw * float(kt.get_height()) / float(kt.get_width())
		draw_texture_rect(kt, Rect2(gf.x - kw * 0.5, gf.y - kh * 0.85, kw, kh), false)
		return
	var tex: Texture2D = texs[od["tex"]]
	var y0 := float(od["y0"])
	var hang := y0 > 0.1
	if hang:
		ox += sin(t_global * 1.6 + oz) * 0.03
	var g := proj(Vector3(ox, y0, oz))
	var k := g.z
	var os := float(o["s"])
	var dh := float(od["dh"]) * (os if not hang else 1.0)
	var w := dh * float(tex.get_width()) / float(tex.get_height())
	var off := sin(t_global * 50.0) * float(o["wob"]) * 8.0
	if not hang:
		draw_set_transform(Vector2(g.x, g.y), 0.0, Vector2(k, k * 0.28))
		draw_colored_polygon(_ell(float(od["cw"]) * os * 0.62, float(od["d"]) * os * 0.5, Vector2.ZERO), Color(0, 0, 0, 0.25))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var top_y := g.y - dh * k
		var ceil_y := horizon + (cam_h - 3.2) * k
		draw_line(Vector2(g.x, top_y), Vector2(g.x, ceil_y), Color(0.35, 0.40, 0.65), maxf(3.0, 0.035 * k))
	draw_texture_rect(tex, Rect2(g.x - w * k * 0.5 + off, g.y - dh * k, w * k, dh * k), false)


func _memo_pose(tg: Dictionary) -> String:
	if bool(tg["dead"]):
		return "hit"
	if phase == Phase.LOSE:
		return "taunt"
	if float(tg["cool"]) > 0.0:
		return "scared"
	var mz := float(tg["z"]) + MEMO_BEHIND
	if s_active and s_vel.z > 0.0 and mz - s_pos.z < 3.5 and absf(s_pos.x - float(tg["x"])) < 1.2:
		return "scared"
	if dragging and phase == Phase.AIM and -(drag_start - drag_cur).y > MAX_PULL * 0.45:
		return "scared"
	return "taunt"


func _draw_memo(i: int) -> void:
	var tg: Dictionary = targets[i]
	var info: Dictionary = TYPE_INFO[tg["kind"]]
	var tint: Color = info["tint"]
	var sc := float(tg["sc"])
	var mx := float(tg["x"])
	var cz := float(tg["z"])
	var pose := _memo_pose(tg)
	if pose == "hit":
		var tex_h: Texture2D = texs["memo_sersem"]
		var gm := proj(Vector3(mx, 0.0, cz + MEMO_BEHIND))
		var t := clampf(float(tg["fall"]), 0.0, 1.0)
		var sc2 := 0.45 + 0.55 * sin(t * PI * 0.5)
		var dhm := 1.25 * gm.z * sc2 * sc
		var wm := dhm * float(tex_h.get_width()) / float(tex_h.get_height())
		var jump := sin(t * PI) * 0.18 * gm.z
		draw_set_transform(Vector2(gm.x, gm.y - jump), sin(t_global * 6.0) * 0.05, Vector2.ONE)
		draw_texture_rect(tex_h, Rect2(-wm * 0.5, -dhm, wm, dhm), false, tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var g := proj(Vector3(mx, CHAIR_TOP * float(tg["rs"]), cz))
	var k := g.z
	var scared := pose == "scared"
	var tex: Texture2D = texs["memo_gergin"] if scared else texs["memo_dil"]
	var wmeters := (0.88 if scared else 0.80) * sc
	var frac := 0.86 if scared else 0.90     # düz kenar çizgisinin sprite içindeki oranı
	var w := wmeters * k
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var h := w * th / tw
	var bob := sin(t_global * 5.0 + float(i)) * 0.012 * k
	var rot := sin(t_global * 30.0) * 0.03 if scared else sin(t_global * 4.0 + float(i)) * 0.035
	var col := tint
	if float(tg["cool"]) > 0.0:
		col = tint.lerp(Color(1.0, 0.25, 0.25), 0.4 + 0.4 * sin(t_global * 25.0))
	var vis := float(tg["vis"])
	var duck := frac * h * (1.0 - vis)
	var pivot := Vector2(g.x, g.y + (1.0 - frac) * h + bob)
	draw_set_transform(pivot, rot, Vector2.ONE)
	if vis >= 0.98:
		draw_texture_rect(tex, Rect2(-w * 0.5, -h, w, h), false, col)
	elif vis > 0.03:
		# eğilirken sprite'ın üst kısmı koltuğun kenarında kesilir
		var vh := h * frac * vis
		draw_texture_rect_region(tex, Rect2(-w * 0.5, -h + duck, w, vh), Rect2(0.0, 0.0, tw, th * frac * vis), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if vis < 0.5:
		return
	var ty := pivot.y - h + duck - 8.0
	if i == _first_alive():
		if scared:
			_otext(Loc.t("stop"), g.x, ty, 26, Color(0.6, 0.9, 1.0))
		else:
			_otext(Loc.t("nanik"), g.x, ty, 26, Color.WHITE)
		ty -= 30.0
	var tag: String = Loc.t("tag_" + String(info["tag"])) if String(info["tag"]) != "" else ""
	if tag != "":
		if int(tg["hp_max"]) > 1:
			tag += " x%d" % int(tg["hp"])
		_otext(tag, g.x, ty, 20, Color(1.0, 0.95, 0.6))


func _draw_mom() -> void:
	var tex: Texture2D = mom_idle
	if throw_anim > 0.0 and mom_throw != null:
		tex = mom_throw
	if tex == null:
		return
	var r := Rect2(
		MOM_X - MOM_PIVOT.x * MOM_SCALE,
		MOM_FEET_Y - MOM_PIVOT.y * MOM_SCALE,
		MOM_CANVAS.x * MOM_SCALE,
		MOM_CANVAS.y * MOM_SCALE)
	draw_texture_rect(tex, r, false)


func _draw_slipper_3d(p: Vector3, sp: float, tb: float) -> void:
	var s := proj(p)
	var g := proj(Vector3(p.x, 0.0, p.z))
	var a := clampf(0.40 - p.y * 0.18, 0.10, 0.40)
	draw_set_transform(Vector2(g.x, g.y), 0.0, Vector2(g.z, g.z * 0.3))
	draw_colored_polygon(_ell(0.17, 0.11, Vector2.ZERO), Color(0, 0, 0, a))
	var sq := 0.35 + 0.65 * absf(cos(tb))
	draw_set_transform(Vector2(s.x, s.y), sp + PI * 0.5, Vector2(s.z, s.z))
	_slipper_sprite(sq)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_slipper_screen(pos: Vector2, k: float, rot: float) -> void:
	draw_set_transform(pos, rot + PI * 0.5, Vector2(k, k))
	_slipper_sprite(1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# terlik.png: uç yukarı bakan dikey sprite; çağıran taraf +90° döndürüp ucu sağa çevirir
func _slipper_sprite(sq: float) -> void:
	draw_texture_rect(texs["terlik"], Rect2(-0.10 * sq, -0.155, 0.20 * sq, 0.31), false)


func _wall_fx() -> void:
	wall_cd = 0.3
	Sfx.play("bounce", randf_range(0.95, 1.1))
	shake = maxf(shake, 0.05)
	if wall_tak_done:
		return                      # yazı bir atışta tek sefer; ses + sarsıntı yeter
	wall_tak_done = true
	var c := proj(s_pos)
	fx.append({"pos": Vector2(c.x, c.y), "text": Loc.t("tak"), "t": 0.0})


func _draw_aim() -> void:
	if not dragging or phase != Phase.AIM:
		return
	var pull := drag_start - drag_cur
	var t := clampf(-pull.y / MAX_PULL, 0.0, 1.0)
	# güç çubuğu
	var bx := 28.0
	var by := 1040.0
	var bh := 200.0
	draw_style_box(bar_bg, Rect2(bx, by, 22, bh))
	if t > 0.02:
		bar_fill.bg_color = Color(0.4, 0.9, 0.4).lerp(Color(0.95, 0.3, 0.2), t)
		var fh := (bh - 6.0) * t
		draw_style_box(bar_fill, Rect2(bx + 3.0, by + bh - 3.0 - fh, 16, fh))
	if -pull.y < MIN_PULL:
		return
	var res := _preview(pull)
	var pts: Array = res[0]
	var n := pts.size()
	for i in n:
		if i < 3:
			continue
		var s := proj(pts[i])
		var a := lerpf(1.0, 0.6, float(i) / maxf(float(n), 1.0))
		var rad := clampf(0.022 * s.z, 5.0, 11.0)
		draw_circle(Vector2(s.x, s.y), rad + 3.0, Color(0.1, 0.05, 0.05, a * 0.75))   # koyu kenar: her zeminde seçilsin
		draw_circle(Vector2(s.x, s.y), rad, Color(1.0, 0.97, 0.7, a))
	var bounces: Array = res[3]
	for b in bounces:
		var bs := proj(b)
		draw_arc(Vector2(bs.x, bs.y), maxf(10.0, 0.08 * bs.z), 0.0, TAU, 20, Color(0.4, 0.95, 1.0, 1.0), 6.0)



# ---------------- EL (Anne yerine) ----------------
func _hand_offset() -> Vector2:
	var off := Vector2.ZERO
	if throw_anim > 0.0:
		var u := 1.0 - throw_anim / 0.45
		off = Vector2(-20.0 * sin(u * PI), -330.0 * sin(u * PI))   # savurma
	elif dragging and phase == Phase.AIM:
		var pl := drag_cur - drag_start
		off = Vector2(clampf(pl.x * 0.4, -90.0, 90.0), clampf(pl.y * 0.5, -40.0, 130.0))
	else:
		off.y = sin(t_global * 2.0) * 4.0
	return off


func _poly(pts: PackedVector2Array, fill: Color, line: Color, w: float) -> void:
	draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, line, w)


func _draw_hand() -> void:
	var off := _hand_offset()
	var pos := HAND_POS + off
	var rot := clampf(off.x / 90.0, -1.0, 1.0) * 0.15
	var holding := (not s_active) and phase == Phase.AIM
	if holding:
		_draw_slipper_screen(pos + Vector2(8.0, -118.0), 840.0, -1.15)
	if hand_tex != null:
		var hw := 330.0
		var hh := hw * float(hand_tex.get_height()) / float(hand_tex.get_width())
		draw_set_transform(pos, rot, Vector2.ONE)
		draw_texture_rect(hand_tex, Rect2(-hw * 0.5, -hh * 0.18, hw, hh), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var skin := Color(0.98, 0.78, 0.64)
	var shade := Color(0.93, 0.64, 0.50)
	var ln := Color(0.42, 0.20, 0.12)
	draw_set_transform(pos, rot, Vector2.ONE)
	# kol (ekranın altına doğru uzanır)
	_poly(PackedVector2Array([Vector2(-44, 30), Vector2(48, 30), Vector2(78, 420), Vector2(-26, 420)]), skin, ln, 5.0)
	draw_line(Vector2(-30, 60), Vector2(-8, 400), shade, 14.0)
	# yumruk gövdesi
	_poly(_ell(68.0, 54.0, Vector2(0, 0)), skin, ln, 5.0)
	# parmak boğumları (önce çerçeve, sonra dolgu)
	var kn := [Vector2(-48, -40), Vector2(-16, -50), Vector2(16, -50), Vector2(48, -40)]
	for c in kn:
		draw_circle(c, 29.0, ln)
	draw_circle(Vector2(-68, 6), 27.0, ln)
	draw_circle(Vector2(-58, -22), 27.0, ln)
	for c in kn:
		draw_circle(c, 25.0, skin)
	draw_circle(Vector2(-68, 6), 23.0, skin)
	draw_circle(Vector2(-58, -22), 23.0, skin)
	for c in kn:
		draw_circle(c + Vector2(-5, -6), 8.0, Color(1, 0.9, 0.82, 0.8))
	for x in [-32.0, 0.0, 32.0]:
		draw_line(Vector2(x, -52), Vector2(x, -24), ln, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_fx() -> void:
	for f in fx:
		var t: float = f["t"]
		var pos: Vector2 = f["pos"]
		if f.has("shards"):
			var kt: Texture2D = texs["kirik_cam"]
			var w: float = float(f["w"]) * (0.8 + 0.5 * t)
			var h := w * float(kt.get_height()) / float(kt.get_width())
			draw_texture_rect(kt, Rect2(pos.x - w * 0.5, pos.y - h * 0.5 + t * 40.0, w, h), false, Color(1, 1, 1, 1.0 - t))
		else:
			_otext(f["text"], pos.x, pos.y - t * 90.0, 36, Color(1, 0.9, 0.3, 1.0 - t))


func _draw_hud() -> void:
	var o := ad_off
	draw_rect(Rect2(0, o, W, 100), Color(0, 0, 0, 0.30))
	var hard_txt := ("  •  " + Loc.t("hard")) if _is_hard(_eff_level(level)) else ""
	_otext(Loc.t("level") % level + hard_txt, 360, 46 + o, 30, Color(1, 0.8, 0.25) if _is_hard(_eff_level(level)) else Color.WHITE)
	for i in shots_left:
		var x := 360.0 + (i - (shots_left - 1) * 0.5) * 46.0
		_draw_slipper_screen(Vector2(x, 78 + o), 140.0, 0.0)
	if targets.size() > 1:
		var left := 0
		for tg in targets:
			if not bool(tg["dead"]):
				left += 1
		_otext("Memo: %d / %d" % [targets.size() - left, targets.size()], 360, 132 + o, 24, Color(1, 0.95, 0.8))
	if intro_t > 0.0 and not debug_on:
		_otext(theme_name, 360, 172 + o, 30, Color(1, 1, 1, clampf(intro_t, 0.0, 1.0)))
	if phase == Phase.AIM and not dragging and not debug_on:
		_draw_hint()


# Bölüm başında (ve öğreticide ıskalayınca) gösterilen ipuçları.
func _level_hint() -> Array:
	var first := shots_left == shots_total and bonus_shots == 0
	match level:
		1:
			return Array(Loc.l("hint1" if first else "hint1b"))
		2, 3, 4, 5, 6, 8:
			if first:
				return Array(Loc.l("hint%d" % level))
	return []


func _draw_hint() -> void:
	var lines := _level_hint()
	if lines.is_empty():
		return
	var ph := 24.0 + lines.size() * 34.0
	var o := ad_off
	draw_rect(Rect2(30, 190 + o, 660, ph), Color(0, 0, 0, 0.5))
	for i in lines.size():
		_text(String(lines[i]), 360, 190.0 + o + 38.0 + i * 34.0, 24, Color(1, 0.95, 0.7) if i == 0 else Color.WHITE)


func _draw_result() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.6))
	if phase == Phase.WIN:
		_otext(Loc.t("all_hit") if targets.size() > 1 else Loc.t("memo_hit"), 360, 380, 60, Color(1, 0.85, 0.3))
		for s in 3:
			var col := Color(1, 0.85, 0.2) if s < result_stars else Color(0.5, 0.5, 0.5)
			_draw_star(Vector2(200 + s * 160, 540), 62.0, col)
		_text(Loc.t("level_done") % level, 360, 700, 28, Color.WHITE)
	else:
		_otext(Loc.t("out"), 360, 420, 60, Color(1, 0.4, 0.3))
		_text(Loc.t("escaped"), 360, 500, 34, Color.WHITE)
	if smashed > 0:
		_text(Loc.t("smashed") % smashed, 360, 740, 26, Color(1, 0.8, 0.5))


func _draw_buttons() -> void:
	for b in buttons:
		var r: Rect2 = b["r"]
		if b.get("result", false) and overlay_t < 0.9:
			continue
		var small: bool = b.get("small", false)
		var dark: bool = small or b["id"] == "menu" or b["id"] == "kam" or b["id"] == "theme" or b["id"] == "retry" and not b.get("result", false)
		var label: String = b["text"]
		if b["id"] == "reward" and not Ads.rewarded_ready:
			dark = true
			label = Loc.t("ad_loading")
		draw_style_box(btn_style_dark if dark else btn_style, r)
		var fsize := 22 if small else (26 if dark else 34)
		if b["id"] == "reward":
			fsize = 30
		_text(label, r.get_center().x, r.position.y + r.size.y * 0.5 + fsize * 0.35, fsize, Color.WHITE)


# Sadece editörde: gerçek banner'ın nereye geleceğini gösterir.
func _draw_fake_banner() -> void:
	draw_rect(Rect2(0, 0, W, ad_off), Color(0.15, 0.15, 0.18, 0.95))
	_text("TEST BANNER (gerçekte LevelPlay reklamı)", 360, ad_off * 0.5 + 8.0, 22, Color(0.8, 0.8, 0.85))


func _draw_star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		var rad := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	draw_colored_polygon(pts, col)


func _ell(rx: float, ry: float, off: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		pts.append(off + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# ---------------- METİN ----------------
func _text(txt: String, cx: float, y: float, fsize: int, col: Color) -> void:
	draw_string(font, Vector2(cx - 500.0, y), txt, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, fsize, col)


func _ltext(txt: String, x: float, y: float, fsize: int, col: Color) -> void:
	draw_string(font, Vector2(x, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fsize, col)


func _otext(txt: String, cx: float, y: float, fsize: int, col: Color) -> void:
	var pos := Vector2(cx - 500.0, y)
	draw_string_outline(font, pos, txt, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, fsize, 8, Color(0.1, 0.05, 0.05, col.a))
	draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, fsize, col)
