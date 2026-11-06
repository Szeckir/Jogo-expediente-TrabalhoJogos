extends Pagina

# Máquina de salgados do setor 05: sanduíche por 2 fichas (serve) e
# café por 1 (a armadilha proposital: não serve para nada).

@onready var _fichas: Label = %Fichas
@onready var _aviso: Label = %Aviso


func _ready() -> void:
	%Sanduiche.pressed.connect(_comprar_sanduiche)
	%Cafe.pressed.connect(_comprar_cafe)


func ao_abrir(_movel: Movel) -> void:
	_atualizar()


func _atualizar() -> void:
	_fichas.text = "Fichas no bolso: " + str(Estado.fichas)
	_aviso.visible = Estado.tem_sanduiche


func _comprar_sanduiche() -> void:
	if Estado.tem_sanduiche:
		Estado.aviso.emit("Você já tem um sanduíche.")
		return
	if not Estado.gastar_fichas(2):
		Audio.tocar("recusado")
		Estado.aviso.emit("Fichas insuficientes.")
		return
	Estado.tem_sanduiche = true
	Estado.bolso_mudou.emit()
	Audio.tocar("aceito")
	Estado.aviso.emit("Sanduíche no bolso.")
	_atualizar()


func _comprar_cafe() -> void:
	if not Estado.gastar_fichas(1):
		Audio.tocar("recusado")
		Estado.aviso.emit("Fichas insuficientes.")
		return
	# a armadilha proposital: o café não serve para nada
	Audio.tocar("aceito")
	Estado.aviso.emit("O copo sai quente. E é só isso.")
	_atualizar()
