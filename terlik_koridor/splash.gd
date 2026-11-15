extends Node2D
## SPLASH (3 sn): terlik uçar -> TAK! -> başlık çarpar -> Memo dil çıkarır -> ikinci terlik Memo'yu vurur -> menü.
## Ekrana dokunursan (0.7 sn sonra) atlar. Süre: DURATION.

const U = preload("res://fx_util.gd")
const W := 720.0
const H := 1280.0
const DURATION := 3.0
const NEXT_SCENE := "res://menu.tscn"
const FADE_START := 2.55

const HIT1 := 0.55                       # ilk terlik başlığa çarpar
const IMPACT1 := Vector2(360.0, 470.0)
const THROW2 := 1.95                     # ikinci terlik Memo'ya gider
const THROW2_DUR := 0.22
const HIT2 := THROW2 + THROW2_DUR
const IMPACT2 := Vector2(360.0, 1000.0)
const MEMO_IN := 1.25                    # Memo'nun yukarı çıkmaya başladığı an

var t := 0.0
var going := false
var _s1 := false
var _s2 := false
var _s3 := false
var _s4 := false
var font: Font
var bg: Texture2D
var tex_slip: Texture2D
var tex_dil: Texture2D
var tex_sersem: Texture2D
var sparks: Array = []


func _ready() -> void:
	font = U.make_font()
	bg = load("res://assets/bg0.jpg")
	tex_slip = load("res://assets/terlik.png")
	tex_dil = load("res://assets/memo_dil.png")
	tex_sersem = load("res://assets/memo_sersem.png")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 22:
		sparks.append({"x": rng.randf_range(30.0, 690.0), "y": rng.randf_range(80.0, 1200.0), "ph": rng.randf_range(0.0, TAU), "s": rng.randf_range(10.0, 24.0)})


func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	t += delta
	if not _s1 and t >= HIT1 - 0.18:
		_s1 = true
		Sfx.play("throw")
	if not _s2 and t >= HIT1:
		_s2 = true
		Sfx.play("hit")
	if not _s3 and t >= THROW2:
		_s3 = true
		Sfx.play("throw", 1.1)
	if not _s4 and t >= HIT2:
		_s4 = true
		Sfx.play("hit", 0.95)
		get_tree().create_timer(0.12).timeout.connect(func(): Sfx.play("ouch"))
	var sh := 0.0
	if t >= HIT1 and t < HIT1 + 0.35:
		sh = (1.0 - (t - HIT1) / 0.35) * 16.0
	elif t >= HIT2 and t < HIT2 + 0.25:
		sh = (1.0 - (t - HIT2) / 0.25) * 9.0
	position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * sh
	if t >= DURATION and not going:
		going = true
		get_tree().change_scene_to_file(NEXT_SCENE)
	queue_redraw()


func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and t > 0.7 and t < FADE_START:
		t = FADE_START          # atla: sadece kararma kısmına geç


# ---------------- TERLİK YOLU ----------------
func _slip_pos(tt: float) -> Vector2:
	if tt <= HIT1:
		var u := clampf(tt / HIT1, 0.0, 1.0)
		var e := u * u * 0.4 + u * 0.6
		var p := Vector2(-120.0, 1400.0).lerp(IMPACT1, e)
		p.y -= sin(u * PI) * 260.0
		return p
	var t2 := tt - HIT1
	return IMPACT1 + Vector2(400.0 * t2, -520.0 * t2 + 1500.0 * t2 * t2)


func _slip_rot(tt: float) -> float:
	return tt * 17.0


func _slip_h(tt: float) -> float:
	if tt <= HIT1:
		return lerpf(330.0, 190.0, clampf(tt / HIT1, 0.0, 1.0))
	return 190.0


# ---------------- ÇİZİM ----------------
func _draw() -> void:
	# arka plan: yavaş zoom
	var z := 1.2 - 0.16 * U.out_cubic(t / DURATION)
	draw_set_transform(Vector2(W * 0.5, H * 0.5), 0.0, Vector2(z, z))
	if bg != null:
		draw_texture_rect(bg, Rect2(-W * 0.5, -H * 0.5, W, H), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(0, 0, W, H), Color(0.08, 0.02, 0.15, lerpf(0.6, 0.18, clampf(t / 1.0, 0.0, 1.0))))

	# güneş ışınları (çarpmadan sonra)
	if t >= HIT1:
		var ra := clampf((t - HIT1) / 0.3, 0.0, 1.0)
		U.sunburst(self, IMPACT1, t * 0.35, 14, Color(1.0, 0.85, 0.25, 0.20 * ra))

	_draw_sparks()
	_draw_slipper_one()
	if t >= HIT1:
		_draw_impact1()
	_draw_title()
	_draw_memo()
	if t >= HIT2:
		_draw_impact2()
	if t >= THROW2 and t < HIT2:
		var u2 := (t - THROW2) / THROW2_DUR
		var p2 := Vector2(-80.0, 900.0).lerp(IMPACT2, u2)
		U.draw_slipper(self, tex_slip, p2, 170.0, t * 20.0)

	# açılış / kapanış karartması
	var a := 0.0
	if t < 0.25:
		a = 1.0 - t / 0.25
	elif t > FADE_START:
		a = clampf((t - FADE_START) / (DURATION - FADE_START), 0.0, 1.0)
	if a > 0.0:
		draw_rect(Rect2(-40, -40, W + 80, H + 80), Color(0, 0, 0, a))


func _draw_sparks() -> void:
	for s in sparks:
		var tw := maxf(0.5 + 0.5 * sin(t * 4.0 + float(s["ph"])), 0.2)
		var c := Vector2(float(s["x"]), float(s["y"]) - t * 25.0)
		c.y = fposmod(c.y, H)
		draw_colored_polygon(U.star_pts(c, float(s["s"]) * tw, float(s["s"]) * 0.25 * tw, 4, 0.0), Color(1.0, 0.95, 0.6, 0.55))


func _draw_slipper_one() -> void:
	if t < 0.0:
		return
	var p := _slip_pos(t)
	if p.y > H + 250.0:
		return
	if t <= HIT1:
		for k in range(5, 0, -1):
			var tt := maxf(t - k * 0.022, 0.0)
			U.draw_slipper(self, tex_slip, _slip_pos(tt), _slip_h(tt), _slip_rot(tt), 0.5 - k * 0.08)
	U.draw_slipper(self, tex_slip, p, _slip_h(t), _slip_rot(t))


func _draw_impact1() -> void:
	var t2 := t - HIT1
	# beyaz flaş
	if t2 < 0.22:
		draw_rect(Rect2(-40, -40, W + 80, H + 80), Color(1, 1, 1, 0.85 * (1.0 - t2 / 0.22)))
	# şok halkaları
	for k in 3:
		var tk := t2 - k * 0.09
		if tk > 0.0 and tk < 0.55:
			var u := tk / 0.55
			draw_arc(IMPACT1, U.out_cubic(u) * 480.0, 0.0, TAU, 72, Color(1.0, 0.92 - k * 0.2, 0.3, 1.0 - u), maxf(2.0, 22.0 * (1.0 - u)))
	# hız çizgileri
	if t2 < 0.5:
		var u := t2 / 0.5
		for i in 22:
			var a := i * TAU / 22.0 + 0.1
			var r0 := 90.0 + U.out_cubic(u) * 160.0
			var r1 := r0 + 120.0 * (1.0 - u)
			draw_line(IMPACT1 + Vector2(cos(a), sin(a)) * r0, IMPACT1 + Vector2(cos(a), sin(a)) * r1, Color(1, 1, 1, 1.0 - u), 7.0)
	# yıldız patlaması
	if t2 < 1.0:
		var u := t2 / 1.0
		for i in 16:
			var a := i * TAU / 16.0 + (i % 2) * 0.15
			var d := U.out_cubic(u) * (240.0 + (i % 3) * 100.0)
			var sz := maxf(4.0, 34.0 * (1.0 - u))
			var col := Color(1.0, 0.85, 0.2, 1.0 - u * 0.6)
			if i % 3 == 1:
				col = Color(1.0, 0.45, 0.2, 1.0 - u * 0.6)
			elif i % 3 == 2:
				col = Color(1, 1, 1, 1.0 - u * 0.6)
			draw_colored_polygon(U.star_pts(IMPACT1 + Vector2(cos(a), sin(a)) * d, sz, sz * 0.45, 5, t2 * 4.0 + i), col)
	# "TAK!" patlaması
	if t2 < 0.95:
		var sc := U.out_back(t2 / 0.25)
		if t2 > 0.7:
			sc *= 1.0 - (t2 - 0.7) / 0.25
		var c := Vector2(580.0, 250.0)
		draw_colored_polygon(U.star_pts(c, 140.0 * sc, 88.0 * sc, 11, -0.2), Color(0.15, 0.04, 0.03))
		draw_colored_polygon(U.star_pts(c, 126.0 * sc, 76.0 * sc, 11, -0.2), Color(0.95, 0.2, 0.15))
		U.out_text(self, font, "TAK!", c + Vector2(0, 20.0 * sc), 64, Color.WHITE, -0.2, sc)


func _draw_title() -> void:
	if t < HIT1:
		return
	var t2 := t - HIT1
	var bob := sin(t * 6.0) * 0.015
	# ANNE
	var u1 := clampf(t2 / 0.35, 0.0, 1.0)
	if u1 > 0.0:
		var sc1 := lerpf(3.2, 1.0, U.out_back(u1))
		U.fat_text(self, font, Loc.t("t1"), Vector2(360.0, 360.0), int(150 * Loc.k1()), Color(1.0, 0.9, 0.3), Color(0.95, 0.35, 0.15), -0.05 + bob, sc1, minf(u1 * 3.0, 1.0))
	# TERLİĞİ
	var u2 := clampf((t2 - 0.14) / 0.35, 0.0, 1.0)
	if u2 > 0.0:
		var sc2 := lerpf(3.2, 1.0, U.out_back(u2))
		U.fat_text(self, font, Loc.t("t2"), Vector2(360.0, 500.0), 128, Color(1.0, 1.0, 1.0), Color(0.25, 0.6, 0.95), 0.04 - bob, sc2, minf(u2 * 3.0, 1.0))
	# KORİDOR şeridi
	var u3 := clampf((t2 - 0.45) / 0.4, 0.0, 1.0)
	if u3 > 0.0:
		var cx := lerpf(-420.0, 360.0, U.out_back(u3))
		draw_set_transform(Vector2(cx, 590.0), -0.05, Vector2.ONE)
		draw_rect(Rect2(-250, -44, 500, 88), Color(0.13, 0.04, 0.03))
		draw_rect(Rect2(-242, -36, 484, 72), Color(0.78, 0.12, 0.15))
		draw_rect(Rect2(-242, -36, 484, 30), Color(0.95, 0.3, 0.3, 0.55))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		U.out_text(self, font, Loc.t("t3"), Vector2(cx, 612.0), 54, Color(1.0, 0.92, 0.5), -0.05)


func _draw_memo() -> void:
	if t < MEMO_IN:
		return
	var tex: Texture2D = tex_dil
	if t >= HIT2:
		tex = tex_sersem
	if tex == null:
		return
	var rise := U.out_bounce((t - MEMO_IN) / 0.55)
	var sc := 0.82
	var w := float(tex.get_width()) * sc
	var h := float(tex.get_height()) * sc
	var wob := 0.0
	if t < HIT2:
		wob = sin(t * 14.0) * 0.05
	else:
		wob = sin((t - HIT2) * 30.0) * 0.12 * maxf(0.0, 1.0 - (t - HIT2) * 2.0)
	var y_off := (1.0 - rise) * h
	draw_set_transform(Vector2(360.0, H + 6.0 + y_off), wob, Vector2.ONE)
	draw_texture_rect(tex, Rect2(-w * 0.5, -h, w, h), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if t >= MEMO_IN + 0.5 and t < HIT2:
		var pop := U.out_back((t - MEMO_IN - 0.5) / 0.2)
		U.out_text(self, font, Loc.t("nanik"), Vector2(560.0, 870.0), 46, Color(1.0, 0.9, 0.3), sin(t * 12.0) * 0.1 + 0.15, pop)


func _draw_impact2() -> void:
	var t2 := t - HIT2
	if t2 < 0.14:
		draw_rect(Rect2(-40, -40, W + 80, H + 80), Color(1, 1, 1, 0.45 * (1.0 - t2 / 0.14)))
	if t2 < 0.5:
		var u := t2 / 0.5
		draw_arc(IMPACT2, U.out_cubic(u) * 260.0, 0.0, TAU, 56, Color(1.0, 0.9, 0.3, 1.0 - u), maxf(2.0, 16.0 * (1.0 - u)))
	if t2 < 0.8:
		var u := t2 / 0.8
		for i in 10:
			var a := i * TAU / 10.0
			var d := U.out_cubic(u) * 200.0
			draw_colored_polygon(U.star_pts(IMPACT2 + Vector2(cos(a), sin(a)) * d, maxf(3.0, 26.0 * (1.0 - u)), 8.0, 5, t2 * 5.0 + i), Color(1.0, 0.85 + 0.1 * (i % 2), 0.25, 1.0 - u * 0.7))
	# dönen yıldızlar (sersemlemiş Memo)
	for i in 3:
		var a := t * 6.0 + i * TAU / 3.0
		var c := Vector2(360.0 + cos(a) * 110.0, 930.0 + sin(a) * 26.0)
		draw_colored_polygon(U.star_pts(c, 20.0, 9.0, 5, t * 3.0), Color(1.0, 0.9, 0.2))
	var pop := U.out_back(t2 / 0.2)
	U.out_text(self, font, "AY!", Vector2(180.0, 880.0), 56, Color(1.0, 0.5, 0.35), -0.2, pop)
