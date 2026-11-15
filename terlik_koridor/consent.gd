extends Node2D
## AÇILIŞ ONAYI: Kullanım Şartları + Gizlilik Politikası. KABUL ET -> splash (ve reklam SDK'sı başlar), REDDET -> oyun kapanır.
## Onay user://terlik_settings.cfg içinde "terms_ok" olarak saklanır; bir kez kabul edilince tekrar sorulmaz.
## Ayarlar > Hakkında'dan şartlar sonradan da okunabilir.

const U = preload("res://fx_util.gd")
const W := 720.0
const H := 1280.0
const NEXT_SCENE := "res://splash.tscn"

var font: Font
var bg: Texture2D
var t := 0.0
var press_id := ""
var toast_txt := ""
var toast_t := 0.0
var st_panel: StyleBoxFlat
var st_accept: StyleBoxFlat
var st_reject: StyleBoxFlat
var st_link: StyleBoxFlat
var st_toast: StyleBoxFlat
var _going := false


func _ready() -> void:
	if U.get_setting("terms_ok", false):       # daha önce kabul edilmiş: direkt splash'a geç
		_going = true
		set_process(false)
		call_deferred("_go_next")
		return
	get_tree().set_auto_accept_quit(true)       # Android geri tuşu = reddet (oyun kapanır)
	font = U.make_font()
	bg = load("res://assets/bg0.jpg")
	st_panel = _style(Color(0.99, 0.94, 0.80), Color(0.35, 0.13, 0.05), 30)
	st_accept = _style(Color(0.22, 0.78, 0.30), Color(0.08, 0.30, 0.12), 30)
	st_reject = _style(Color(0.86, 0.28, 0.22), Color(0.35, 0.08, 0.05), 30)
	st_link = _style(Color(0.93, 0.45, 0.25), Color(0.35, 0.13, 0.05), 24)
	st_toast = _style(Color(0.15, 0.06, 0.04, 0.92), Color(0, 0, 0, 0), 24)


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


func _go_next() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)


# ---------------- DÜZEN ----------------
func _panel() -> Rect2:
	return Rect2(50.0, 230.0, 620.0, 820.0)


func _terms_rect() -> Rect2:
	return Rect2(110.0, 660.0, 500.0, 84.0)


func _privacy_rect() -> Rect2:
	return Rect2(110.0, 760.0, 500.0, 84.0)


func _reject_rect() -> Rect2:
	return Rect2(80.0, 900.0, 260.0, 104.0)


func _accept_rect() -> Rect2:
	return Rect2(380.0, 900.0, 260.0, 104.0)


func _hit(pos: Vector2) -> String:
	if _accept_rect().has_point(pos):
		return "accept"
	if _reject_rect().has_point(pos):
		return "reject"
	if _terms_rect().has_point(pos):
		return "terms"
	if _privacy_rect().has_point(pos):
		return "privacy"
	return ""


# ---------------- GİRDİ ----------------
func _input(event: InputEvent) -> void:
	if _going:
		return
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var pos := get_global_mouse_position()
	if mb.pressed:
		press_id = _hit(pos)
		return
	var id := press_id
	press_id = ""
	if id == "" or _hit(pos) != id:
		return
	match id:
		"accept":
			_going = true
			U.set_setting("terms_ok", true)
			Sfx.play("click")
			Ads.start()
			_go_next()
		"reject":
			_going = true
			Sfx.play("click")
			get_tree().create_timer(0.15).timeout.connect(func(): get_tree().quit())
		"terms":
			Sfx.play("click")
			_open_url(U.TERMS_URL)
		"privacy":
			Sfx.play("click")
			_open_url(U.PRIVACY_URL)


func _open_url(url: String) -> void:
	if url.begins_with("BURAYA"):
		toast_txt = Loc.t("toast_nolink")
		toast_t = 2.0
		return
	OS.shell_open(url)


func _process(delta: float) -> void:
	t += minf(delta, 0.05)
	if toast_t > 0.0:
		toast_t -= delta
	queue_redraw()


# ---------------- ÇİZİM ----------------
func _draw() -> void:
	if _going and font == null:
		return
	if bg != null:
		draw_texture_rect(bg, Rect2(0, 0, W, H), false)
	draw_rect(Rect2(0, 0, W, H), Color(0.08, 0.02, 0.15, 0.78))
	var pr := _panel()
	draw_style_box(st_panel, pr)
	U.fat_text(self, font, Loc.t("cs_title"), Vector2(360.0, pr.position.y + 95.0), 50, Color(1.0, 0.9, 0.3), Color(0.95, 0.35, 0.15))
	# gövde metni: uzun dillerde taşmasın diye boyut küçülür
	var body := Loc.t("cs_body")
	var fs := 28
	while fs > 18 and font.get_multiline_string_size(body, HORIZONTAL_ALIGNMENT_LEFT, 540.0, fs).y > 240.0:
		fs -= 1
	draw_multiline_string(font, Vector2(90.0, pr.position.y + 175.0), body, HORIZONTAL_ALIGNMENT_LEFT, 540.0, fs, -1, Color(0.25, 0.12, 0.06))
	_draw_btn(_terms_rect(), st_link, Loc.t("terms"), 30, "terms")
	_draw_btn(_privacy_rect(), st_link, Loc.t("privacy"), 30, "privacy")
	_draw_btn(_reject_rect(), st_reject, Loc.t("cs_reject"), 34, "reject")
	_draw_btn(_accept_rect(), st_accept, Loc.t("cs_accept"), 34, "accept")
	if toast_t > 0.0:
		var a := clampf(toast_t / 0.4, 0.0, 1.0)
		var r := Rect2(90.0, 1130.0, 540.0, 76.0)
		draw_style_box(st_toast, r)
		draw_string(font, Vector2(r.position.x, r.position.y + 47.0), Loc.t("toast_nolink"), HORIZONTAL_ALIGNMENT_CENTER, 540.0, 24, Color(1, 1, 1, a))


func _draw_btn(r: Rect2, st: StyleBoxFlat, txt: String, fsize: int, id: String) -> void:
	var sc := 0.95 if press_id == id else 1.0
	draw_set_transform(r.get_center(), 0.0, Vector2(sc, sc))
	draw_style_box(st, Rect2(-r.size * 0.5, r.size))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	U.out_text(self, font, txt, r.get_center() + Vector2(0.0, fsize * 0.36), fsize, Color.WHITE, 0.0, sc)
