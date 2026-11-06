extends RefCounted

# Catálogo dos setores.
#
# Os DADOS de cada setor (nome, perímetro, posição no minimapa, móveis,
# para onde cada porta leva) moram nas próprias cenas em
# cenas/setores/setor_NN.tscn. Aqui só fica a lista de quais cenas
# existem e uma leitura rápida delas, usada pelo minimapa e pela
# travessia de portas sem precisar montar o setor na tela.
#
# Setor novo: crie cenas/setores/setor_07.tscn e acrescente em CENAS.

const CENAS := {
	1: preload("res://cenas/setores/setor_01.tscn"),
	2: preload("res://cenas/setores/setor_02.tscn"),
	3: preload("res://cenas/setores/setor_03.tscn"),
	4: preload("res://cenas/setores/setor_04.tscn"),
	5: preload("res://cenas/setores/setor_05.tscn"),
	6: preload("res://cenas/setores/setor_06.tscn"),
}

static var _cache := {}


static func numeros() -> Array:
	return CENAS.keys()


# { "nome", "perimetro", "mapa", "total_moveis", "portas": [{ "x", "destino", "exige_chave" }] }
static func info(numero: int) -> Dictionary:
	if _cache.has(numero):
		return _cache[numero]

	var setor: Setor = CENAS[numero].instantiate()
	var portas: Array = []
	var total := 0
	for filho in setor.get_children():
		if filho is Movel:
			total += 1
		if filho is Porta:
			portas.append({
				"x": filho.position.x,
				"destino": filho.destino,
				"exige_chave": filho.exige_chave,
			})

	var dados := {
		"nome": setor.nome,
		"perimetro": setor.perimetro,
		"mapa": setor.posicao_mapa,
		"total_moveis": total,
		"portas": portas,
	}
	setor.free()
	_cache[numero] = dados
	return dados


# Quantos móveis com enigma cada setor tem. Usado pelo minimapa.
static func moveis_do_setor(numero: int) -> int:
	return info(numero)["total_moveis"]


# Vizinhos de um setor, lidos das portas.
static func vizinhos(numero: int) -> Array:
	var lista: Array = []
	for p in info(numero)["portas"]:
		lista.append(p["destino"])
	return lista
