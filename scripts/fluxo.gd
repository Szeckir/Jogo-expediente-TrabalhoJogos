class_name Fluxo
extends Control

# A grade de fluxo do terminal (cenas/ui/fluxo.tscn): ligar cada par de
# pontas sem cruzar ninguém e **sem deixar célula vazia**. É a rodada
# final, e a única do terminal que não se resolve num palpite.
#
# Como as cartelas são geradas: todo caminho hamiltoniano da grade,
# cortado em pedaços, já é uma solução válida que cobre tudo. Então o
# gerador sorteia um hamiltoniano (algoritmo "backbite": pega uma ponta,
# escolhe um vizinho dela que já esteja no caminho e inverte o trecho
# entre os dois), corta em pedaços de tamanho parecido e esconde o miolo,
# deixando só as pontas. Isso garante que toda cartela tem solução.
#
# Sem cor, como o resto do terminal. O que separa um par do outro é o
# **traço** (cheio, tracejado, pontilhado, vazado) e o **marcador** da
# ponta (círculo, quadrado, triângulo, losango).

signal resolvido
signal mudou

const TINTA := Color(0.10, 0.10, 0.10)
const GRADE := Color(0.78, 0.80, 0.77)
const FUNDO := Color(0.99, 0.99, 0.98)
const MOLDURA := Color(0.38, 0.40, 0.39)

## Tamanho da grade. 5 x 5 com 4 pares é a cartela padrão do jogo.
@export var colunas := 5
@export var linhas := 5
## Quantos pares de pontas a cartela tem (no máximo 4: são 4 traços).
@export var pares := 4
## Limites de tamanho de cada caminho, para não sair uma cobra e três tocos.
@export var minimo := 4
@export var maximo := 9

var _pontas: Array[Array] = []    # par -> [ponta_a, ponta_b]
var _trilhas: Array[Array] = []   # par -> células, a partir de uma das pontas
var _dono := {}                   # célula -> índice do par que a ocupa
var _arrastando := -1
var _pronto := false


# ---------------------------------------------------------- cartela

func gerar() -> void:
	var segmentos: Array = []
	for _tentativa in 40:
		segmentos = _cortar(_hamiltoniano())
		if not segmentos.is_empty() and not _pontas_coladas(segmentos):
			break
	if segmentos.is_empty():
		segmentos = _cortar(_hamiltoniano())

	_pontas.clear()
	for s in segmentos:
		_pontas.append([s[0], s[s.size() - 1]])
	limpar()


# Tira todas as trilhas da mesa, mantendo a mesma cartela.
func limpar() -> void:
	_trilhas.clear()
	_dono.clear()
	for _i in _pontas.size():
		_trilhas.append([])
	_arrastando = -1
	_pronto = false
	queue_redraw()
	mudou.emit()


func progresso() -> String:
	var ligados := 0
	for par in _pontas.size():
		if _fechada(par):
			ligados += 1
	return "%d de %d pares ligados  ·  %d de %d células" % [
		ligados, _pontas.size(), _dono.size(), colunas * linhas]


# Caminho que passa uma vez por cada célula. Começa na serpentina e
# embaralha com o "backbite".
func _hamiltoniano() -> Array:
	var cam: Array = []
	for y in linhas:
		for i in colunas:
			cam.append(Vector2i(i if y % 2 == 0 else colunas - 1 - i, y))

	var pos := {}
	for i in cam.size():
		pos[cam[i]] = i
	var n := cam.size()

	for _giro in 300:
		var k := -1
		var inicio := 0
		if randi() % 2 == 0:
			# morde pela ponta final
			var candidatos := []
			for v in _vizinhos(cam[n - 1]):
				if pos[v] < n - 2:
					candidatos.append(v)
			if candidatos.is_empty():
				continue
			k = pos[candidatos.pick_random()]
			inicio = k + 1
			var cauda: Array = cam.slice(inicio)
			cauda.reverse()
			for i in cauda.size():
				cam[inicio + i] = cauda[i]
		else:
			# morde pela ponta inicial
			var candidatos := []
			for v in _vizinhos(cam[0]):
				if pos[v] > 1:
					candidatos.append(v)
			if candidatos.is_empty():
				continue
			k = pos[candidatos.pick_random()]
			var cabeca: Array = cam.slice(0, k)
			cabeca.reverse()
			for i in cabeca.size():
				cam[i] = cabeca[i]

		for i in cam.size():
			pos[cam[i]] = i

	return cam


# Reparte o caminho em pedaços de tamanho parecido.
func _cortar(caminho: Array) -> Array:
	var n := caminho.size()
	if n < pares * minimo or n > pares * maximo:
		return []

	var tam := []
	for _i in pares:
		tam.append(minimo)
	var sobra := n - pares * minimo
	while sobra > 0:
		var i := randi() % pares
		if tam[i] < maximo:
			tam[i] += 1
			sobra -= 1

	var segmentos := []
	var corte := 0
	for t in tam:
		segmentos.append(caminho.slice(corte, corte + t))
		corte += t
	return segmentos


# Par com as duas pontas encostadas fica feio e entrega meio caminho.
func _pontas_coladas(segmentos: Array) -> bool:
	for s in segmentos:
		var a: Vector2i = s[0]
		var b: Vector2i = s[s.size() - 1]
		if absi(a.x - b.x) + absi(a.y - b.y) == 1:
			return true
	return false


func _vizinhos(c: Vector2i) -> Array:
	var saida := []
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var v: Vector2i = c + d
		if v.x >= 0 and v.y >= 0 and v.x < colunas and v.y < linhas:
			saida.append(v)
	return saida


# ----------------------------------------------------------- estado

func _par_da_ponta(c: Vector2i) -> int:
	for par in _pontas.size():
		if _pontas[par][0] == c or _pontas[par][1] == c:
			return par
	return -1


func _fechada(par: int) -> bool:
	var t: Array = _trilhas[par]
	if t.size() < 2:
		return false
	var a: Vector2i = t[0]
	var b: Vector2i = t[t.size() - 1]
	return (a == _pontas[par][0] and b == _pontas[par][1]) \
		or (a == _pontas[par][1] and b == _pontas[par][0])


# Corta a trilha do par a partir da célula (a célula também sai).
func _cortar_em(par: int, c: Vector2i) -> void:
	var t: Array = _trilhas[par]
	var i := t.find(c)
	if i < 0:
		return
	for j in range(i, t.size()):
		_dono.erase(t[j])
	_trilhas[par] = t.slice(0, i)


# ------------------------------------------------------------ mouse

func _gui_input(event: InputEvent) -> void:
	if _pronto:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pegar(_celula_em(event.position))
		else:
			_arrastando = -1
	elif event is InputEventMouseMotion and _arrastando >= 0:
		_estender(_celula_em(event.position))


func _pegar(c: Vector2i) -> void:
	if c.x < 0:
		return

	var par := _par_da_ponta(c)
	if par >= 0:
		# clicou numa ponta: a trilha daquele par recomeça dali
		for celula in _trilhas[par]:
			_dono.erase(celula)
		_trilhas[par] = [c]
		_dono[c] = par
		_arrastando = par
		queue_redraw()
		mudou.emit()
		return

	if _dono.has(c):
		# pegou no meio de uma trilha: continua de lá, jogando fora o resto
		par = _dono[c]
		var t: Array = _trilhas[par]
		var i := t.find(c)
		for j in range(i + 1, t.size()):
			_dono.erase(t[j])
		_trilhas[par] = t.slice(0, i + 1)
		_arrastando = par
		queue_redraw()
		mudou.emit()


func _estender(c: Vector2i) -> void:
	if c.x < 0:
		return
	var trilha: Array = _trilhas[_arrastando]
	if trilha.is_empty():
		return

	var ultima: Vector2i = trilha[trilha.size() - 1]
	if c == ultima:
		return

	# arrastar de volta por cima do próprio rastro desfaz
	if trilha.size() >= 2 and c == trilha[trilha.size() - 2]:
		_dono.erase(ultima)
		trilha.remove_at(trilha.size() - 1)
		queue_redraw()
		mudou.emit()
		return

	if absi(c.x - ultima.x) + absi(c.y - ultima.y) != 1:
		return          # só anda para célula vizinha
	if _fechada(_arrastando):
		return          # já ligou as duas pontas; não estende mais

	var ponta := _par_da_ponta(c)
	if ponta >= 0 and ponta != _arrastando:
		return          # ponta dos outros é intransponível
	if ponta == _arrastando and c == trilha[0]:
		return          # a própria ponta de partida

	if _dono.has(c):
		if _dono[c] == _arrastando:
			return      # laço em cima de si mesma
		_cortar_em(_dono[c], c)   # passa por cima: a trilha alheia cede

	trilha.append(c)
	_dono[c] = _arrastando

	if ponta == _arrastando:
		Audio.tocar("tecla")
		_arrastando = -1

	queue_redraw()
	mudou.emit()
	_checar()


func _checar() -> void:
	for par in _pontas.size():
		if not _fechada(par):
			return
	if _dono.size() < colunas * linhas:
		return
	_pronto = true
	_arrastando = -1
	queue_redraw()
	resolvido.emit()


# --------------------------------------------------------- geometria

func _lado() -> float:
	return minf(size.x / float(colunas), size.y / float(linhas))


func _origem() -> Vector2:
	var l := _lado()
	return Vector2((size.x - l * colunas) / 2.0, (size.y - l * linhas) / 2.0)


func _centro(c: Vector2i) -> Vector2:
	var l := _lado()
	return _origem() + Vector2((c.x + 0.5) * l, (c.y + 0.5) * l)


func _celula_em(p: Vector2) -> Vector2i:
	var l := _lado()
	var local := p - _origem()
	var c := Vector2i(int(floor(local.x / l)), int(floor(local.y / l)))
	if c.x < 0 or c.y < 0 or c.x >= colunas or c.y >= linhas:
		return Vector2i(-1, -1)
	return c


# ----------------------------------------------------------- desenho

func _draw() -> void:
	var l := _lado()
	var o := _origem()
	var caixa := Rect2(o, Vector2(l * colunas, l * linhas))

	draw_rect(caixa, FUNDO)
	for i in colunas + 1:
		draw_line(o + Vector2(i * l, 0), o + Vector2(i * l, l * linhas), GRADE, 1.0)
	for j in linhas + 1:
		draw_line(o + Vector2(0, j * l), o + Vector2(l * colunas, j * l), GRADE, 1.0)
	draw_rect(caixa, MOLDURA, false, 2.0)

	for par in _pontas.size():
		_desenhar_trilha(par, l)
	for par in _pontas.size():
		for ponta in _pontas[par]:
			_marcador(_centro(ponta), par, l * 0.26)


# Quatro traços diferentes, porque não existe cor aqui: cheio,
# tracejado, pontilhado e vazado (grosso com o miolo aberto).
func _desenhar_trilha(par: int, l: float) -> void:
	var trilha: Array = _trilhas[par]
	if trilha.size() < 2:
		return

	var pontos := PackedVector2Array()
	for c in trilha:
		pontos.append(_centro(c))

	match par % 4:
		0:
			draw_polyline(pontos, TINTA, l * 0.16, true)
		1:
			for seg in _tracos(pontos, l * 0.17):
				draw_polyline(seg, TINTA, l * 0.16, true)
		2:
			for p in _amostrar(pontos, l * 0.26):
				draw_circle(p, l * 0.075, TINTA)
		_:
			draw_polyline(pontos, TINTA, l * 0.18, true)
			draw_polyline(pontos, FUNDO, l * 0.08, true)


# Pontos espaçados ao longo da polilinha, acompanhando as curvas.
func _amostrar(pontos: PackedVector2Array, passo: float) -> Array:
	var saida := []
	var resto := 0.0
	for i in pontos.size() - 1:
		var a := pontos[i]
		var b := pontos[i + 1]
		var d := a.distance_to(b)
		var dir := (b - a) / maxf(d, 0.001)
		var s := resto
		while s < d:
			saida.append(a + dir * s)
			s += passo
		resto = s - d
	saida.append(pontos[pontos.size() - 1])
	return saida


# Pares de pontos consecutivos viram traço; os ímpares viram vão.
func _tracos(pontos: PackedVector2Array, passo: float) -> Array:
	var amostras := _amostrar(pontos, passo)
	var saida := []
	var i := 0
	while i + 1 < amostras.size():
		saida.append(PackedVector2Array([amostras[i], amostras[i + 1]]))
		i += 2
	return saida


func _marcador(centro: Vector2, par: int, r: float) -> void:
	draw_circle(centro, r * 1.25, FUNDO)
	match par % 4:
		0:
			draw_circle(centro, r, TINTA)
		1:
			draw_rect(Rect2(centro - Vector2(r, r) * 0.88, Vector2(r, r) * 1.76), TINTA)
		2:
			draw_colored_polygon(PackedVector2Array([
				centro + Vector2(0, -r), centro + Vector2(r * 0.92, r * 0.72),
				centro + Vector2(-r * 0.92, r * 0.72)]), TINTA)
		_:
			draw_colored_polygon(PackedVector2Array([
				centro + Vector2(0, -r * 1.12), centro + Vector2(r * 1.12, 0),
				centro + Vector2(0, r * 1.12), centro + Vector2(-r * 1.12, 0)]), TINTA)
