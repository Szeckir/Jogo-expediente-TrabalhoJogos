class_name Mapa
extends CanvasLayer

# Janela do mapa (cenas/ui/mapa.tscn). Abre no meio da tela com a tecla
# M e fecha com M de novo ou ESC. Enquanto está aberta o jogador fica
# parado. O desenho em si é o Minimapa, que mora dentro desta cena.

const Dados = preload("res://dados/setores.gd")

@onready var _minimapa: Minimapa = %Minimapa
@onready var _subtitulo: Label = %Subtitulo
@onready var _centro: Control = %Centro


func _ready() -> void:
	Estado.mapa_mudou.connect(_atualizar_texto)
	_atualizar_texto()


func definir_setor(numero: int) -> void:
	_minimapa.definir_setor(numero)


func alternar() -> void:
	if visible:
		fechar()
	else:
		abrir()


func abrir() -> void:
	if visible:
		return
	_atualizar_texto()
	_minimapa.queue_redraw()
	visible = true
	Audio.tocar("overlay_abrir")
	# aparece em um fade curto
	_centro.modulate.a = 0.0
	create_tween().tween_property(_centro, "modulate:a", 1.0, 0.12)


func fechar() -> void:
	if not visible:
		return
	visible = false
	Audio.tocar("overlay_fechar")


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_M or event.keycode == KEY_ESCAPE):
		fechar()
		get_viewport().set_input_as_handled()


func _atualizar_texto() -> void:
	_subtitulo.text = "%d de %d setores explorados  ·  %d móveis examinados" % [
		Estado.visitados.size(), Dados.numeros().size(), Estado.examinados.size()]
