@tool
class_name Setor
extends Node2D

# Um setor do escritório. Cada setor é uma cena em cenas/setores/.
#
# Para montar um setor no editor:
#   - arraste móveis (cenas/movel/*.tscn) para dentro dele;
#   - a posição X de cada móvel é o ponto dele no anel, de 0 até o
#     perímetro; deixe Y em 0 (é o chão);
#   - a linha verde que aparece no editor mostra o anel inteiro, e a
#     vermelha é onde ele fecha (e volta para o 0).
#
# As luminárias do teto são criadas sozinhas ao longo do anel.

const LUMINARIA := preload("res://cenas/setores/luminaria.tscn")

## Número do setor (1 a 6). Tem que bater com o das portas que levam até ele.
@export var numero := 1
## Nome que aparece no cabeçalho do jogo.
@export var nome := ""
## Comprimento do anel em pixels. O jogador anda em x, e quando passa
## do perímetro a posição volta a zero.
@export var perimetro := 1500.0:
	set(valor):
		perimetro = valor
		queue_redraw()
## Onde o cartão deste setor fica no mapa (tecla M), em colunas e linhas:
## (0, 0) é o canto de cima à esquerda, (1, 0) é o cartão ao lado e
## (0, 1) é o de baixo.
@export var posicao_mapa := Vector2.ZERO
## Distância entre luminárias no teto. 0 desliga.
@export var espaco_luminarias := 320.0

## Tudo que mora no anel (móveis e luminárias).
var itens: Array[ItemDoAnel] = []
## Só os móveis.
var moveis: Array[Movel] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_criar_luminarias()
	for filho in get_children():
		if filho is ItemDoAnel:
			itens.append(filho)
		if filho is Movel:
			moveis.append(filho)


func _criar_luminarias() -> void:
	if espaco_luminarias <= 0.0:
		return
	var quantas := int(perimetro / espaco_luminarias)
	for i in quantas:
		var luz: ItemDoAnel = LUMINARIA.instantiate()
		luz.position.x = i * espaco_luminarias
		add_child(luz)
		move_child(luz, i)   # ficam atrás dos móveis


# Distância entre dois pontos do anel, sempre pelo caminho mais curto.
# É daqui que sai a ilusão: nada nunca está "do outro lado".
func delta_anel(de: float, para: float) -> float:
	return fposmod(para - de + perimetro / 2.0, perimetro) - perimetro / 2.0


# Empurra cada item para o lugar certo da tela, dado onde o jogador está.
func posicionar(posicao_jogador: float, centro_x: float, chao_y: float) -> void:
	for item in itens:
		var dx := delta_anel(posicao_jogador, item.x_anel)
		if absf(dx) > 700.0:
			item.visible = false
		else:
			item.visible = true
			item.position = Vector2(centro_x + dx, chao_y)


# O móvel mais perto do jogador dentro do raio, ou null.
func movel_mais_proximo(posicao_jogador: float, raio: float) -> Movel:
	var melhor: Movel = null
	var menor := raio
	for m in moveis:
		var d := absf(delta_anel(posicao_jogador, m.x_anel))
		if d < menor:
			menor = d
			melhor = m
	return melhor


# Só no editor: régua do anel, para saber até onde dá para colocar móvel.
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var verde := Color(0.12, 0.31, 0.27, 0.85)
	var vermelho := Color(0.80, 0.20, 0.20, 0.90)
	var fonte := ThemeDB.fallback_font
	draw_line(Vector2(0, 0), Vector2(perimetro, 0), verde, 2.0)
	draw_line(Vector2(0, -200), Vector2(0, 40), verde, 2.0)
	draw_line(Vector2(perimetro, -200), Vector2(perimetro, 40), vermelho, 2.0)
	draw_string(fonte, Vector2(6, 64), "início do anel (x = 0)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, verde)
	draw_string(fonte, Vector2(perimetro - 300, 64),
		"fim do anel (x = %d) · volta ao 0" % int(perimetro),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, vermelho)
