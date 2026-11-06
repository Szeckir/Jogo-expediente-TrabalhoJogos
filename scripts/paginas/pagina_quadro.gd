extends Pagina

# Quadro de avisos do setor 01: a tabela de letra para dígito da partida.

@onready var _grade: GridContainer = %Grade


func ao_abrir(_movel: Movel) -> void:
	# a grade tem uma linha de letras e, logo abaixo, uma de dígitos
	var n := Estado.LETRAS.size()
	for i in n:
		var letra: String = Estado.LETRAS[i]
		_grade.get_child(i).text = letra
		_grade.get_child(n + i).text = str(Estado.cifra[letra])

	Estado.anotar("O quadro de avisos do setor 01 tem uma tabela de letra para dígito.")
	Estado.cumprir_marco(2)
	_checar_cruzamento()
