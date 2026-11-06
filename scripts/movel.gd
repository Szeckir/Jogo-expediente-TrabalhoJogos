class_name Movel
extends ItemDoAnel

# Base de todo móvel interativo. Cada tipo (porta, quadro, cofre...) é
# uma cena em cenas/movel/ que herda de movel.tscn. O desenho é o nó
# Imagem (um Sprite2D) com o PNG de arte/movel/<tipo>.png. Para trocar
# a imagem, sobrescreva o PNG com o mesmo nome. O pé do desenho fica na
# origem do nó; coisa pendurada na parede só tem a imagem mais alta.

# Cores da etiqueta. Escuras, porque o chão é claro.
const APAGADO := Color(0.17, 0.22, 0.20)
const VERDE := Color(0.04, 0.34, 0.25)

## Texto que aparece embaixo do móvel e no prompt "E · ...".
@export var rotulo := "Móvel"
## Tela que abre quando o jogador aperta E (uma cena de cenas/paginas/).
@export var pagina: PackedScene

@onready var _etiqueta: Label = %Etiqueta


func _ready() -> void:
	super._ready()
	marcar_examinado(false)


# Móvel já examinado ganha um tique na etiqueta. É o terceiro medidor
# de progresso do pitch, junto com o mapa e o caderno.
func marcar_examinado(examinado: bool) -> void:
	if examinado:
		_etiqueta.text = "✓ " + rotulo
		_etiqueta.add_theme_color_override("font_color", VERDE)
	else:
		_etiqueta.text = rotulo
		_etiqueta.add_theme_color_override("font_color", APAGADO)
