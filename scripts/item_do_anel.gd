class_name ItemDoAnel
extends Node2D

# Tudo o que mora no corredor circular herda daqui: móveis, luminárias...
#
# A posição X que você dá ao nó no editor é o ponto dele NO ANEL, de 0
# até o perímetro do setor. Em jogo o setor empurra o nó pela tela (o
# jogador nunca anda), então o X original fica guardado em x_anel.

var x_anel := 0.0


func _ready() -> void:
	x_anel = position.x
