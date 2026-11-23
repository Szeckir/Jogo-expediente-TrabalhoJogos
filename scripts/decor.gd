class_name Decor
extends ItemDoAnel

# Decoração de parede e de chão que dá cara própria a cada setor. Não é
# móvel: não tem rótulo, não abre nada e não conta no mapa. O Setor as
# espalha sozinho conforme o `ambiente` (ver Setor._criar_decoracao).
#
# Tudo é desenhado por código. Y = 0 é o chão e a parede sobe até -470;
# a faixa lisa da parede vai de -436 a -134 e o rodapé escuro, de -134 a
# -12. Cada peça cabe em ~200 px de largura (o Setor só mostra o que está
# a menos de 700 px do jogador).

enum Tipo { RACHADURA, BURACO, ESCOMBRO, ARMARIOS, RACK, CANO, CAIXAS, EXTINTOR, LIXEIRA, PLACA, MAQUINA, XEROX, PLANTA }

const GESSO := Color(0.74, 0.76, 0.72)
const BURACO_FUNDO := Color(0.17, 0.18, 0.18)
const TIJOLO := Color(0.56, 0.34, 0.28)
const METAL := Color(0.55, 0.60, 0.57)
const PAPELAO := Color(0.70, 0.58, 0.40)

@export var tipo: Tipo = Tipo.RACHADURA
@export var semente := 0

var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _passo := 0.0


func _process(delta: float) -> void:
	# só RACK (LEDs) e CANO com válvula (vapor) se mexem
	if not visible or not (tipo == Tipo.RACK or (tipo == Tipo.CANO and semente % 4 == 0)):
		return
	_t += delta
	_passo += delta
	if _passo >= 0.08:
		_passo = 0.0
		queue_redraw()


func _draw() -> void:
	_rng.seed = semente   # a geometria é a mesma a cada redesenho
	match tipo:
		Tipo.RACHADURA: _rachadura()
		Tipo.BURACO: _buraco()
		Tipo.ESCOMBRO: _escombro()
		Tipo.ARMARIOS: _armarios()
		Tipo.RACK: _rack()
		Tipo.CANO: _cano()
		Tipo.CAIXAS: _caixas()
		Tipo.EXTINTOR: _extintor()
		Tipo.LIXEIRA: _lixeira()
		Tipo.PLACA: _placa()
		Tipo.MAQUINA: _maquina()
		Tipo.XEROX: _xerox()
		Tipo.PLANTA: _planta()


func _r(a: float, b: float) -> float:
	return _rng.randf_range(a, b)


func _elipse(centro: Vector2, rx: float, ry: float, cor: Color) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		var ang := TAU * i / 14.0
		pts.append(centro + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_colored_polygon(pts, cor)


# ------------------------------------------------------------ destruído

func _rachadura() -> void:
	var x := 0.0
	var y := -410.0 + _r(-20.0, 10.0)
	var pts := PackedVector2Array([Vector2(x, y)])
	for _i in 8:
		x += _r(-15.0, 15.0)
		y += _r(24.0, 36.0)
		pts.append(Vector2(x, y))
	var sombra := Color(0.30, 0.33, 0.31, 0.95)
	var luz := Color(0.99, 0.99, 0.97, 0.55)
	draw_polyline(pts, luz, 2.2)
	draw_polyline(pts, sombra, 2.4)
	for i in [2, 5]:
		var ramo := PackedVector2Array([pts[i], pts[i] + Vector2(_r(-46.0, 46.0), _r(18.0, 34.0))])
		draw_polyline(ramo, sombra, 1.6)


# Parede quebrada: borda de gesso estilhaçado, vão escuro com tijolo à vista.
func _buraco() -> void:
	var centro := Vector2(0.0, -250.0 + _r(-30.0, 30.0))
	var n := 11
	var fora := PackedVector2Array()
	var dentro := PackedVector2Array()
	for i in n:
		var ang := TAU * i / n
		var raio := _r(40.0, 62.0)
		fora.append(centro + Vector2(cos(ang) * raio * 1.25, sin(ang) * raio * 1.18))
		dentro.append(centro + Vector2(cos(ang) * raio * 0.95, sin(ang) * raio * 0.9))
	draw_colored_polygon(fora, GESSO)
	draw_colored_polygon(dentro, BURACO_FUNDO)
	for _i in 5:
		var tijolo := centro + Vector2(_r(-26.0, 20.0), _r(-30.0, 26.0))
		var cor := TIJOLO.darkened(_r(0.0, 0.3))
		draw_rect(Rect2(tijolo, Vector2(_r(18.0, 26.0), 9.0)), cor)
	# rachaduras saindo da boca do buraco
	var sombra := Color(0.30, 0.33, 0.31, 0.9)
	for _i in 3:
		var ang := _r(0.0, TAU)
		var ini := centro + Vector2(cos(ang), sin(ang)) * 76.0
		var meio := ini + Vector2(cos(ang + 0.4), sin(ang + 0.4)) * _r(14.0, 24.0)
		var fim := meio + Vector2(cos(ang - 0.3), sin(ang - 0.3)) * _r(14.0, 26.0)
		draw_polyline(PackedVector2Array([ini, meio, fim]), sombra, 1.6)


# Pedaços de parede caídos no chão.
func _escombro() -> void:
	_elipse(Vector2(0.0, 14.0), 62.0, 8.0, Color(0.82, 0.82, 0.79, 0.55))
	for _i in 9:
		var c := Vector2(_r(-48.0, 48.0), _r(5.0, 22.0))
		var t := _r(5.0, 12.0)
		var cor := [Color(0.64, 0.65, 0.62), Color(0.50, 0.50, 0.48), TIJOLO][_rng.randi() % 3] as Color
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(-t, t * 0.4), c + Vector2(-t * 0.3, -t * 0.7),
			c + Vector2(t * 0.8, -t * 0.3), c + Vector2(t, t * 0.5)]), cor)


# ------------------------------------------------------------- armários

# Fileira de armários de aço ao fundo. Um deles sempre fica com a porta
# entreaberta, e qual é depende da semente.
func _armarios() -> void:
	var qtd := 2 + _rng.randi() % 2          # 2 ou 3 armários
	var aberto := _rng.randi() % 4          # 3 = todos fechados
	var x0 := -qtd * 26.0
	for i in qtd:
		var x := x0 + i * 52.0
		var topo := -250.0
		draw_rect(Rect2(x, topo, 50.0, 238.0), METAL.darkened(0.1))
		if i == aberto:
			draw_rect(Rect2(x + 3.0, topo + 3.0, 44.0, 232.0), Color(0.12, 0.14, 0.13))
			draw_rect(Rect2(x + 36.0, topo + 3.0, 10.0, 232.0), METAL.darkened(0.25))
		else:
			draw_rect(Rect2(x + 2.0, topo + 2.0, 46.0, 234.0), METAL)
			for k in 5:
				draw_rect(Rect2(x + 9.0, topo + 14.0 + k * 7.0, 32.0, 3.0), Color(0, 0, 0, 0.30))
			draw_rect(Rect2(x + 38.0, topo + 118.0, 4.0, 18.0), Color(0.82, 0.85, 0.83))
			draw_rect(Rect2(x + 12.0, topo + 56.0, 16.0, 10.0), Color(0.95, 0.95, 0.92))
		draw_rect(Rect2(x, topo - 4.0, 50.0, 5.0), METAL.darkened(0.3))
	_elipse(Vector2(0.0, -8.0), qtd * 29.0, 4.0, Color(0, 0, 0, 0.10))


# --------------------------------------------------------------- refino

# Rack de servidor com LEDs piscando.
func _rack() -> void:
	draw_rect(Rect2(-40.0, -286.0, 80.0, 278.0), Color(0.13, 0.15, 0.16))
	for i in 8:
		var y := -278.0 + i * 33.0
		draw_rect(Rect2(-35.0, y, 70.0, 29.0), Color(0.21, 0.24, 0.25))
		draw_rect(Rect2(-31.0, y + 5.0, 34.0, 3.0), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(-31.0, y + 11.0, 34.0, 3.0), Color(0, 0, 0, 0.55))
		for k in 3:
			var acesa := sin(_t * (2.5 + k) + i * 1.7 + semente * 0.01 + k * 2.1) > 0.0
			var cor := Color(0.35, 0.95, 0.60) if k != 2 else Color(1.0, 0.70, 0.25)
			if not acesa:
				cor = cor.darkened(0.75)
			draw_circle(Vector2(12.0 + k * 7.0, y + 14.0), 2.2, cor)
	_elipse(Vector2(0.0, -6.0), 52.0, 4.0, Color(0, 0, 0, 0.14))


# ------------------------------------------------------------- máquinas

# Um trecho de 200 px de cano na parede. Trechos vizinhos se encostam, então
# o cano parece contínuo em volta do anel. Alguns trazem uma válvula que
# solta vapor.
func _cano() -> void:
	for y in [-402.0]:
		draw_rect(Rect2(-100.0, y - 7.0, 200.0, 14.0), Color(0.50, 0.53, 0.51))
		draw_rect(Rect2(-100.0, y - 7.0, 200.0, 4.0), Color(0.78, 0.81, 0.79))
		draw_rect(Rect2(-100.0, y + 4.0, 200.0, 3.0), Color(0, 0, 0, 0.22))
	# braçadeira
	draw_rect(Rect2(-6.0, -414.0, 12.0, 24.0), Color(0.33, 0.35, 0.34))
	if semente % 4 != 0:
		return
	draw_rect(Rect2(36.0, -402.0, 9.0, 254.0), Color(0.50, 0.53, 0.51))
	draw_rect(Rect2(36.0, -402.0, 3.0, 254.0), Color(0.78, 0.81, 0.79))
	draw_arc(Vector2(40.5, -250.0), 13.0, 0.0, TAU, 20, Color(0.74, 0.20, 0.17), 3.0)
	draw_line(Vector2(27.5, -250.0), Vector2(53.5, -250.0), Color(0.74, 0.20, 0.17), 3.0)
	for i in 4:
		var p := fmod(_t * 0.5 + i * 0.25, 1.0)
		var c := Vector2(44.0 + sin(p * 6.0 + i) * 7.0, -150.0 - p * 90.0)
		draw_circle(c, 6.0 + p * 15.0, Color(1, 1, 1, 0.30 * (1.0 - p)))


# ---------------------------------------------------------------- arquivo

# Pilha de caixas de papelão.
func _caixas() -> void:
	var larg := _r(64.0, 92.0)
	var alt := _r(42.0, 58.0)
	_caixa(Vector2(-larg / 2.0, -4.0 - alt), Vector2(larg, alt))
	if _rng.randf() < 0.75:
		var l2 := larg * _r(0.6, 0.85)
		var a2 := _r(34.0, 48.0)
		_caixa(Vector2(-l2 / 2.0 + _r(-8.0, 8.0), -4.0 - alt - a2), Vector2(l2, a2))
	_elipse(Vector2(0.0, -2.0), larg * 0.62, 4.0, Color(0, 0, 0, 0.12))


func _caixa(canto: Vector2, tam: Vector2) -> void:
	draw_rect(Rect2(canto, tam), PAPELAO.darkened(_r(0.0, 0.18)))
	draw_rect(Rect2(canto, tam), Color(0, 0, 0, 0.35), false, 1.2)
	draw_rect(Rect2(canto + Vector2(tam.x / 2.0 - 6.0, 0.0), Vector2(12.0, tam.y)), Color(0.86, 0.78, 0.60, 0.8))
	draw_rect(Rect2(canto + Vector2(6.0, tam.y - 18.0), Vector2(18.0, 11.0)), Color(0.96, 0.95, 0.9))


# ---------------------------------------------------- objetos soltos
# Esses entram na mão, pelo editor (nó com este script, escolhendo o Tipo).
# Não são móveis: não têm rótulo e não dá para interagir.

# Extintor preso na parede, com a plaquinha vermelha em cima.
func _extintor() -> void:
	var vermelho := Color(0.78, 0.16, 0.14)
	draw_rect(Rect2(-13.0, -236.0, 26.0, 26.0), vermelho)
	draw_circle(Vector2(0.0, -223.0), 6.0, Color(1, 1, 1, 0.9))
	draw_rect(Rect2(-9.0, -172.0, 18.0, 60.0), vermelho)
	draw_rect(Rect2(-9.0, -172.0, 5.0, 60.0), Color(1, 1, 1, 0.18))
	draw_rect(Rect2(-9.0, -152.0, 18.0, 12.0), Color(0.95, 0.94, 0.90))
	draw_rect(Rect2(-5.0, -181.0, 10.0, 9.0), Color(0.15, 0.15, 0.15))
	draw_polyline(PackedVector2Array([Vector2(5.0, -178.0), Vector2(18.0, -166.0), Vector2(13.0, -140.0)]),
		Color(0.12, 0.12, 0.12), 2.4)
	draw_rect(Rect2(-12.0, -158.0, 24.0, 4.0), Color(0.25, 0.27, 0.26))


# Lixeira de rua de escritório, de metal, com a tampa.
func _lixeira() -> void:
	_elipse(Vector2(0.0, -1.5), 24.0, 3.5, Color(0, 0, 0, 0.14))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-17.0, -54.0), Vector2(17.0, -54.0), Vector2(13.0, -3.0), Vector2(-13.0, -3.0)]),
		Color(0.45, 0.52, 0.50))
	for i in 4:
		var x := -9.0 + i * 6.0
		draw_line(Vector2(x, -48.0), Vector2(x * 0.78, -8.0), Color(0, 0, 0, 0.18), 1.4)
	draw_rect(Rect2(-20.0, -60.0, 40.0, 7.0), Color(0.33, 0.38, 0.36))
	draw_rect(Rect2(-20.0, -60.0, 40.0, 2.0), Color(1, 1, 1, 0.22))


# Placa de "piso molhado", em A.
func _placa() -> void:
	_elipse(Vector2(0.0, -1.5), 26.0, 3.5, Color(0, 0, 0, 0.14))
	var amarelo := Color(0.97, 0.80, 0.15)
	var contorno := PackedVector2Array([
		Vector2(-19.0, -3.0), Vector2(-10.0, -66.0), Vector2(10.0, -66.0), Vector2(19.0, -3.0)])
	draw_colored_polygon(contorno, amarelo)
	draw_polyline(PackedVector2Array([contorno[0], contorno[1], contorno[2], contorno[3], contorno[0]]),
		Color(0.55, 0.40, 0.05), 1.6)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -56.0), Vector2(8.0, -36.0), Vector2(-8.0, -36.0)]), Color(0.15, 0.15, 0.15))
	draw_circle(Vector2(0.0, -39.5), 1.2, amarelo)
	draw_rect(Rect2(-0.9, -52.0, 1.8, 8.0), amarelo)


# Máquina de bebidas, irmã da de salgadinhos: só enfeite.
func _maquina() -> void:
	_elipse(Vector2(0.0, -2.0), 52.0, 4.0, Color(0, 0, 0, 0.14))
	draw_rect(Rect2(-42.0, -196.0, 84.0, 192.0), Color(0.24, 0.40, 0.58))
	draw_rect(Rect2(26.0, -196.0, 16.0, 192.0), Color(0, 0, 0, 0.14))
	draw_rect(Rect2(-36.0, -190.0, 56.0, 16.0), Color(0.96, 0.95, 0.90))
	draw_string(ThemeDB.fallback_font, Vector2(-30.0, -178.0), "BEBIDAS",
		HORIZONTAL_ALIGNMENT_LEFT, 44.0, 11, Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(-36.0, -166.0, 56.0, 108.0), Color(0.11, 0.15, 0.19))
	var cores := [Color(0.80, 0.22, 0.20), Color(0.95, 0.75, 0.20), Color(0.30, 0.65, 0.40),
		Color(0.90, 0.90, 0.88), Color(0.30, 0.50, 0.80)]
	for fila in 3:
		var y := -160.0 + fila * 36.0
		draw_rect(Rect2(-36.0, y + 30.0, 56.0, 3.0), Color(0.30, 0.33, 0.36))
		for k in 4:
			var cor: Color = cores[_rng.randi() % cores.size()]
			draw_rect(Rect2(-32.0 + k * 13.5, y + 6.0, 9.0, 24.0), cor)
			draw_rect(Rect2(-30.0 + k * 13.5, y + 2.0, 5.0, 5.0), cor.darkened(0.3))
	for i in 3:
		draw_rect(Rect2(29.0, -150.0 + i * 16.0, 10.0, 8.0), Color(0.85, 0.87, 0.85))
	draw_rect(Rect2(31.0, -90.0, 6.0, 14.0), Color(0.08, 0.09, 0.10))
	draw_rect(Rect2(-32.0, -48.0, 46.0, 28.0), Color(0.07, 0.08, 0.09))


# Copiadora de escritório, com a tampa do scanner, o painel e a bandeja.
func _xerox() -> void:
	_elipse(Vector2(0.0, -2.0), 50.0, 4.0, Color(0, 0, 0, 0.14))
	draw_rect(Rect2(-40.0, -92.0, 80.0, 88.0), Color(0.88, 0.89, 0.87))
	draw_rect(Rect2(26.0, -92.0, 14.0, 88.0), Color(0, 0, 0, 0.08))
	draw_rect(Rect2(-43.0, -106.0, 86.0, 14.0), Color(0.66, 0.69, 0.69))
	draw_rect(Rect2(-43.0, -106.0, 86.0, 3.0), Color(1, 1, 1, 0.3))
	draw_rect(Rect2(6.0, -86.0, 28.0, 18.0), Color(0.16, 0.18, 0.20))
	draw_rect(Rect2(9.0, -83.0, 14.0, 8.0), Color(0.35, 0.65, 0.75))
	for i in 3:
		draw_circle(Vector2(12.0 + i * 8.0, -71.0), 1.8, Color(0.85, 0.87, 0.85))
	draw_rect(Rect2(-36.0, -56.0, 38.0, 4.0), Color(0.30, 0.32, 0.33))
	draw_rect(Rect2(-30.0, -61.0, 28.0, 5.0), Color(0.98, 0.98, 0.96))
	draw_line(Vector2(-40.0, -34.0), Vector2(40.0, -34.0), Color(0, 0, 0, 0.18), 1.4)
	draw_line(Vector2(0.0, -34.0), Vector2(0.0, -4.0), Color(0, 0, 0, 0.18), 1.4)
	draw_rect(Rect2(-40.0, -8.0, 80.0, 4.0), Color(0.30, 0.32, 0.33))


# Vaso de planta com folhagem.
func _planta() -> void:
	_elipse(Vector2(0.0, -1.5), 26.0, 3.5, Color(0, 0, 0, 0.14))
	var base := Vector2(0.0, -34.0)
	for i in 9:
		var ang := deg_to_rad(-90.0 + (i - 4) * 17.0 + _r(-5.0, 5.0))
		var comp := _r(40.0, 70.0)
		var dir := Vector2(cos(ang), sin(ang))
		var lado := Vector2(-dir.y, dir.x) * (comp * 0.16)
		var ponta := base + dir * comp
		var meio := base + dir * comp * 0.55
		var verde := Color(0.22, 0.45, 0.30).lightened(_r(0.0, 0.25))
		draw_colored_polygon(PackedVector2Array([base, meio + lado, ponta, meio - lado]), verde)
		draw_line(base, ponta, verde.darkened(0.25), 1.2)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18.0, -36.0), Vector2(18.0, -36.0), Vector2(12.0, -3.0), Vector2(-12.0, -3.0)]),
		Color(0.72, 0.42, 0.30))
	draw_rect(Rect2(-20.0, -40.0, 40.0, 7.0), Color(0.62, 0.35, 0.25))
