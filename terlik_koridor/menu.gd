extends Node2D
## ANA MENÜ: dalgalı başlık, düşen terlikler, dönen ışınlar, Memo (dokununca sersemler),
## büyük OYNA butonu (basınca terlik Memo'ya uçar, sonra oyun başlar), NASIL OYNANIR penceresi.

const U = preload("res://fx_util.gd")
const W := 720.0
const H := 1280.0
const GAME_SCENE := "res://main.tscn"
const SAVE_PATH := "user://terlik_save.cfg"

# >>> BURAYI DOLDUR: Play Store paket adların ve politika bağlantıların <<<
const VERSION := "v2.6.1"
const GAMES = [
	{"name": "Merge Dünyaları", "desc": "Gezegenleri birleştir, yeni dünyalar keşfet!", "pkg": "BURAYA_PAKET_ADI", "col": Color(0.55, 0.30, 0.85)},
	{"name": "Okey 101", "desc": "Klasik 101 okey keyfi, hemen oyna!", "pkg": "BURAYA_PAKET_ADI", "col": Color(0.15, 0.55, 0.35)},
	{"name": "AstroFelyx AI", "desc": "Yapay zekâ ile sohbet et, uygulamanı kur.", "pkg": "BURAYA_PAKET_ADI", "col": Color(0.15, 0.45, 0.85)},
]

enum Pose { DIL, GERGIN, SERSEM }

var t := 0.0
var font: Font
var bg: Texture2D
var tex_slip: Texture2D
var tex_memo := {}
var ad_off := 0.0
var best_level := 1

var parts: Array = []          # düşen terlikler
var sparks: Array = []         # parlayan yıldızlar

var memo_pose: int = Pose.DIL
var memo_pose_t := 0.0         # sersem / gergin pozunun kalan süresi
var memo_taps := 0
var memo_talk := ""
var memo_talk_t := 0.0

var press_id := ""             # basılı tutulan buton
var help_open := false
var help_t := 0.0

var starting := false          # OYNA'ya basıldı, geçiş animasyonu
var start_t := 0.0
var shake := 0.0
var fx: Array = []             # {pos, text, t}

var st_play: StyleBoxFlat
var st_play_hi: StyleBoxFlat
var st_help: StyleBoxFlat
var st_help_hi: StyleBoxFlat
var st_panel: StyleBoxFlat
var st_sheet: StyleBoxFlat
var st_box: StyleBoxFlat
var st_card: StyleBoxFlat
var st_toast: StyleBoxFlat

var page := "main"             # "main" | "settings" | "games"
var cur_items: Array = []
var cur_h := 0.0
var set_items: Array = []
var set_h := 0.0
var game_items: Array = []
var game_h := 0.0
var scroll := 0.0
var scroll_start := 0.0
var scroll_drag := false
var drag_moved := false
var press_pos := Vector2.ZERO
var opts := {"music": true, "sfx": true, "vib": true, "fx": true}
var backup_open := false       # yedekleme bilgi penceresi açık mı
var lang_open := false         # dil listesi penceresi açık mı
var toast_txt := ""
var toast_t := 0.0


func _ready() -> void:
	randomize()
	font = U.make_font()
	bg = load("res://assets/bg0.jpg")
	tex_slip = load("res://assets/terlik.png")
	for n in ["memo_dil", "memo_gergin", "memo_sersem"]:
		tex_memo[n] = load("res://assets/%s.png" % n)
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		best_level = maxi(1, int(cf.get_value("p", "level", 1)))
	ad_off = Ads.banner_h
	Ads.banner_height_changed.connect(_on_banner)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 11:
		parts.append({"x": rng.randf_range(0.0, W), "y": rng.randf_range(0.0, H + 260.0), "v": rng.randf_range(55.0, 120.0),
			"r": rng.randf_range(0.0, TAU), "rv": rng.randf_range(-2.5, 2.5), "h": rng.randf_range(70.0, 130.0), "ph": rng.randf_range(0.0, TAU)})
	for i in 20:
		sparks.append({"x": rng.randf_range(20.0, 700.0), "y": rng.randf_range(60.0, 1220.0), "ph": rng.randf_range(0.0, TAU), "s": rng.randf_range(9.0, 22.0)})
	st_play = _style(Color(0.22, 0.78, 0.30), Color(0.08, 0.30, 0.12), 34)
	st_play_hi = _style(Color(0.55, 0.95, 0.55, 0.65), Color(0, 0, 0, 0), 26)
	st_help = _style(Color(0.93, 0.45, 0.25), Color(0.35, 0.13, 0.05), 28)
	st_help_hi = _style(Color(1.0, 0.75, 0.5, 0.6), Color(0, 0, 0, 0), 20)
	st_panel = _style(Color(0.99, 0.94, 0.80), Color(0.35, 0.13, 0.05), 30)
	st_sheet = StyleBoxFlat.new()
	st_sheet.bg_color = Color(0.99, 0.94, 0.80)
	st_sheet.corner_radius_top_left = 44
	st_sheet.corner_radius_top_right = 44
	st_box = _style(Color.WHITE, Color(0.35, 0.13, 0.05), 12)
	st_box.set_border_width_all(4)
	st_box.shadow_size = 0
	st_card = _style(Color(1.0, 0.98, 0.9), Color(0.35, 0.13, 0.05), 28)
	st_toast = _style(Color(0.15, 0.06, 0.04, 0.92), Color(0, 0, 0, 0), 24)
	for k in opts.keys():
		opts[k] = U.get_setting(k, true)
	_build_settings()
	_build_games()


func _on_banner(h: float) -> void:
	ad_off = h


func _style(c: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	if border.a > 0.0:
		s.set_border_width_all(7)
		s.border_color = border
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = 10
		s.shadow_offset = Vector2(0, 8)
	return s


# ---------------- DÜZEN ----------------
func _play_rect() -> Rect2:
	return Rect2(110.0, 690.0, 500.0, 128.0)


func _help_rect() -> Rect2:
	return Rect2(170.0, 836.0, 380.0, 82.0)


func _memo_rect() -> Rect2:
	return Rect2(190.0, 960.0, 340.0, 320.0)


func _close_rect() -> Rect2:
	return Rect2(210.0, 980.0, 300.0, 90.0)


# ---------------- GİRDİ ----------------
func _input(event: InputEvent) -> void:
	if starting:
		return
	var mm := event as InputEventMouseMotion
	if mm != null:
		if scroll_drag and page != "main":
			var d := get_global_mouse_position().y - press_pos.y
			if absf(d) > 14.0:
				drag_moved = true
			if drag_moved:
				scroll = clampf(scroll_start - d, 0.0, _scroll_max())
		return
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var pos := get_global_mouse_position()
	if page != "main" and not help_open:
		_page_input(mb.pressed, pos)
		return
	if mb.pressed:
		if help_open:
			press_id = "close" if _close_rect().has_point(pos) else ""
		elif _play_rect().has_point(pos):
			press_id = "play"
		elif _help_rect().has_point(pos):
			press_id = "help"
		elif _gear_rect().has_point(pos):
			press_id = "gear"
		elif _memo_rect().has_point(pos):
			press_id = "memo"
		else:
			press_id = ""
		return
	# bırakma
	var id := press_id
	press_id = ""
	if id == "":
		return
	var ok := false
	match id:
		"play":
			ok = _play_rect().has_point(pos)
		"help":
			ok = _help_rect().has_point(pos)
		"close":
			ok = _close_rect().has_point(pos)
		"memo":
			ok = _memo_rect().has_point(pos)
		"gear":
			ok = _gear_rect().has_point(pos)
	if not ok:
		return
	match id:
		"play":
			starting = true
			start_t = 0.0
			Sfx.play("scared", 1.0, -3.0)
			get_tree().create_timer(0.15).timeout.connect(func(): Sfx.play("throw"))
			memo_pose = Pose.GERGIN
			memo_pose_t = 99.0
			_say(Loc.t("stop"))
		"help":
			Sfx.play("click")
			help_open = true
			help_t = 0.0
		"close":
			Sfx.play("click")
			help_open = false
		"memo":
			_poke_memo()
		"gear":
			Sfx.play("click")
			_open_page("settings")


func _say(txt: String) -> void:
	memo_talk = txt
	memo_talk_t = 1.2


func _poke_memo() -> void:
	memo_taps += 1
	Sfx.play("hit", randf_range(0.95, 1.08))
	get_tree().create_timer(0.1).timeout.connect(func(): Sfx.play("ouch", randf_range(0.95, 1.15)))
	memo_pose = Pose.SERSEM
	memo_pose_t = 1.0
	shake = 0.2
	_say(Loc.pick("poke"))
	fx.append({"pos": Vector2(360.0, 1040.0), "text": Loc.t("tak"), "t": 0.0})
	if memo_taps % 5 == 0:
		_say(Loc.t("enough"))


# ---------------- ZAMAN ----------------
func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	t += delta
	if help_open:
		help_t += delta
	if shake > 0.0:
		shake = maxf(shake - delta, 0.0)
		position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake * 40.0
	else:
		position = Vector2.ZERO
	if memo_talk_t > 0.0:
		memo_talk_t -= delta
	if toast_t > 0.0:
		toast_t -= delta
	if not starting:
		if memo_pose_t > 0.0:
			memo_pose_t -= delta
			if memo_pose_t <= 0.0:
				memo_pose = Pose.DIL
	else:
		start_t += delta
		if start_t >= 0.38 and start_t - delta < 0.38:      # terlik Memo'ya çarptı
			memo_pose = Pose.SERSEM
			shake = 0.3
			Sfx.play("hit")
			get_tree().create_timer(0.12).timeout.connect(func(): Sfx.play("ouch"))
			_say("AY!")
			fx.append({"pos": Vector2(360.0, 1040.0), "text": "TAK!", "t": 0.0})
		if start_t >= 1.2:
			set_process(false)
			get_tree().change_scene_to_file(GAME_SCENE)
	for f in fx:
		f["t"] = float(f["t"]) + delta
	fx = fx.filter(func(f): return float(f["t"]) < 0.9)
	queue_redraw()


# ---------------- ÇİZİM ----------------
func _draw() -> void:
	var o := ad_off
	if page == "main":
		_draw_bg()
		_draw_falling()
		U.sunburst(self, Vector2(360.0, 330.0 + o), t * 0.15, 16, Color(1.0, 0.85, 0.3, 0.10))
		_draw_title(o)
		_draw_ribbon(o)
		_draw_memo()
		_draw_buttons()
		_draw_gear()
		_draw_fx()
		if starting:
			_draw_start_anim()
	else:
		_draw_page()
	if help_open:
		_draw_help()
	if toast_t > 0.0:
		_draw_toast()
	if Ads.is_stub:
		draw_rect(Rect2(0, 0, W, ad_off), Color(0.15, 0.15, 0.18, 0.95))
		U.out_text(self, font, "TEST BANNER", Vector2(360.0, ad_off * 0.5 + 8.0), 22, Color(0.8, 0.8, 0.85))
	# açılış karartması
	if t < 0.4:
		draw_rect(Rect2(-40, -40, W + 80, H + 80), Color(0, 0, 0, 1.0 - t / 0.4))
	if starting and start_t > 0.8:
		draw_rect(Rect2(-40, -40, W + 80, H + 80), Color(0, 0, 0, clampf((start_t - 0.8) / 0.38, 0.0, 1.0)))


func _draw_bg() -> void:
	var z := 1.08 + sin(t * 0.35) * 0.02
	var off := Vector2(sin(t * 0.25) * 14.0, cos(t * 0.2) * 10.0)
	draw_set_transform(Vector2(W * 0.5, H * 0.5) + off, 0.0, Vector2(z, z))
	if bg != null:
		draw_texture_rect(bg, Rect2(-W * 0.5, -H * 0.5, W, H), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# üstte başlık için koyu geçiş, altta Memo için hafif karartma
	var top := Color(0.08, 0.02, 0.15, 0.62)
	var clear := Color(0.08, 0.02, 0.15, 0.0)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, 700), Vector2(0, 700)]), PackedColorArray([top, top, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, 900), Vector2(W, 900), Vector2(W, H), Vector2(0, H)]), PackedColorArray([clear, clear, Color(0.08, 0.02, 0.15, 0.4), Color(0.08, 0.02, 0.15, 0.4)]))


func _draw_falling() -> void:
	for s in sparks:
		var tw := maxf(0.5 + 0.5 * sin(t * 3.0 + float(s["ph"])), 0.2)
		var sz := float(s["s"]) * tw
		draw_colored_polygon(U.star_pts(Vector2(float(s["x"]), float(s["y"])), sz, sz * 0.25, 4, 0.0), Color(1.0, 0.95, 0.6, 0.5))
	for p in parts:
		var y := fposmod(float(p["y"]) + t * float(p["v"]), H + 260.0) - 130.0
		var x := float(p["x"]) + sin(t * 0.9 + float(p["ph"])) * 30.0
		U.draw_slipper(self, tex_slip, Vector2(x, y), float(p["h"]), float(p["r"]) + t * float(p["rv"]), 0.8)


func _draw_title(o: float) -> void:
	_wave_text(Loc.t("t1"), 360.0, 270.0 + o, int(134 * Loc.k1()), Color(1.0, 0.9, 0.3), Color(0.95, 0.35, 0.15), 0.0)
	_wave_text(Loc.t("t2"), 360.0, 408.0 + o, 112, Color.WHITE, Color(0.25, 0.6, 0.95), 0.4)


# Harfleri tek tek hareket ettirir: giriş animasyonunda yukarıdan sekerek düşer, sonra dalgalanır.
func _wave_text(txt: String, cx: float, y: float, fsize: int, fill: Color, edge: Color, delay: float) -> void:
	var widths: Array = []
	var total := 0.0
	for i in txt.length():
		var cw := font.get_string_size(txt.substr(i, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
		widths.append(cw)
		total += cw
	for layer in 3:
		var x := cx - total * 0.5
		for i in txt.length():
			var cw: float = widths[i]
			var u := (t - 0.15 - delay - i * 0.07) / 0.55
			if u > 0.0:
				var drop := (1.0 - U.out_bounce(u)) * -520.0
				var wave := 0.0
				var rot := 0.0
				if u >= 1.0:
					wave = sin(t * 3.2 + i * 0.8) * 7.0
					rot = sin(t * 2.4 + i * 1.1) * 0.06
				U.fat_text(self, font, txt.substr(i, 1), Vector2(x + cw * 0.5, y + drop + wave), fsize, fill, edge, rot, 1.0, clampf(u * 4.0, 0.0, 1.0), layer)
			x += cw


func _draw_ribbon(o: float) -> void:
	var u := clampf((t - 0.9) / 0.45, 0.0, 1.0)
	if u <= 0.0:
		return
	var cx := lerpf(-400.0, 360.0, U.out_back(u))
	var cy := 500.0 + o + sin(t * 2.0) * 3.0
	draw_set_transform(Vector2(cx, cy), -0.05 + sin(t * 1.6) * 0.012, Vector2.ONE)
	draw_rect(Rect2(-250, -44, 500, 88), Color(0.13, 0.04, 0.03))
	draw_rect(Rect2(-242, -36, 484, 72), Color(0.78, 0.12, 0.15))
	draw_rect(Rect2(-242, -36, 484, 30), Color(0.95, 0.3, 0.3, 0.55))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	U.out_text(self, font, Loc.t("t3"), Vector2(cx, cy + 20.0), 54, Color(1.0, 0.92, 0.5), -0.05 + sin(t * 1.6) * 0.012)


func _draw_memo() -> void:
	var key := "memo_dil"
	if memo_pose == Pose.GERGIN:
		key = "memo_gergin"
	elif memo_pose == Pose.SERSEM:
		key = "memo_sersem"
	var tex: Texture2D = tex_memo[key]
	if tex == null:
		return
	var sc := 0.64
	var w := float(tex.get_width()) * sc
	var h := float(tex.get_height()) * sc
	# giriş: aşağıdan çıkar. Boştayken ara sıra yukarı aşağı oynar (dil çıkarır)
	var rise := U.out_bounce((t - 1.2) / 0.6)
	var bob := 0.0
	var wob := 0.0
	if memo_pose == Pose.DIL:
		bob = maxf(0.0, sin(t * 2.2)) * 14.0
		wob = sin(t * 9.0) * 0.035 * maxf(0.0, sin(t * 2.2))
	elif memo_pose == Pose.SERSEM:
		wob = sin(t * 28.0) * 0.1
	else:
		wob = sin(t * 40.0) * 0.03
	draw_set_transform(Vector2(360.0, H + 6.0 + (1.0 - rise) * h - bob), wob, Vector2.ONE)
	draw_texture_rect(tex, Rect2(-w * 0.5, -h, w, h), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if memo_pose == Pose.SERSEM:
		for i in 3:
			var a := t * 6.0 + i * TAU / 3.0
			draw_colored_polygon(U.star_pts(Vector2(360.0 + cos(a) * 90.0, 1010.0 + sin(a) * 20.0), 17.0, 8.0, 5, t * 3.0), Color(1.0, 0.9, 0.2))
	if memo_talk_t > 0.0:
		var pop := U.out_back((1.2 - memo_talk_t) / 0.2)
		U.out_text(self, font, memo_talk, Vector2(540.0, 985.0), 40, Color(1.0, 0.9, 0.3), 0.15, pop)


func _draw_buttons() -> void:
	if help_open:
		return
	var pulse := 1.0 + sin(t * 4.5) * 0.035
	var pr := _play_rect()
	var ps := pulse
	if press_id == "play" or starting:
		ps = 0.94
	draw_set_transform(pr.get_center(), 0.0, Vector2(ps, ps))
	draw_style_box(st_play, Rect2(-pr.size * 0.5, pr.size))
	draw_style_box(st_play_hi, Rect2(-pr.size.x * 0.5 + 16.0, -pr.size.y * 0.5 + 12.0, pr.size.x - 32.0, pr.size.y * 0.36))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var sub: String = Loc.t("new_game") if best_level <= 1 else Loc.t("continue") % best_level
	U.out_text(self, font, Loc.t("play"), pr.get_center() + Vector2(0, 12.0) * ps, 66, Color.WHITE, 0.0, ps)
	U.out_text(self, font, sub, pr.get_center() + Vector2(0, 46.0) * ps, 22, Color(0.85, 1.0, 0.85), 0.0, ps)
	var hr := _help_rect()
	var hs := 0.95 if press_id == "help" else 1.0
	draw_set_transform(hr.get_center(), 0.0, Vector2(hs, hs))
	draw_style_box(st_help, Rect2(-hr.size * 0.5, hr.size))
	draw_style_box(st_help_hi, Rect2(-hr.size.x * 0.5 + 14.0, -hr.size.y * 0.5 + 10.0, hr.size.x - 28.0, hr.size.y * 0.34))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	U.out_text(self, font, Loc.t("how_to"), hr.get_center() + Vector2(0, 11.0), 30, Color.WHITE, 0.0, hs)


func _draw_fx() -> void:
	for f in fx:
		var u := float(f["t"]) / 0.9
		var p: Vector2 = f["pos"]
		for i in 8:
			var a := i * TAU / 8.0
			var d := U.out_cubic(u * 1.4) * 150.0
			draw_colored_polygon(U.star_pts(p + Vector2(cos(a), sin(a)) * d, maxf(3.0, 22.0 * (1.0 - u)), 7.0, 5, u * 6.0 + i), Color(1.0, 0.85, 0.2, 1.0 - u))
		U.out_text(self, font, String(f["text"]), p + Vector2(0, -110.0 - u * 50.0), 54, Color(1.0, 0.9, 0.3, 1.0 - u * u), 0.0, 0.6 + U.out_back(u * 3.0) * 0.5)


# OYNA'ya basınca: terlik sol alttan Memo'ya uçar.
func _draw_start_anim() -> void:
	if start_t < 0.38:
		var u := start_t / 0.38
		var p := Vector2(-60.0, 1250.0).lerp(Vector2(360.0, 1030.0), u)
		p.y -= sin(u * PI) * 320.0
		for k in range(4, 0, -1):
			var uu := maxf(u - k * 0.05, 0.0)
			var pp := Vector2(-60.0, 1250.0).lerp(Vector2(360.0, 1030.0), uu)
			pp.y -= sin(uu * PI) * 320.0
			U.draw_slipper(self, tex_slip, pp, 190.0 - uu * 40.0, uu * 18.0, 0.5 - k * 0.1)
		U.draw_slipper(self, tex_slip, p, 190.0 - u * 40.0, u * 18.0)
	else:
		var t2 := start_t - 0.38
		if t2 < 0.15:
			draw_rect(Rect2(-40, -40, W + 80, H + 80), Color(1, 1, 1, 0.6 * (1.0 - t2 / 0.15)))
		if t2 < 0.5:
			var u := t2 / 0.5
			draw_arc(Vector2(360.0, 1030.0), U.out_cubic(u) * 300.0, 0.0, TAU, 56, Color(1.0, 0.9, 0.3, 1.0 - u), maxf(2.0, 18.0 * (1.0 - u)))


func _draw_help() -> void:
	var u := U.out_back(help_t / 0.25)
	draw_rect(Rect2(-40, -40, W + 80, H + 80), Color(0, 0, 0, 0.6 * clampf(help_t / 0.2, 0.0, 1.0)))
	var pr := Rect2(50.0, 200.0, 620.0, 900.0)
	draw_set_transform(pr.get_center(), 0.0, Vector2(u, u))
	draw_style_box(st_panel, Rect2(-pr.size * 0.5, pr.size))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if help_t < 0.2:
		return
	U.fat_text(self, font, Loc.t("how_to"), Vector2(360.0, 300.0), 46, Color(1.0, 0.9, 0.3), Color(0.95, 0.35, 0.15))
	var lines := [Loc.t("h1"), Loc.t("h2"), Loc.t("h3"), Loc.t("h4"), Loc.t("h5")]
	# Uzun dillerde taşmasın: yazı boyutunu toplam yükseklik sığana kadar küçült.
	var fs := 25
	var gap := 22.0
	while fs > 18:
		var tot := 0.0
		for l in lines:
			tot += font.get_multiline_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, 540.0, fs).y + gap
		if tot <= 640.0:
			break
		fs -= 1
	var y := 370.0
	for l in lines:
		draw_multiline_string(font, Vector2(90.0, y), l, HORIZONTAL_ALIGNMENT_LEFT, 540.0, fs, -1, Color(0.25, 0.12, 0.06))
		y += font.get_multiline_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, 540.0, fs).y + gap
	var cr := _close_rect()
	var cs := 0.95 if press_id == "close" else 1.0
	draw_set_transform(cr.get_center(), 0.0, Vector2(cs, cs))
	draw_style_box(st_play, Rect2(-cr.size * 0.5, cr.size))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	U.out_text(self, font, Loc.t("ok"), cr.get_center() + Vector2(0, 14.0), 42, Color.WHITE, 0.0, cs)


# ---------------- AYARLAR / UYGULAMALARIMIZ SAYFALARI ----------------
func _gear_rect() -> Rect2:
	return Rect2(596.0, 28.0 + ad_off, 96.0, 96.0)


func _panel_top() -> float:
	return 190.0 + ad_off


func _scroll_max() -> float:
	return maxf(0.0, cur_h + 24.0 - (H - _panel_top() - 30.0))


func _back_center() -> Vector2:
	return Vector2(80.0, 100.0 + ad_off)


func _open_page(p: String) -> void:
	page = p
	scroll = 0.0
	scroll_drag = false
	if p == "settings":
		cur_items = set_items
		cur_h = set_h
	elif p == "games":
		cur_items = game_items
		cur_h = game_h


func _toast(txt: String) -> void:
	toast_txt = txt
	toast_t = 2.0


var build_y := 0.0
var reset_arm_ms := -10000


func _add_set(kind: String, id: String, txt: String, h: float, gap: float) -> void:
	set_items.append({"k": kind, "id": id, "t": txt, "y": build_y, "h": h})
	build_y += h + gap


func _build_settings() -> void:
	set_items.clear()
	build_y = 0.0
	_add_set("btn", "games", Loc.t("games_btn"), 124.0, 14.0)
	_add_set("hdr", "", Loc.t("sec_sound"), 56.0, 0.0)
	_add_set("chk", "music", Loc.t("music"), 96.0, 14.0)
	_add_set("chk", "sfx", Loc.t("sfx"), 96.0, 14.0)
	_add_set("hdr", "", Loc.t("sec_device"), 56.0, 0.0)
	_add_set("chk", "vib", Loc.t("vib"), 96.0, 14.0)
	_add_set("chk", "fx", Loc.t("fxs"), 96.0, 14.0)
	_add_set("hdr", "", Loc.t("sec_progress"), 56.0, 0.0)
	_add_set("btn", "backup", Loc.t("backup_btn"), 96.0, 14.0)
	_add_set("btn", "reset", Loc.t("reset"), 96.0, 14.0)
	_add_set("hdr", "", Loc.t("sec_lang"), 56.0, 0.0)
	_add_set("btn", "lang", Loc.lang_name(), 96.0, 14.0)
	_add_set("hdr", "", Loc.t("sec_help"), 56.0, 0.0)
	_add_set("btn", "help", Loc.t("how_to_s"), 96.0, 14.0)
	_add_set("hdr", "", Loc.t("sec_privacy"), 56.0, 0.0)
	_add_set("btn", "consent", Loc.t("consent"), 96.0, 14.0)
	_add_set("hdr", "", Loc.t("sec_about"), 56.0, 0.0)
	_add_set("btn", "terms", Loc.t("terms"), 96.0, 14.0)
	_add_set("btn", "privacy", Loc.t("privacy"), 96.0, 14.0)
	_add_set("foot", "", Loc.t("title_full") + "  •  " + VERSION, 70.0, 0.0)
	set_h = build_y


func _build_games() -> void:
	game_items.clear()
	var cy := 0.0
	game_items.append({"k": "note", "id": "", "t": Loc.t("apps_note"), "y": cy, "h": 70.0})
	cy += 80.0
	for i in GAMES.size():
		game_items.append({"k": "card", "id": "game%d" % i, "t": "", "y": cy, "h": 176.0, "g": i})
		cy += 176.0 + 20.0
	game_h = cy


func _item_rect(it: Dictionary) -> Rect2:
	return Rect2(40.0, _panel_top() + 24.0 + float(it["y"]) - scroll, 640.0, float(it["h"]))


func _page_input(pressed: bool, pos: Vector2) -> void:
	if backup_open:                    # yedekleme penceresi: OK ya da dışarı dokununca kapanır
		if not pressed and (_bk_close().has_point(pos) or not _bk_panel().has_point(pos)):
			Sfx.play("click")
			backup_open = false
		return
	if lang_open:                      # dil listesi açıkken sayfa kaymaz, sadece listeye dokunulur
		if not pressed:
			_lang_tap(pos)
		return
	if pressed:
		scroll_drag = true
		drag_moved = false
		press_pos = pos
		scroll_start = scroll
		return
	if not scroll_drag:
		return
	scroll_drag = false
	if drag_moved:
		return
	if pos.distance_to(_back_center()) < 54.0:
		Sfx.play("click")
		_open_page("settings" if page == "games" else "main")
		return
	if pos.y < _panel_top():
		return
	for it in cur_items:
		var k: String = it["k"]
		if k != "btn" and k != "chk" and k != "card":
			continue
		if _item_rect(it).has_point(pos):
			_on_item(String(it["id"]))
			return


func _on_item(id: String) -> void:
	Sfx.play("click")
	match id:
		"games":
			_open_page("games")
		"music", "sfx", "vib", "fx":
			opts[id] = not bool(opts[id])
			U.set_setting(id, bool(opts[id]))
			Sfx.apply_settings()
			if id == "vib" and bool(opts[id]):
				Input.vibrate_handheld(50)
		"reset":
			if Time.get_ticks_msec() - reset_arm_ms < 3000:
				var cf := ConfigFile.new()
				cf.set_value("p", "level", 1)
				cf.save(SAVE_PATH)
				best_level = 1
				reset_arm_ms = -10000
				_toast(Loc.t("reset_done"))
			else:
				reset_arm_ms = Time.get_ticks_msec()
				_toast(Loc.t("reset_ask"))
		"lang":
			lang_open = true
		"backup":
			backup_open = true
		"help":
			help_open = true
			help_t = 0.0
		"consent":
			if not Ads.show_privacy_options():
				_toast(Loc.t("toast_noconsent"))
		"terms":
			_open_url(U.TERMS_URL)
		"privacy":
			_open_url(U.PRIVACY_URL)
		_:
			if id.begins_with("game"):
				var g: Dictionary = GAMES[int(id.substr(4))]
				_open_store(String(g["pkg"]))


# ---------------- YEDEKLEME PENCERESİ ----------------
func _bk_panel() -> Rect2:
	return Rect2(50.0, 240.0, 620.0, 800.0)


func _bk_close() -> Rect2:
	return Rect2(210.0, 920.0, 300.0, 90.0)


func _draw_backup() -> void:
	draw_rect(Rect2(-40, -40, W + 80, H + 80), Color(0, 0, 0, 0.6))
	var pr := _bk_panel()
	draw_style_box(st_panel, pr)
	U.fat_text(self, font, Loc.t("bk_title"), Vector2(360.0, pr.position.y + 90.0), 46, Color(1.0, 0.9, 0.3), Color(0.95, 0.35, 0.15))
	var lines := [Loc.t("bk1"), Loc.t("bk2"), Loc.t("bk3"), Loc.t("bk4")]
	var fs := 25
	var gap := 22.0
	while fs > 17:
		var tot := 0.0
		for l in lines:
			tot += font.get_multiline_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, 540.0, fs).y + gap
		if tot <= 500.0:
			break
		fs -= 1
	var y := pr.position.y + 150.0
	for l in lines:
		draw_multiline_string(font, Vector2(90.0, y), l, HORIZONTAL_ALIGNMENT_LEFT, 540.0, fs, -1, Color(0.25, 0.12, 0.06))
		y += font.get_multiline_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, 540.0, fs).y + gap
	var cr := _bk_close()
	draw_style_box(st_play, cr)
	U.out_text(self, font, Loc.t("ok"), cr.get_center() + Vector2(0, 14.0), 42, Color.WHITE)


# ---------------- DİL LİSTESİ ----------------
func _lang_panel() -> Rect2:
	return Rect2(80.0, 330.0, 560.0, 100.0 + Loc.LANGS.size() * 100.0)


func _lang_row(i: int) -> Rect2:
	return Rect2(110.0, 330.0 + 90.0 + i * 100.0, 500.0, 88.0)


func _lang_tap(pos: Vector2) -> void:
	for i in Loc.LANGS.size():
		if _lang_row(i).has_point(pos):
			Sfx.play("click")
			if i != Loc.idx:
				Loc.set_lang(i)
				_build_settings()
				_build_games()
				if page == "settings":
					cur_h = set_h
				elif page == "games":
					cur_h = game_h
				scroll = clampf(scroll, 0.0, _scroll_max())
			lang_open = false
			return
	if not _lang_panel().has_point(pos):
		Sfx.play("click")
		lang_open = false


func _draw_lang() -> void:
	draw_rect(Rect2(-40, -40, W + 80, H + 80), Color(0, 0, 0, 0.6))
	var pr := _lang_panel()
	draw_style_box(st_panel, pr)
	draw_string(font, Vector2(pr.position.x, pr.position.y + 62.0), Loc.t("sec_lang"), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x, 32, Color(0.35, 0.13, 0.05))
	for i in Loc.LANGS.size():
		var r := _lang_row(i)
		var sel := i == Loc.idx
		draw_style_box(st_play if sel else st_help, r)
		draw_style_box(st_play_hi if sel else st_help_hi, Rect2(r.position.x + 16.0, r.position.y + 8.0, r.size.x - 32.0, r.size.y * 0.30))
		U.out_text(self, font, Loc.NAMES[i], r.get_center() + Vector2(0.0, 12.0), 34, Color.WHITE)
		if sel:
			var c := Vector2(r.position.x + 52.0, r.get_center().y)
			draw_polyline(PackedVector2Array([c + Vector2(-14, 0), c + Vector2(-3, 12), c + Vector2(16, -12)]), Color.WHITE, 8.0)


func _open_url(url: String) -> void:
	if url.begins_with("BURAYA"):
		_toast(Loc.t("toast_nolink"))
		return
	OS.shell_open(url)


func _open_store(pkg: String) -> void:
	if pkg.begins_with("BURAYA"):
		_toast(Loc.t("toast_nopkg"))
		return
	var base := "market://details?id=" if OS.get_name() == "Android" else "https://play.google.com/store/apps/details?id="
	OS.shell_open(base + pkg)


func _draw_gear() -> void:
	if help_open:
		return
	var c := _gear_rect().get_center()
	draw_circle(c, 44.0, Color(0.20, 0.08, 0.05, 0.88))
	draw_arc(c, 44.0, 0.0, TAU, 40, Color(0.93, 0.45, 0.25), 5.0)
	draw_colored_polygon(U.star_pts(c, 31.0, 23.0, 8, t * 0.5), Color(1.0, 0.9, 0.6))
	draw_circle(c, 22.0, Color(1.0, 0.9, 0.6))
	draw_circle(c, 11.0, Color(0.20, 0.08, 0.05))


func _draw_page() -> void:
	var pt := _panel_top()
	draw_rect(Rect2(0, 0, W, H), Color(0.17, 0.07, 0.27))
	for s in sparks:
		var tw := maxf(0.5 + 0.5 * sin(t * 3.0 + float(s["ph"])), 0.2)
		var sz := float(s["s"]) * tw
		draw_colored_polygon(U.star_pts(Vector2(float(s["x"]), float(s["y"])), sz, sz * 0.25, 4, 0.0), Color(1.0, 0.95, 0.6, 0.25))
	draw_style_box(st_sheet, Rect2(0.0, pt, W, H - pt + 60.0))
	for it in cur_items:
		var r := _item_rect(it)
		if r.end.y < pt or r.position.y > H:
			continue
		match String(it["k"]):
			"hdr":
				draw_string(font, Vector2(r.position.x, r.position.y + 38.0), String(it["t"]), HORIZONTAL_ALIGNMENT_CENTER, 640.0, 26, Color(0.55, 0.33, 0.15))
			"note":
				draw_multiline_string(font, Vector2(r.position.x + 6.0, r.position.y + 30.0), String(it["t"]), HORIZONTAL_ALIGNMENT_LEFT, 628.0, 24, 3, Color(0.2, 0.5, 0.2))
			"foot":
				draw_string(font, Vector2(r.position.x, r.position.y + 40.0), String(it["t"]), HORIZONTAL_ALIGNMENT_CENTER, 640.0, 24, Color(0.45, 0.28, 0.14))
			"btn", "chk":
				_draw_item_button(it, r)
			"card":
				_draw_card(int(it["g"]), r)
	# başlık şeridi (içeriği üstten örter)
	draw_rect(Rect2(0, 0, W, pt), Color(0.17, 0.07, 0.27))
	var o := ad_off
	draw_rect(Rect2(160, 100.0 + o - 44.0, 400, 88), Color(0.13, 0.04, 0.03))
	draw_rect(Rect2(167, 100.0 + o - 37.0, 386, 74), Color(0.78, 0.12, 0.15))
	draw_rect(Rect2(167, 100.0 + o - 37.0, 386, 30), Color(0.95, 0.3, 0.3, 0.55))
	U.out_text(self, font, Loc.t("settings") if page == "settings" else Loc.t("our_apps"), Vector2(360.0, 114.0 + o), 40, Color(1.0, 0.92, 0.5))
	var bc := _back_center()
	draw_circle(bc, 42.0, Color(0.12, 0.04, 0.2))
	draw_arc(bc, 42.0, 0.0, TAU, 40, Color(0.93, 0.45, 0.25), 5.0)
	draw_polyline(PackedVector2Array([bc + Vector2(14, 0), bc + Vector2(-14, 0)]), Color.WHITE, 6.0)
	draw_polyline(PackedVector2Array([bc + Vector2(-2, -14), bc + Vector2(-16, 0), bc + Vector2(-2, 14)]), Color.WHITE, 6.0)
	var sm := _scroll_max()
	if sm > 0.0:
		var track := H - pt - 40.0
		var bar := maxf(60.0, track * track / (track + sm))
		draw_rect(Rect2(W - 12.0, pt + 20.0 + (track - bar) * scroll / sm, 6.0, bar), Color(0.55, 0.33, 0.15, 0.6))
	if lang_open:
		_draw_lang()
	if backup_open:
		_draw_backup()


func _draw_item_button(it: Dictionary, r: Rect2) -> void:
	var st: StyleBoxFlat = st_help
	var hi: StyleBoxFlat = st_help_hi
	if String(it["id"]) == "games":
		st = st_play
		hi = st_play_hi
	draw_style_box(st, r)
	draw_style_box(hi, Rect2(r.position.x + 16.0, r.position.y + 10.0, r.size.x - 32.0, r.size.y * 0.32))
	var fs := 34
	if String(it["id"]) == "games":
		fs = 30
	U.out_text(self, font, String(it["t"]), r.get_center() + Vector2(0.0, fs * 0.36), fs, Color.WHITE)
	if String(it["id"]) == "lang":       # açılır liste oku
		var ac := Vector2(r.end.x - 50.0, r.get_center().y)
		draw_colored_polygon(PackedVector2Array([ac + Vector2(-14, -8), ac + Vector2(14, -8), ac + Vector2(0, 10)]), Color.WHITE)
	if String(it["k"]) == "chk":
		var bx := Rect2(r.position.x + 24.0, r.position.y + (r.size.y - 54.0) * 0.5, 54.0, 54.0)
		draw_style_box(st_box, bx)
		if bool(opts[String(it["id"])]):
			var c := bx.position
			draw_polyline(PackedVector2Array([c + Vector2(12, 28), c + Vector2(23, 40), c + Vector2(43, 15)]), Color(0.15, 0.7, 0.25), 8.0)


func _draw_card(i: int, r: Rect2) -> void:
	var g: Dictionary = GAMES[i]
	draw_style_box(st_card, r)
	var ic := Rect2(r.position.x + 22.0, r.position.y + 33.0, 110.0, 110.0)
	var col: Color = g["col"]
	draw_rect(Rect2(ic.position.x - 3.0, ic.position.y - 3.0, 116.0, 116.0), Color(0.35, 0.13, 0.05))
	draw_rect(ic, col)
	draw_rect(Rect2(ic.position.x, ic.position.y, 110.0, 40.0), Color(1, 1, 1, 0.18))
	U.out_text(self, font, String(g["name"]).substr(0, 1), ic.get_center() + Vector2(0.0, 26.0), 74, Color.WHITE)
	draw_string(font, Vector2(r.position.x + 152.0, r.position.y + 60.0), String(g["name"]), HORIZONTAL_ALIGNMENT_LEFT, 320.0, 30, Color(0.30, 0.14, 0.06))
	draw_multiline_string(font, Vector2(r.position.x + 152.0, r.position.y + 96.0), Loc.t("gdesc%d" % i), HORIZONTAL_ALIGNMENT_LEFT, 290.0, 21, 3, Color(0.45, 0.28, 0.14))
	var br := Rect2(r.end.x - 150.0, r.position.y + (r.size.y - 66.0) * 0.5, 130.0, 66.0)
	draw_style_box(st_play, br)
	U.out_text(self, font, Loc.t("download"), br.get_center() + Vector2(0.0, 10.0), 26, Color.WHITE)


func _draw_toast() -> void:
	var a := clampf(toast_t / 0.4, 0.0, 1.0)
	var r := Rect2(90.0, 1130.0, 540.0, 76.0)
	draw_style_box(st_toast, r)
	draw_string(font, Vector2(r.position.x, r.position.y + 47.0), toast_txt, HORIZONTAL_ALIGNMENT_CENTER, 540.0, 24, Color(1, 1, 1, a))
