class_name Forma
extends Control

# Um símbolo do terminal (cenas/ui/forma.tscn). Não existe PNG: tudo sai
# de draw_*, no mesmo traço flat do resto do jogo, e **sem cor nenhuma** —
# só tinta sobre papel. Quem decide o que aparece é um dicionário:
#
#   glifo      "poligono" (padrão) ou "efe" (figura sem simetria)
#   lados      3 a 8 lados do polígono
#   giro       rotação em quartos de volta (0, 1, 2, 3)
#   espelhado  reflete no eixo vertical; vira a figura "canhota"
#   marcas     quantos pontos ficam dentro da figura
#   textura    "vazado", "cheio" ou "hachura"
#   irregular  afunda um vértice e quebra a simetria
#   afundar    o quanto esse vértice afunda (0.40 grita, 0.68 sussurra)
#
# Duas formas são iguais quando os dicionários são iguais. É assim que a
# rodada do modelo sabe qual das opções é a cópia certa.
#
# Combinações que a página do terminal evita de propósito, porque não
# dariam para ler: marcas dentro de figura "cheio" (somem na tinta) e
# "cheio" num glifo "efe" (o polígono é côncavo).

const TINTA := Color(0.10, 0.10, 0.10)
const TRACO := 2.6
const PONTO := 3.0

# Glifo "efe": a figura sem nenhum eixo de simetria. O F é o estímulo
# clássico de rotação mental porque giro nenhum dele coincide com o
# reflexo dele — é isso que torna a rodada de espelhamento justa.
# Nunca use textura "cheio" aqui: o polígono é côncavo.
const EFE: Array[Vector2] = [
	Vector2(-0.42, -0.95), Vector2(0.58, -0.95), Vector2(0.58, -0.60),
	Vector2(-0.10, -0.60), Vector2(-0.10, -0.20), Vector2(0.40, -0.20),
	Vector2(0.40, 0.14), Vector2(-0.10, 0.14), Vector2(-0.10, 0.95),
	Vector2(-0.42, 0.95),
]

var spec := {}


func definir(novo: Dictionary) -> void:
	spec = novo
	queue_redraw()


func limpar() -> void:
	spec = {}
	queue_redraw()


func _draw() -> void:
	if spec.is_empty():
		return

	var poligono := _vertices()
	var textura: String = spec.get("textura", "vazado")

	if textura == "cheio":
		draw_colored_polygon(poligono, TINTA)
		return

	if textura == "hachura":
		_hachura(poligono)

	var contorno := poligono.duplicate()
	contorno.append(poligono[0])
	draw_polyline(contorno, TINTA, TRACO, true)
	_marcas(int(spec.get("marcas", 0)))


func _raio() -> float:
	return minf(size.x, size.y) * 0.32


# Os vértices já saem girados, espelhados e centrados no controle.
func _vertices() -> PackedVector2Array:
	var centro := size / 2.0
	var r := _raio()
	var crus: Array[Vector2] = []

	if spec.get("glifo", "poligono") == "efe":
		for p in EFE:
			crus.append(p * r)
	else:
		var n: int = clampi(int(spec.get("lados", 4)), 3, 8)
		for i in n:
			var a := -PI / 2.0 + TAU * i / n
			# o vértice 1 afunda quando a figura é irregular, e o entalhe
			# que isso abre é bem mais visível do que um vértice esticado
			var raio := r * float(spec.get("afundar", 0.40)) \
					if (spec.get("irregular", false) and i == 1) else r
			crus.append(Vector2(cos(a), sin(a)) * raio)

	var giro := TAU / 4.0 * float(spec.get("giro", 0))
	var espelhado: bool = spec.get("espelhado", false)
	var saida := PackedVector2Array()
	for p in crus:
		var q := Vector2(-p.x, p.y) if espelhado else p
		saida.append(q.rotated(giro) + centro)
	return saida


# Risquinhos a 45 graus, cortados na borda da figura. É o "preenchido"
# que não usa cor.
func _hachura(poligono: PackedVector2Array) -> void:
	var r := _raio()
	var centro := size / 2.0
	var alcance := r * 2.2
	var d := -alcance
	while d <= alcance:
		var base := centro + Vector2(d, 0.0)
		var linha := PackedVector2Array([
			base + Vector2(-alcance, -alcance), base + Vector2(alcance, alcance)])
		for pedaco in Geometry2D.intersect_polyline_with_polygon(linha, poligono):
			if pedaco.size() >= 2:
				draw_polyline(pedaco, TINTA, 1.5, true)
		d += 8.0


# Pontos dentro da figura, em anel. O anel abre conforme a contagem
# cresce, mas nunca encosta na borda: o teto é o raio inscrito do
# polígono, que é o que garante que 6 pontos cabem num hexágono e 3
# pontos ainda cabem num triângulo.
func _marcas(quantidade: int) -> void:
	if quantidade <= 0:
		return
	var centro := size / 2.0
	if quantidade == 1:
		draw_circle(centro, PONTO, TINTA)
		return

	var r := _raio()
	var lados := clampi(int(spec.get("lados", 4)), 3, 8)
	var inscrito := r * cos(PI / lados)
	var anel := minf(r * (0.30 + 0.03 * quantidade), inscrito * 0.62)

	for i in quantidade:
		var a := -PI / 2.0 + TAU * i / quantidade
		draw_circle(centro + Vector2(cos(a), sin(a)) * anel, PONTO, TINTA)
