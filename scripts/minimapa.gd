class_name Minimapa
extends Control

# O mapa do andar, desenhado por código (cenas/ui/minimapa.tscn). Fica
# dentro da janela do mapa (cenas/ui/mapa.tscn), que abre com a tecla M.
#
# Cada setor é um cartão. O cartão mostra o número, o nome e quantos
# móveis já foram examinados. Os corredores ligam os cartões pelas
# portas, e a porta trancada aparece tracejada, com cadeado.
#
#   verde cheio   setor onde você está
#   branco        setor já visitado
#   tracejado     setor que dá para ver a porta, mas nunca entrou
#
# Onde cada cartão fica vem do campo "Posicao Mapa" da cena do setor,
# em colunas e linhas: (0, 0) é o canto de cima à esquerda, (1, 0) é o
# cartão ao lado, (0, 1) é o de baixo. O desenho se centraliza e, se
# não couber, diminui sozinho. A topologia (quem liga com quem) vem das
# portas das cenas dos setores (ver Dados).

const Dados = preload("res://dados/setores.gd")

const PAPEL := Color(0.96, 0.95, 0.93)
const TINTA := Color(0.10, 0.10, 0.10)
const TEXTO_SUAVE := Color(0.38, 0.40, 0.39)
const VERDE := Color(0.12, 0.31, 0.27)
const VERDE_ESCURO := Color(0.06, 0.19, 0.16)
const VERDE_CLARO := Color(0.66, 0.86, 0.78)
const CINZA := Color(0.62, 0.65, 0.63)
const CORREDOR := Color(0.87, 0.89, 0.86)
const ALERTA := Color(0.70, 0.26, 0.23)

const CARTAO := Vector2(190, 104)
const ESPACO := Vector2(80, 62)
const RESERVA_SAIDA := 56.0     # espaço em cima, para a placa de saída
const RESERVA_LEGENDA := 40.0   # espaço embaixo, para a legenda

var setor_atual := 1

var _escala := 1.0
var _origem := Vector2.ZERO
var _minimo := Vector2.ZERO


func _ready() -> void:
	Estado.mapa_mudou.connect(queue_redraw)


func definir_setor(numero: int) -> void:
	setor_atual = numero
	queue_redraw()


# Um setor é conhecido quando dá para ver a porta dele de algum
# lugar já visitado, mesmo sem nunca ter entrado.
func _conhecido(numero: int) -> bool:
	if Estado.visitados.has(numero):
		return true
	for visitado in Estado.visitados:
		if Dados.vizinhos(visitado).has(numero):
			return true
	return false


# A ligação entre dois setores está trancada se qualquer uma das portas
# dela pede a chave e o jogador ainda não tem.
func _trancada(a: int, b: int) -> bool:
	if Estado.tem_chave:
		return false
	for par in [[a, b], [b, a]]:
		for p in Dados.info(par[0])["portas"]:
			if p["destino"] == par[1] and p["exige_chave"]:
				return true
	return false


# ------------------------------------------------------------ layout

func _calcular_layout() -> void:
	var maximo := Vector2(-INF, -INF)
	_minimo = Vector2(INF, INF)
	for numero in Dados.numeros():
		var g: Vector2 = Dados.info(numero)["mapa"]
		_minimo = _minimo.min(g)
		maximo = maximo.max(g)

	var passo := CARTAO + ESPACO
	var ocupado := (maximo - _minimo) * passo + CARTAO
	var area := Vector2(size.x, size.y - RESERVA_SAIDA - RESERVA_LEGENDA)
	_escala = minf(1.0, minf(area.x / ocupado.x, area.y / ocupado.y))
	_origem = Vector2(
		(size.x - ocupado.x * _escala) / 2.0,
		RESERVA_SAIDA + (area.y - ocupado.y * _escala) / 2.0)


# Canto de cima à esquerda do cartão, em coordenadas do desenho (sem escala).
func _canto(numero: int) -> Vector2:
	var g: Vector2 = Dados.info(numero)["mapa"]
	return (g - _minimo) * (CARTAO + ESPACO)


func _centro(numero: int) -> Vector2:
	return _canto(numero) + CARTAO / 2.0


# ------------------------------------------------------------ desenho

func _draw() -> void:
	_calcular_layout()
	_pontilhado()

	draw_set_transform(_origem, 0.0, Vector2(_escala, _escala))

	# corredores primeiro, para ficarem atrás dos cartões
	var feitos := {}
	for numero in Dados.numeros():
		if not Estado.visitados.has(numero):
			continue
		for vizinho in Dados.vizinhos(numero):
			var chave := Vector2i(mini(numero, vizinho), maxi(numero, vizinho))
			if feitos.has(chave):
				continue
			feitos[chave] = true
			_corredor(numero, vizinho)

	for numero in Dados.numeros():
		if _conhecido(numero):
			_cartao(numero)

	_saida()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_legenda()


# Papel quadriculado de fundo, bem discreto.
func _pontilhado() -> void:
	var cor := Color(0.0, 0.0, 0.0, 0.07)
	var x := 12.0
	while x < size.x:
		var y := 12.0
		while y < size.y:
			draw_circle(Vector2(x, y), 1.1, cor)
			y += 24.0
		x += 24.0


func _corredor(a: int, b: int) -> void:
	var ca := _centro(a)
	var cb := _centro(b)
	if _trancada(a, b):
		_tracejada(ca, cb, ALERTA, 3.0, 9.0, 7.0)
		_cadeado((ca + cb) / 2.0)
	else:
		draw_line(ca, cb, CORREDOR, 18.0)
		var dir := (cb - ca).normalized()
		var lado := Vector2(-dir.y, dir.x) * 9.0
		draw_line(ca + lado, cb + lado, CINZA, 1.5)
		draw_line(ca - lado, cb - lado, CINZA, 1.5)


func _cartao(numero: int) -> void:
	var canto := _canto(numero)
	var caixa := Rect2(canto, CARTAO)
	var visitado: bool = Estado.visitados.has(numero)
	var atual: bool = numero == setor_atual

	if atual:
		var s := _estilo(VERDE, VERDE_ESCURO, 2, Color(0.12, 0.31, 0.27, 0.30), 12)
		draw_style_box(s, caixa)
		_numero_e_nome(numero, canto, Color(1, 1, 1), VERDE_CLARO)
		_progresso(numero, canto, VERDE_CLARO, Color(1, 1, 1, 0.45), VERDE_CLARO)
		_etiqueta_voce(canto)
	elif visitado:
		var s := _estilo(Color(1, 1, 1), TINTA, 2, Color(0, 0, 0, 0.12), 8)
		draw_style_box(s, caixa)
		_numero_e_nome(numero, canto, TINTA, TEXTO_SUAVE)
		_progresso(numero, canto, VERDE, CINZA, TEXTO_SUAVE)
	else:
		var s := _estilo(Color(0.93, 0.93, 0.91), Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), 0)
		draw_style_box(s, caixa)
		_retangulo_tracejado(caixa.grow(-1.0), CINZA, 2.0)
		_texto_centrado(canto + Vector2(0, 56), CARTAO.x, "?", 38, CINZA)
		_texto_centrado(canto + Vector2(0, 80), CARTAO.x, "não explorado", 12, CINZA)

	# marcas de porta nas bordas dos corredores
	if visitado:
		for vizinho in Dados.vizinhos(numero):
			_marca_de_porta(numero, vizinho)


func _numero_e_nome(numero: int, canto: Vector2, cor_numero: Color, cor_nome: Color) -> void:
	_texto(canto + Vector2(16, 44), "%02d" % numero, 32, cor_numero)
	var nome: String = Dados.info(numero)["nome"]
	_texto(canto + Vector2(16, 64), nome, 13, cor_nome)


# Um ponto por móvel do setor: cheio se já examinou, vazado se não.
func _progresso(numero: int, canto: Vector2, cor_cheio: Color, cor_vazio: Color, cor_texto: Color) -> void:
	var total: int = Dados.moveis_do_setor(numero)
	var vistos: int = Estado.examinados_no_setor(numero)
	for i in total:
		var p := canto + Vector2(20 + i * 13, 84)
		if i < vistos:
			draw_circle(p, 4.0, cor_cheio)
		else:
			draw_arc(p, 3.6, 0.0, TAU, 14, cor_vazio, 1.5)
	var fonte := ThemeDB.fallback_font
	var txt := "%d/%d" % [vistos, total]
	var larg := fonte.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	_texto(canto + Vector2(CARTAO.x - 16 - larg, 89), txt, 12, cor_texto)


# Pílula "você está aqui" na quina de cima do cartão atual.
func _etiqueta_voce(canto: Vector2) -> void:
	var fonte := ThemeDB.fallback_font
	var txt := "VOCÊ ESTÁ AQUI"
	var larg := fonte.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 34.0
	var caixa := Rect2(canto + Vector2(CARTAO.x - larg - 12, -10), Vector2(larg, 20))
	draw_style_box(_estilo(PAPEL, VERDE, 2, Color(0, 0, 0, 0.12), 4, 10), caixa)
	draw_circle(caixa.position + Vector2(10, 10), 3.0, VERDE)
	_texto(caixa.position + Vector2(18, 14), txt, 10, VERDE)


func _marca_de_porta(numero: int, vizinho: int) -> void:
	var de := _centro(numero)
	var para := _centro(vizinho)
	var dir := (para - de).normalized()
	var metade := CARTAO / 2.0
	var t := minf(metade.x / maxf(absf(dir.x), 0.0001), metade.y / maxf(absf(dir.y), 0.0001))
	var borda := de + dir * t
	var lado := Vector2(-dir.y, dir.x)
	var cor := ALERTA if _trancada(numero, vizinho) else TINTA
	draw_line(borda - lado * 8.0, borda + lado * 8.0, cor, 4.0)


# Placa de saída, pendurada em cima do setor 01 quando o jogador já sabe
# onde fica o elevador.
func _saida() -> void:
	if not (Estado.marcos.has(1) or Estado.foi_examinado(1, "Planta de evacuação")):
		return
	var topo := _canto(1)
	# a haste fica na esquerda do cartão, para não bater na etiqueta "você está aqui"
	var centro_x := topo.x + 40.0
	var caixa := Rect2(Vector2(centro_x - 58, topo.y - 50), Vector2(116, 30))
	draw_line(Vector2(centro_x, caixa.end.y), Vector2(centro_x, topo.y), VERDE, 2.0)
	draw_style_box(_estilo(Color(1, 1, 1), VERDE, 2, Color(0, 0, 0, 0.10), 6, 6), caixa)
	# ícone de elevador: duas portas
	var ic := caixa.position + Vector2(14, 7)
	draw_rect(Rect2(ic, Vector2(7, 16)), VERDE)
	draw_rect(Rect2(ic + Vector2(9, 0), Vector2(7, 16)), VERDE)
	_texto(caixa.position + Vector2(40, 20), "SAÍDA", 13, VERDE)


func _cadeado(centro: Vector2) -> void:
	draw_circle(centro, 15.0, PAPEL)
	draw_arc(centro, 15.0, 0.0, TAU, 28, ALERTA, 2.0)
	draw_arc(centro + Vector2(0, -2), 4.5, PI, TAU, 12, ALERTA, 2.2)
	var corpo := Rect2(centro + Vector2(-6, -2), Vector2(12, 10))
	draw_style_box(_estilo(ALERTA, ALERTA, 0, Color(0, 0, 0, 0), 0, 2), corpo)


# ----------------------------------------------------------- legenda

func _legenda() -> void:
	var y := size.y - 20.0
	var fonte := ThemeDB.fallback_font
	var itens := [
		["atual", "Você está aqui"],
		["visitado", "Visitado"],
		["oculto", "Não explorado"],
		["trancada", "Porta trancada"],
		["ponto", "Móvel examinado"],
	]
	var larg_icone := 20.0
	var folga := 26.0
	var total := 0.0
	for it in itens:
		total += larg_icone + 7.0 + fonte.get_string_size(it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	total += folga * (itens.size() - 1)

	var x := (size.x - total) / 2.0
	for it in itens:
		var c := Vector2(x + larg_icone / 2.0, y - 4.0)
		match it[0]:
			"atual":
				draw_style_box(_estilo(VERDE, VERDE_ESCURO, 1, Color(0, 0, 0, 0), 0, 3), Rect2(c - Vector2(10, 6), Vector2(20, 12)))
			"visitado":
				draw_style_box(_estilo(Color(1, 1, 1), TINTA, 1, Color(0, 0, 0, 0), 0, 3), Rect2(c - Vector2(10, 6), Vector2(20, 12)))
			"oculto":
				_retangulo_tracejado(Rect2(c - Vector2(10, 6), Vector2(20, 12)), CINZA, 1.5, 4.0, 3.0)
			"trancada":
				_tracejada(c - Vector2(10, 0), c + Vector2(10, 0), ALERTA, 2.5, 5.0, 4.0)
			"ponto":
				draw_circle(c - Vector2(5, 0), 3.5, VERDE)
				draw_arc(c + Vector2(5, 0), 3.2, 0.0, TAU, 12, CINZA, 1.5)
		var tam := fonte.get_string_size(it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		_texto(Vector2(x + larg_icone + 7.0, y), it[1], 12, TEXTO_SUAVE)
		x += larg_icone + 7.0 + tam + folga


# ----------------------------------------------------------- ajudantes

func _estilo(fundo: Color, borda: Color, esp: int, sombra: Color, tam_sombra: int, raio := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = borda
	s.set_border_width_all(esp)
	s.set_corner_radius_all(raio)
	s.shadow_color = sombra
	s.shadow_size = tam_sombra
	s.shadow_offset = Vector2(0, 3)
	s.anti_aliasing = true
	return s


func _texto(base: Vector2, texto: String, tamanho: int, cor: Color) -> void:
	draw_string(ThemeDB.fallback_font, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)


func _texto_centrado(base: Vector2, largura: float, texto: String, tamanho: int, cor: Color) -> void:
	draw_string(ThemeDB.fallback_font, base, texto, HORIZONTAL_ALIGNMENT_CENTER, largura, tamanho, cor)


func _tracejada(de: Vector2, para: Vector2, cor: Color, largura := 1.5, traco := 4.0, vao := 3.0) -> void:
	var total := de.distance_to(para)
	var dir := (para - de).normalized()
	var d := 0.0
	while d < total:
		var fim := minf(d + traco, total)
		draw_line(de + dir * d, de + dir * fim, cor, largura)
		d += traco + vao


func _retangulo_tracejado(r: Rect2, cor: Color, largura: float, traco := 7.0, vao := 5.0) -> void:
	var a := r.position
	var b := Vector2(r.end.x, r.position.y)
	var c := r.end
	var d := Vector2(r.position.x, r.end.y)
	_tracejada(a, b, cor, largura, traco, vao)
	_tracejada(b, c, cor, largura, traco, vao)
	_tracejada(c, d, cor, largura, traco, vao)
	_tracejada(d, a, cor, largura, traco, vao)
