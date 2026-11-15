extends RefCounted
## Splash ve menü için ortak yardımcılar (easing, yıldız, kontürlü yazı, font).
## Kullanım:  const U = preload("res://fx_util.gd")   ->   U.out_back(x)

const FONT_PATH := "res://assets/fonts/Poppins-Bold.ttf"
const SETTINGS_PATH := "user://terlik_settings.cfg"

# Kullanım Şartları ve Gizlilik Politikası bağlantıları (GitHub Pages; adres büyük/küçük harfe duyarlı)
const TERMS_URL := "https://filinta01453-ui.github.io/AstroFelyx-legal/Terms&Conditions.html"
const PRIVACY_URL := "https://filinta01453-ui.github.io/AstroFelyx-legal/privacypolicy.html"


# Ayarlar (müzik, ses, titreşim, ekran efektleri): menüden yazılır, oyundan okunur.
static func get_setting(key: String, default_v: bool) -> bool:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		return bool(cf.get_value("s", key, default_v))
	return default_v


static func set_setting(key: String, val: bool) -> void:
	var cf := ConfigFile.new()
	cf.load(SETTINGS_PATH)
	cf.set_value("s", key, val)
	cf.save(SETTINGS_PATH)


static func make_font() -> Font:
	if ResourceLoader.exists(FONT_PATH):
		var base: Font = load(FONT_PATH)
		if base != null:
			var fv := FontVariation.new()
			fv.base_font = base
			fv.variation_embolden = 0.35
			return fv
	return ThemeDB.fallback_font


static func out_cubic(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - x, 3.0)


static func out_back(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)


static func out_bounce(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	var n1 := 7.5625
	var d1 := 2.75
	if x < 1.0 / d1:
		return n1 * x * x
	elif x < 2.0 / d1:
		x -= 1.5 / d1
		return n1 * x * x + 0.75
	elif x < 2.5 / d1:
		x -= 2.25 / d1
		return n1 * x * x + 0.9375
	x -= 2.625 / d1
	return n1 * x * x + 0.984375


static func star_pts(c: Vector2, r_out: float, r_in: float, n: int, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := rot + i * PI / float(n)
		var r := r_out if i % 2 == 0 else r_in
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


# Üç katmanlı (koyu kontür + renkli kontür + dolgu) ortalanmış yazı. pos = (orta x, taban çizgisi y).
# layer: -1 = hepsi, 0 = gölge + koyu kontür, 1 = renkli kontür, 2 = dolgu.
# (Harf harf çizerken önce tüm harflerin 0. katmanı, sonra 1., sonra 2. çizilir ki kontürler komşu harfi örtmesin.)
static func fat_text(ci: CanvasItem, font: Font, txt: String, pos: Vector2, fsize: int, fill: Color, edge: Color, rot: float = 0.0, sc: float = 1.0, alpha: float = 1.0, layer: int = -1) -> void:
	sc = maxf(sc, 0.01)
	ci.draw_set_transform(pos, rot, Vector2(sc, sc))
	var p := Vector2(-500.0, 0.0)
	if layer == -1 or layer == 0:
		ci.draw_string_outline(font, p + Vector2(0, 9), txt, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, fsize, 26, Color(0, 0, 0, 0.35 * alpha))
		ci.draw_string_outline(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, fsize, 24, Color(0.13, 0.04, 0.03, alpha))
	if layer == -1 or layer == 1:
		ci.draw_string_outline(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, fsize, 11, Color(edge.r, edge.g, edge.b, alpha))
	if layer == -1 or layer == 2:
		ci.draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, fsize, Color(fill.r, fill.g, fill.b, alpha))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Küçük, tek kontürlü yazı (etiketler, butonlar için).
static func out_text(ci: CanvasItem, font: Font, txt: String, pos: Vector2, fsize: int, col: Color, rot: float = 0.0, sc: float = 1.0) -> void:
	sc = maxf(sc, 0.01)
	ci.draw_set_transform(pos, rot, Vector2(sc, sc))
	var p := Vector2(-500.0, 0.0)
	ci.draw_string_outline(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, fsize, 9, Color(0.13, 0.04, 0.03, col.a))
	ci.draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, fsize, col)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Güneş ışınları (arka plan efekti).
static func sunburst(ci: CanvasItem, c: Vector2, rot: float, n: int, col: Color) -> void:
	for i in n:
		var a0 := rot + i * TAU / float(n)
		var a1 := a0 + TAU / float(n) * 0.5
		var pts := PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * 1400.0, c + Vector2(cos(a1), sin(a1)) * 1400.0])
		ci.draw_colored_polygon(pts, col)


static func draw_slipper(ci: CanvasItem, tex: Texture2D, c: Vector2, h: float, rot: float, alpha: float = 1.0) -> void:
	if tex == null:
		return
	var w := h * float(tex.get_width()) / float(tex.get_height())
	ci.draw_set_transform(c, rot, Vector2.ONE)
	ci.draw_texture_rect(tex, Rect2(-w * 0.5, -h * 0.5, w, h), false, Color(1, 1, 1, alpha))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
