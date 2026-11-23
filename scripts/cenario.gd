class_name Cenario
extends Node2D

# Parede e chão. São duas imagens em tile (arte/cenario/parede.png e
# chao.png), cada uma com 100 px de largura repetidos pela tela toda.
# O jogador nunca anda: quem desliza é o cenário, e como o tile tem
# exatamente o PERIODO, a emenda nunca aparece.
#
# PERIODO precisa dividir o perímetro de todos os setores (hoje 1900,
# 2100, 2200, 2400 e 3000, então o maior valor possível é 100). Se
# criar um setor com perímetro que não seja múltiplo de 100, o fundo
# dá um pulinho quando a volta fecha.

const PERIODO := 100.0

@onready var _x0: float = position.x
@onready var _parede: Sprite2D = $Parede
@onready var _chao: Sprite2D = $Chao


# Tinta do setor (Setor.tom). Parede e chão são tiles de uma cor só, então
# multiplicar pela tinta é o jeito barato de dar clima a cada setor.
func definir_tom(tom: Color) -> void:
	_parede.modulate = tom
	_chao.modulate = tom


func atualizar(posicao_no_anel: float) -> void:
	position.x = _x0 - fposmod(posicao_no_anel, PERIODO)
