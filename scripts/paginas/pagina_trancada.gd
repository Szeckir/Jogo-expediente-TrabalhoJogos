extends Pagina

# Porta trancada por chave (a do setor 03 para o arquivo morto).


func ao_abrir(_movel: Movel) -> void:
	Audio.tocar("porta_travada")
	Estado.anotar("A porta 06, no setor 03, está trancada por chave.")
