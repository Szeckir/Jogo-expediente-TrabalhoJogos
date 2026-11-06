extends Pagina

# Tela de texto simples. Serve para qualquer documento: basta preencher
# o Titulo e o Texto (no editor, ou por código antes de abrir).

@export_multiline var texto := ""

@onready var _texto: Label = %Texto


func _ready() -> void:
	_texto.text = texto
