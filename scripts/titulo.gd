class_name Titulo
extends CanvasLayer

# Tela de título (cenas/ui/titulo.tscn). Some na primeira tecla.

signal comecou


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		visible = false
		Audio.tocar("porta_abrir")
		comecou.emit()
		get_viewport().set_input_as_handled()
