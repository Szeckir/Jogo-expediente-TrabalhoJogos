class_name Transicao
extends CanvasLayer

# Fade preto ao atravessar uma porta (cenas/ui/transicao.tscn).
# Dura `duracao` segundos no total: metade escurecendo, a troca de setor
# com a tela toda preta, e metade clareando. Para mudar o tempo, é só
# editar "Duracao" no Inspetor desta cena.

@export var duracao := 0.5

# verdadeiro enquanto o fade roda; o Jogo trava teclas e movimento
var ativa := false

@onready var _preto: ColorRect = %Preto


# Escurece, chama `no_escuro` (aqui o Jogo troca o setor) e clareia.
func executar(no_escuro: Callable) -> void:
	if ativa:
		return
	ativa = true
	visible = true
	_preto.modulate.a = 0.0

	var meia := duracao * 0.5
	var t := create_tween()
	t.tween_property(_preto, "modulate:a", 1.0, meia)
	await t.finished

	no_escuro.call()

	t = create_tween()
	t.tween_property(_preto, "modulate:a", 0.0, meia)
	await t.finished

	visible = false
	ativa = false
