class_name Overlay
extends CanvasLayer

# Janela que abre por cima do jogo (cenas/ui/overlay.tscn). Ela é só a
# moldura: o conteúdo de cada enigma é uma cena em cenas/paginas/, e o
# móvel diz qual (campo Pagina na cena dele). Para criar um enigma novo:
# faça uma página nova, e aponte o Pagina de um móvel para ela.

signal fechou

const PAGINA_DOCUMENTO := preload("res://cenas/paginas/pagina_documento.tscn")

@onready var _titulo: Label = %Titulo
@onready var _conteudo: VBoxContainer = %Conteudo


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		fechar()
		get_viewport().set_input_as_handled()


func fechar() -> void:
	visible = false
	Audio.tocar("overlay_fechar")
	fechou.emit()


# Abre a página do móvel. Se a página não tiver título próprio, usa o
# rótulo do móvel.
func abrir(cena: PackedScene, movel: Movel = null) -> Pagina:
	return _mostrar(cena.instantiate(), movel)


# Tela de texto simples, com título e corpo escolhidos na hora (usada no
# fim do jogo).
func abrir_documento(titulo: String, corpo: String) -> Pagina:
	var pagina: Pagina = PAGINA_DOCUMENTO.instantiate()
	pagina.titulo = titulo
	pagina.texto = corpo
	return _mostrar(pagina, null)


func _mostrar(pagina: Pagina, movel: Movel) -> Pagina:
	for filho in _conteudo.get_children():
		_conteudo.remove_child(filho)
		filho.queue_free()

	if pagina.titulo != "":
		_titulo.text = pagina.titulo
	elif movel != null:
		_titulo.text = movel.rotulo
	else:
		_titulo.text = ""

	if not visible:
		Audio.tocar("overlay_abrir")
	visible = true

	_conteudo.add_child(pagina)
	pagina.ao_abrir(movel)
	return pagina
