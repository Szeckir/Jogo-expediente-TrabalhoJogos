class_name Npc
extends ItemDoAnel

# Gente de fundo. Não é móvel: não tem rótulo, não abre tela e não conta no
# mapa; só dá vida ao setor. Fica no anel como qualquer item, mas sem
# colisão, então o jogador passa por trás.
#
# O boneco é desenhado por código, com as mesmas proporções e o mesmo
# traço do jogador (membros de linha com ponta redonda, tronco arredondado,
# cabeça de círculo). Cada papel tem a sua animação:
#
#   CAMINHAR    anda de um lado a outro (a posição no anel muda), para um
#               pouco nas pontas e volta
#   CONVERSAR   fica parado, gesticulando; dois NPCs com o mesmo `grupo`
#               (e `lado` 0 e 1) conversam de verdade, falando uma linha de
#               uma das CONVERSAS de cada vez, na ordem
#   TRABALHAR   sentado numa mesa, digitando, com monitor e cadeira
#
# Quem anda ou trabalha resmunga uma frase de `falas` de vez em quando.
#
# O desenho nunca usa transformação de espelho: o lado para onde o boneco
# olha entra nas contas como `_v` (1 ou -1), que multiplica todo x.

enum Papel { CAMINHAR, CONVERSAR, TRABALHAR }

# Conversas de bebedouro: linhas alternadas, a primeira é do lado 0.
const CONVERSAS := [
	["Viu o café hoje? Tava frio de novo.",
	 "Frio é elogio. Ontem veio morno e sem açúcar.",
	 "Esse bebedouro também só dá água quente.",
	 "Reclama pro RH. Ah, verdade, não tem RH."],
	["Você já saiu antes das sete esse mês?",
	 "Que mês? Parei de contar no segundo.",
	 "Dizem que tem um elevador que leva embora daqui.",
	 "Dizem muita coisa. Bebe sua água."],
	["O terminal pediu pra eu ligar uns pontos.",
	 "E você ligou todos?",
	 "Sobrou um quadradinho. Deu um tremelique na tela.",
	 "Tem que cobrir tudo, né? Sempre tem pegadinha."],
	["Meu chefe disse que hoje é um expediente curtinho.",
	 "Ele diz isso desde terça.",
	 "Eu acreditei até quarta.",
	 "Eu ainda acredito. É o que me segura."],
	["Tá cansado?",
	 "Cansado é pouco. Tô em modo de economia de energia.",
	 "Eu já tô no modo avião.",
	 "Bom, ao menos o wi-fi pega no corredor."],
]

static var _conversas := {}   # grupo -> { linhas, i, fala, vez, proxima }

@export var papel: Papel = Papel.CAMINHAR
## Para onde olha: 1 direita, -1 esquerda.
@export var virado := 1
## CAMINHAR: até onde vai para cada lado a partir do ponto inicial, em px.
@export var alcance := 180.0
@export var velocidade := 34.0
@export var camisa := Color(0.30, 0.45, 0.62)
@export var calca := Color(0.25, 0.27, 0.32)
@export var cabelo := Color(0.20, 0.15, 0.12)
@export var pele := Color(0.79, 0.61, 0.49)
## Defasagem das animações, para dois bonecos iguais não se mexerem juntos.
@export var fase := 0.0
## Frases soltas de quem anda ou trabalha.
@export var falas: PackedStringArray = []
## CONVERSAR: id da conversa. Dois NPCs com o mesmo grupo conversam entre si.
@export var grupo := ""
## CONVERSAR: 0 começa a conversa, 1 responde.
@export var lado := 0

var _t := 0.0
var _origem := 0.0
var _espera := 0.0
var _andando := false
var _v := 1.0
var _fala := ""
var _fala_ate := 0.0
var _proxima_fala := 0.0
var _tronco: StyleBoxFlat
var _caixa_balao: StyleBoxFlat


func _ready() -> void:
	super._ready()
	_origem = x_anel
	_t = fase
	_v = float(virado)
	_proxima_fala = _t + randf_range(2.0, 6.0)
	if grupo != "" and lado == 0:
		_conversas[grupo] = {"linhas": CONVERSAS.pick_random(), "i": -1,
			"fala": "", "vez": -1, "proxima": _t + randf_range(1.0, 3.0)}
	_tronco = StyleBoxFlat.new()
	_tronco.bg_color = camisa
	_tronco.set_corner_radius_all(9)
	_tronco.anti_aliasing = true
	_caixa_balao = StyleBoxFlat.new()
	_caixa_balao.bg_color = Color(0.99, 0.99, 0.98)
	_caixa_balao.border_color = Color(0.10, 0.10, 0.10)
	_caixa_balao.set_border_width_all(2)
	_caixa_balao.set_corner_radius_all(9)
	_caixa_balao.anti_aliasing = true


func _process(delta: float) -> void:
	_t += delta
	if papel == Papel.CAMINHAR:
		_caminhar(delta)
	if grupo == "":
		_murmurar()
	elif lado == 0:
		_conversar()
	if visible:
		queue_redraw()


func _caminhar(delta: float) -> void:
	if _t < _espera:
		_andando = false
		return
	_andando = true
	x_anel += _v * velocidade * delta
	var limite := _origem + alcance * _v
	if (_v > 0.0 and x_anel >= limite) or (_v < 0.0 and x_anel <= limite):
		_v = -_v
		_espera = _t + randf_range(1.5, 3.5)


# Resmungo ocasional, em voz alta, para ninguém.
func _murmurar() -> void:
	if falas.is_empty() or _t < _proxima_fala:
		return
	_fala = falas[randi() % falas.size()]
	_fala_ate = _t + 2.6 + 0.05 * _fala.length()
	_proxima_fala = _fala_ate + randf_range(5.0, 11.0)


# Só o lado 0 puxa a conversa: troca a linha quando a anterior já deu tempo
# de ler e, no fim, faz uma pausa e sorteia outra conversa.
func _conversar() -> void:
	var c: Dictionary = _conversas[grupo]
	if _t < float(c["proxima"]):
		return
	var linhas: Array = c["linhas"]
	var i := int(c["i"]) + 1
	if i >= linhas.size():
		c["linhas"] = CONVERSAS.pick_random()
		c["i"] = -1
		c["fala"] = ""
		c["vez"] = -1
		c["proxima"] = _t + randf_range(4.0, 8.0)
		return
	var texto: String = linhas[i]
	c["i"] = i
	c["fala"] = texto
	c["vez"] = i % 2
	c["proxima"] = _t + 2.4 + 0.05 * texto.length()


# O que este NPC está dizendo agora ("" se está calado).
func _minha_fala() -> String:
	if grupo != "":
		if not _conversas.has(grupo):
			return ""
		var c: Dictionary = _conversas[grupo]
		return str(c["fala"]) if int(c["vez"]) == lado else ""
	return _fala if _t < _fala_ate else ""


# ----------------------------------------------------------- desenho

func _draw() -> void:
	if _tronco == null:
		return
	_elipse(_p(0, -1.4), 30.0, 3.4, Color(0, 0, 0, 0.12))
	match papel:
		Papel.CAMINHAR:
			_desenhar_em_pe(_t * 8.5 if _andando else 0.0, _andando)
			if _minha_fala() != "":
				_balao(_p(2.0, -126.0), _minha_fala())
		Papel.CONVERSAR: _desenhar_conversando()
		Papel.TRABALHAR:
			_desenhar_trabalhando()
			if _minha_fala() != "":
				_balao(_p(2.0, -118.0), _minha_fala())


# Ponto do boneco: x espelha conforme o lado para onde ele olha.
func _p(x: float, y: float) -> Vector2:
	return Vector2(x * _v, y)


func _elipse(centro: Vector2, rx: float, ry: float, cor: Color) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		var ang := TAU * i / 14.0
		pts.append(centro + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_colored_polygon(pts, cor)


func _retangulo(x0: float, y0: float, x1: float, y1: float, cor: Color) -> void:
	var a := _p(x0, y0)
	var b := _p(x1, y1)
	draw_rect(Rect2(a, b - a).abs(), cor)


# Membro de linha com ponta redonda, como o stroke-linecap round do SVG.
func _membro(a: Vector2, b: Vector2, largura: float, cor: Color) -> void:
	draw_line(a, b, cor, largura)
	draw_circle(a, largura / 2.0, cor)
	draw_circle(b, largura / 2.0, cor)


func _perna(quadril: Vector2, angulo: float, cor: Color) -> void:
	var joelho := quadril + Vector2(sin(angulo) * _v, cos(angulo)) * 27.0
	var pe := joelho + Vector2(sin(angulo * 0.5) * _v, cos(angulo * 0.5)) * 27.0
	_membro(quadril, joelho, 10.5, cor)
	_membro(joelho, pe, 9.3, cor)
	_elipse(pe + _p(4.0, -2.0), 8.6, 4.4, Color(0.16, 0.14, 0.13))


# Braço de dois segmentos: manga na cor da camisa, mão na da pele.
func _braco(ombro: Vector2, cotovelo: Vector2, mao: Vector2) -> void:
	_membro(ombro, cotovelo, 8.6, camisa.darkened(0.12))
	_membro(cotovelo, mao, 7.8, pele.darkened(0.08))


# Tronco, pescoço e cabeça. `dy` desce o conjunto (usado sentado).
func _busto(dy: float, balanco: float) -> void:
	var topo := -92.0 + dy
	draw_style_box(_tronco, Rect2(Vector2(-12.5, topo), Vector2(25.0, 41.0)))
	draw_rect(Rect2(Vector2(2.0 if _v > 0 else -12.5, topo), Vector2(10.5, 41.0)), Color(0, 0, 0, 0.08))
	_retangulo(-2, -98.0 + dy, 6, -89.0 + dy, pele.darkened(0.08))   # pescoço

	var cabeca := _p(2.0, -107.0 + dy + balanco)
	draw_circle(cabeca, 12.6, pele)
	# cabelo: calota que cobre o alto e o fundo da cabeça
	var pts := PackedVector2Array([cabeca])
	var de := 150.0 if _v > 0 else 210.0
	var ate := 345.0 if _v > 0 else 390.0
	for i in 15:
		var ang := deg_to_rad(lerpf(de, ate, i / 14.0))
		pts.append(cabeca + Vector2(cos(ang), sin(ang)) * 13.4)
	draw_colored_polygon(pts, cabelo)
	draw_circle(cabeca + _p(6.2, 0.0), 1.5, Color(0.11, 0.15, 0.13))


func _desenhar_em_pe(fase_perna: float, andando: bool) -> void:
	var quadril := _p(0.0, -54.0)
	var amp := 0.55 if andando else 0.05
	var a := sin(fase_perna) * amp
	_perna(quadril, -a, calca.darkened(0.15))
	_perna(quadril, a, calca)

	var respira := sin(_t * 2.0) * 0.8
	_busto(0.0, respira)
	var ombro := _p(0.5, -87.0)
	var b := -a * 0.9 if andando else sin(_t * 1.4) * 0.05
	for lado in [-1.0, 1.0]:
		var ang: float = b * lado
		var cot := ombro + Vector2(sin(ang) * _v, cos(ang)) * 19.0
		_braco(ombro, cot, cot + Vector2(sin(ang * 1.4) * _v, cos(ang * 1.4)) * 18.0)


func _desenhar_conversando() -> void:
	var quadril := _p(0.0, -54.0)
	_perna(quadril, -0.04, calca.darkened(0.15))
	_perna(quadril, 0.06, calca)
	_busto(0.0, sin(_t * 2.0 + fase) * 0.8)

	var fala := _minha_fala()
	var falando := fala != ""
	var ombro := _p(0.5, -87.0)
	# braço de trás, parado
	var cot_t := ombro + _p(-2.0, 19.0)
	_braco(ombro, cot_t, cot_t + _p(-1.0, 17.0))
	# braço da frente: gesticula enquanto fala, descansa quando escuta
	var cot := ombro + _p(10.0, 15.0)
	var mao := cot + _p(13.0, 6.0)
	if falando:
		cot = ombro + _p(13.0, 8.0)
		mao = cot + _p(14.0, -11.0 + sin(_t * 7.0) * 6.0)
	_braco(ombro, cot, mao)

	if falando:
		_balao(_p(2.0, -126.0), fala)


# Balão com o texto, em cima de `ancora` (a ponta do rabinho).
func _balao(ancora: Vector2, texto: String) -> void:
	var fonte := ThemeDB.fallback_font
	var tam := 12
	var area := fonte.get_multiline_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, 150.0, tam)
	var tamanho := area + Vector2(16.0, 12.0)
	var caixa := Rect2(Vector2(ancora.x - tamanho.x / 2.0, ancora.y - 10.0 - tamanho.y), tamanho)
	var tinta := Color(0.10, 0.10, 0.10)
	var papel_cor := Color(0.99, 0.99, 0.98)
	var ponta := Vector2(ancora.x + 3.0 * _v, ancora.y)
	draw_colored_polygon(PackedVector2Array([
		Vector2(ancora.x - 7.0, caixa.end.y - 2.0), Vector2(ancora.x + 7.0, caixa.end.y - 2.0),
		ponta]), tinta)
	draw_style_box(_caixa_balao, caixa)
	draw_colored_polygon(PackedVector2Array([
		Vector2(ancora.x - 5.0, caixa.end.y - 2.0), Vector2(ancora.x + 5.0, caixa.end.y - 2.0),
		ponta + Vector2(0.0, -3.0)]), papel_cor)
	draw_multiline_string(fonte, caixa.position + Vector2(8.0, 6.0 + fonte.get_ascent(tam)),
		texto, HORIZONTAL_ALIGNMENT_LEFT, 150.0, tam, -1, tinta)


# Sentado, de frente para a mesa (que fica no lado para onde ele olha).
func _desenhar_trabalhando() -> void:
	# cadeira, atrás do boneco
	_retangulo(-28, -84, -22, -40, Color(0.28, 0.30, 0.33))
	_retangulo(-26, -42, 4, -37, Color(0.28, 0.30, 0.33))
	_retangulo(-12, -37, -8, -6, Color(0.22, 0.24, 0.26))
	_retangulo(-24, -6, 4, -2, Color(0.22, 0.24, 0.26))

	# coxa na horizontal, canela na vertical
	var quadril := _p(-4.0, -42.0)
	var joelho := _p(20.0, -42.0)
	var pe := _p(22.0, -5.0)
	_membro(quadril, joelho, 10.5, calca)
	_membro(joelho, pe, 9.3, calca)
	_elipse(pe + _p(4.0, -2.0), 8.6, 4.4, Color(0.16, 0.14, 0.13))

	_busto(12.0, sin(_t * 1.6 + fase) * 0.6)

	# mesa e monitor, na frente
	_retangulo(34, -66, 118, -60, Color(0.80, 0.74, 0.64))
	_retangulo(38, -60, 114, 0, Color(0.64, 0.58, 0.50))
	_retangulo(42, -56, 110, -14, Color(0.56, 0.50, 0.43))
	_retangulo(66, -72, 82, -66, Color(0.15, 0.16, 0.17))
	_retangulo(48, -112, 100, -72, Color(0.15, 0.16, 0.17))
	var brilho := 0.55 + 0.1 * sin(_t * 3.0)
	_retangulo(52, -108, 96, -76, Color(0.30, 0.52, 0.60).lightened(brilho * 0.2))
	for i in 3:
		_retangulo(57, -102.0 + i * 8.0, 57.0 + 22.0 + (i * 9) % 16, -99.0 + i * 8.0, Color(1, 1, 1, 0.5))
	_retangulo(36, -63, 56, -60, Color(0.20, 0.21, 0.22))

	# braços no teclado, com o balanço de quem digita
	var ombro := _p(0.5, -75.0)
	var bate := sin(_t * 11.0 + fase) * 1.6
	var cot := ombro + _p(16.0, 11.0)
	_braco(ombro, cot, _p(40.0, -65.0 + bate))
	var cot2 := ombro + _p(12.0, 13.0)
	_braco(ombro, cot2, _p(36.0, -64.0 - bate))
