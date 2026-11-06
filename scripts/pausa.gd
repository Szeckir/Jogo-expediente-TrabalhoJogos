class_name Pausa
extends CanvasLayer

# Pausa com controle de volume (cenas/ui/pausa.tscn). Os botões e o
# slider estão ligados a estas funções pela aba Nó > Sinais da cena.

signal reiniciar_pedido

@onready var _slider: HSlider = %Volume


func abrir() -> void:
	_slider.value = Audio.volume
	visible = true
	get_tree().paused = true


func fechar() -> void:
	visible = false
	get_tree().paused = false


func _ao_mudar_volume(valor: float) -> void:
	Audio.volume = valor


func _ao_recomecar() -> void:
	fechar()
	reiniciar_pedido.emit()
