class_name Jogador
extends Node2D

# O jogador fica sempre parado no centro da tela. Quem se move é o
# cenário. Isso é o que faz o corredor circular não ter emenda visível:
# não existe câmera para pular quando a volta fecha.
#
# O desenho é um AnimatedSprite2D (nó Sprite) com três animações que
# ficam em cenas/jogador/jogador_frames.tres:
#   parado     4 quadros, respiração
#   andar      8 quadros, ciclo de passo
#   interagir  3 quadros, braço estendido (toca uma vez)
# Os quadros são os PNGs de arte/jogador/. Para trocar o boneco, basta
# sobrescrever os PNGs com o mesmo nome (ou abrir o .tres e trocar).

var andando := false     # o Jogo liga e desliga
var virado := 1          # 1 direita, -1 esquerda

var _interagindo := false

@onready var _sprite: AnimatedSprite2D = %Sprite


func _ready() -> void:
	_sprite.animation_finished.connect(_ao_terminar_animacao)


func _process(_delta: float) -> void:
	_sprite.flip_h = virado < 0
	if _interagindo:
		return
	var quer := "andar" if andando else "parado"
	if _sprite.animation != quer:
		_sprite.play(quer)


# Chamado ao apertar E: o braço vai para a frente e volta.
func estender_braco() -> void:
	_interagindo = true
	_sprite.play("interagir")


func _ao_terminar_animacao() -> void:
	if _sprite.animation != "interagir":
		return
	# segura o braço esticado um instante antes de voltar
	await get_tree().create_timer(0.25).timeout
	_interagindo = false
