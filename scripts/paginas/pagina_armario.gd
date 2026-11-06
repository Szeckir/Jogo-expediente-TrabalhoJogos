extends Pagina

# Armário 14 do setor 03: o bilhete de três letras da partida.

@onready var _bilhete: Label = %Bilhete


func ao_abrir(_movel: Movel) -> void:
	_bilhete.text = Estado.bilhete
	Estado.anotar("O armário 14 do setor 03 guarda um bilhete com três letras: " + Estado.bilhete + ".")
	Estado.cumprir_marco(2)
	_checar_cruzamento()
