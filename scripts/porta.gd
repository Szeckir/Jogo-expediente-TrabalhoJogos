class_name Porta
extends Movel

# Porta entre setores. Em vez de abrir uma tela, ela leva o jogador
# para o setor "destino" (ou mostra pagina_trancada se faltar a chave).

## Número do setor para onde a porta leva.
@export var destino := 1
## Se ligado, só abre com a chave do arquivo (Estado.tem_chave).
@export var exige_chave := false
## Tela que abre quando a porta está trancada.
@export var pagina_trancada: PackedScene

@onready var _numero: Label = %Numero


func _ready() -> void:
	super._ready()
	_numero.text = "%02d" % destino
