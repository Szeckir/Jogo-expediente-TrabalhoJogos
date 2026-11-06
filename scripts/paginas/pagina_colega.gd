extends Pagina

# Colega da copa (setor 04): troca a chave do arquivo morto por comida.

@onready var _fala: Label = %Fala
@onready var _gesto: Label = %Gesto


func ao_abrir(_movel: Movel) -> void:
	if Estado.tem_chave:
		_dizer("— Já te dei a chave. Some daqui antes que alguém veja.")
		return

	if Estado.tem_sanduiche:
		_dizer("— Você trouxe comida. Não pergunto de onde.",
			"Ela tira uma chave pequena do bolso do avental e empurra pela mesa.")
		Estado.tem_sanduiche = false
		Estado.tem_chave = true
		Estado.bolso_mudou.emit()
		Estado.mapa_mudou.emit()
		Audio.tocar("aceito")
		Estado.riscar("A colega da copa troca a chave do arquivo morto por comida.")
		Estado.anotar("A chave da colega abre a porta 06, no setor 03.")
	else:
		_dizer("— Não saio daqui desde as sete. Se aparecer alguma coisa de comer, a gente conversa.")
		Estado.anotar("A colega da copa troca a chave do arquivo morto por comida.")


func _dizer(fala: String, gesto := "") -> void:
	_fala.text = fala
	_gesto.text = gesto
	_gesto.visible = gesto != ""
