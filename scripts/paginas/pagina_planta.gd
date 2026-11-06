extends Pagina

# Planta de evacuação do setor 01: revela onde fica a saída.


func ao_abrir(_movel: Movel) -> void:
	Estado.anotar("O elevador de serviço do setor 01 é a saída, e o leitor dele só aceita o crachá de saída.")
	Estado.mapa_mudou.emit()
