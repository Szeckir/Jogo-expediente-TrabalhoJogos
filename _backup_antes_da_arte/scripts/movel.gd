class_name Movel
extends ItemDoAnel

# Base de todo móvel interativo. Cada tipo (porta, quadro, cofre...) é
# uma cena em cenas/movel/ que herda de movel.tscn. Para trocar o
# retângulo por um sprite, abra a cena do tipo e troque o nó Caixa.

const APAGADO := Color(0.55, 0.55, 0.55)
const VERDE := Color(0.12, 0.31, 0.27)

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
