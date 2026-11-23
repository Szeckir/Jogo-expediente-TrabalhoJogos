class_name Luminaria
extends ItemDoAnel

# Luminária do teto (cenas/setores/luminaria.tscn). O Setor cria uma a
# cada `espaco_luminarias` e escolhe o estilo conforme o ambiente:
#
#   FIXA        acesa e parada (o normal)
#   PISCANDO    tremida de lâmpada fluorescente velha
#   BALANCANDO  pendulando no fio
#   TORTA       torta e quase apagada, pendurada por um fio só
#   APAGADA     queimada

enum Estilo { FIXA, PISCANDO, BALANCANDO, TORTA, APAGADA }

# Onde o sprite fica quando a lâmpada está parada, e onde o fio prende no
# teto (ponto em torno do qual ela balança).
const BASE := Vector2(-100.0, -452.0)
const PIVO := Vector2(-50.0, -450.0)

var estilo: Estilo = Estilo.FIXA
var fase := 0.0

var _t := 0.0

@onready var _luz: Sprite2D = $Luz


func _ready() -> void:
	super._ready()
	_t = fase
	match estilo:
		Estilo.TORTA:
			_girar(0.5)
			_luz.modulate = Color(0.75, 0.75, 0.75, 0.35)
		Estilo.APAGADA:
			_luz.modulate = Color(0.60, 0.60, 0.60, 0.50)


func _process(delta: float) -> void:
	if not visible or estilo == Estilo.FIXA or estilo == Estilo.TORTA \
			or estilo == Estilo.APAGADA:
		return
	_t += delta
	match estilo:
		Estilo.PISCANDO:
			var a := 0.88 + 0.12 * sin(_t * 2.3)
			if sin(_t * 9.1) * sin(_t * 3.7 + 1.3) > 0.82:
				a = 0.30
			_luz.modulate.a = a
		Estilo.BALANCANDO:
			_girar(0.2 * sin(_t * 1.6))
			_luz.modulate.a = 0.92 + 0.08 * sin(_t * 11.0)


# Gira a lâmpada em torno do ponto onde o fio prende no teto.
func _girar(angulo: float) -> void:
	_luz.rotation = angulo
	_luz.position = PIVO + (BASE - PIVO).rotated(angulo)
