extends Pagina

# Cofre do arquivo morto (setor 06): fechadura numérica de três dígitos.
# Estados na cena: Aberto (já pegou o crachá), Fechadura (o teclado) e
# Sucesso (acabou de abrir).

var _digitado := ""

@onready var _aberto: Control = %Aberto
@onready var _fechadura: Control = %Fechadura
@onready var _sucesso: Control = %Sucesso
@onready var _visor: Label = %Visor
@onready var _teclado: GridContainer = %Teclado


func _ready() -> void:
	for botao in _teclado.get_children():
		botao.pressed.connect(_tecla.bind(botao.text))


func ao_abrir(_movel: Movel) -> void:
	if Estado.tem_cracha:
		_mostrar(_aberto)
		return
	_digitado = ""
	_atualizar_visor()
	_mostrar(_fechadura)


func _mostrar(estado: Control) -> void:
	_aberto.visible = (estado == _aberto)
	_fechadura.visible = (estado == _fechadura)
	_sucesso.visible = (estado == _sucesso)


func _tecla(t: String) -> void:
	if t == "C":
		Audio.tocar("tecla")
		_digitado = ""
	elif t == "OK":
		if _digitado == Estado.senha:
			Estado.tem_cracha = true
			Estado.bolso_mudou.emit()
			Estado.cumprir_marco(4)
			Audio.tocar("cracha_aprovado")
			Estado.riscar("O elevador de serviço do setor 01 é a saída, e o leitor dele só aceita o crachá de saída.")
			_mostrar(_sucesso)
			return
		else:
			Audio.tocar("recusado")
			Estado.aviso.emit("O cofre recusa.")
			_digitado = ""
	elif _digitado.length() < 3:
		Audio.tocar("tecla")
		_digitado += t

	_atualizar_visor()


func _atualizar_visor() -> void:
	var mostra := ""
	for i in 3:
		mostra += (_digitado[i] if i < _digitado.length() else "_") + " "
	_visor.text = mostra.strip_edges()
