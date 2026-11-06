extends Pagina

# Elevador de serviço do setor 01: a saída. Só abre com o crachá de saída.

@onready var _aprovado: Control = %Aprovado
@onready var _negado: Control = %Negado


func ao_abrir(_movel: Movel) -> void:
	var tem := Estado.tem_cracha
	_aprovado.visible = tem
	_negado.visible = not tem

	if tem:
		Audio.tocar("cracha_aprovado")
		Audio.tocar("elevador")
		Estado.cumprir_marco(5)
		Estado.venceu = true
	else:
		Audio.tocar("cracha_negado")
		Estado.anotar("O elevador de serviço do setor 01 é a saída, e o leitor dele só aceita o crachá de saída.")
		Estado.mapa_mudou.emit()
