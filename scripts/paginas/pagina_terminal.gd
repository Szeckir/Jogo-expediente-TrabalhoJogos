extends Pagina

# Terminal do setor 02: três rodadas de "ache o que não pertence".
#
# As rodadas são de FORMA, não de conta. O enunciado nunca diz qual é a
# regra — descobrir a regra É o enigma, e é isso que a dica da tela
# sempre prometeu ("o terminal não explica a regra").
#
# A garantia de que existe uma única resposta defensável: numa rodada,
# as quatro opções são idênticas em todos os atributos menos no único
# que define o intruso. Nada de cor em lugar nenhum; o que separa as
# figuras é lado, giro, reflexo, contagem e textura.
#
# Sete famílias de forma, em degraus (ver DEGRAUS), e a partir do degrau
# 3 elas apertam: lados com diferença de um só, mais pontos para contar,
# entalhe mais raso, distratores mais parecidos com o modelo.
#
# A última rodada não é de forma: é a GRADE DE FLUXO (scripts/fluxo.gd),
# ligar os pares sem cruzar e sem deixar célula vazia. Ela é a única que
# não tem resposta errada — dá para limpar e tentar de novo à vontade,
# porque a cota é curta e o terminal é a única fonte de fichas do jogo.
#
# A página tem cinco estados (nós Cota, Intro, Rodada, Vitoria e Recusa
# na cena); só um fica visível por vez. Dentro de Rodada há dois blocos,
# Escolha (as quatro formas) e Grade (o fluxo).

const ACHE_O_INTRUSO := "UM DESTES NÃO PERTENCE AO CONJUNTO."
const ACHE_O_IGUAL := "ESCOLHA O SÍMBOLO IGUAL AO MODELO."
const LIGUE_TUDO := "LIGUE CADA PAR SEM CRUZAR E SEM DEIXAR CÉLULA VAZIA."

# Quais famílias podem cair em cada rodada. A partida sobe de degrau, e
# do degrau 3 em diante as famílias saem na versão difícil.
const DEGRAUS := [
	["lados", "marcas", "textura"],
	["textura", "irregular", "modelo"],
	["espelhado", "relacao", "irregular", "modelo"],
	["fluxo"],
]
const PRIMEIRO_DEGRAU_DIFICIL := 2

var _rodada := 0
var _certa := -1

@onready var _estados: Array[Control] = [%Cota, %Intro, %Rodada, %Vitoria, %Recusa]
@onready var _premio: Label = %Premio
@onready var _usadas: Label = %Usadas
@onready var _contador: Label = %Contador
@onready var _enunciado: Label = %Enunciado
@onready var _escolha: VBoxContainer = %Escolha
@onready var _opcoes: HBoxContainer = %Opcoes
@onready var _modelo: PanelContainer = %Modelo
@onready var _forma_modelo: Forma = %FormaModelo
@onready var _grade: VBoxContainer = %Grade
@onready var _fluxo: Fluxo = %Fluxo
@onready var _andamento: Label = %Andamento
@onready var _creditado: Label = %Creditado


func _ready() -> void:
	%Iniciar.pressed.connect(_iniciar_partida)
	%Voltar.pressed.connect(_mostrar_intro)
	for i in _opcoes.get_child_count():
		var botao: Button = _opcoes.get_child(i)
		botao.pressed.connect(_responder.bind(i))
	%Limpar.pressed.connect(_fluxo.limpar)
	_fluxo.resolvido.connect(_ao_resolver_fluxo)
	_fluxo.mudou.connect(func(): _andamento.text = _fluxo.progresso())


func ao_abrir(_movel: Movel) -> void:
	_mostrar_intro()


func _mostrar(estado: Control) -> void:
	for e in _estados:
		e.visible = (e == estado)


func _mostrar_intro() -> void:
	if Estado.partidas_terminal >= Estado.COTA_PARTIDAS:
		_mostrar(%Cota)
		return
	_premio.text = "%d rodadas seguidas, a última na grade. Prêmio: %d fichas." % [
		DEGRAUS.size(), Estado.PREMIO_PARTIDA]
	_usadas.text = "Partidas usadas: " + str(Estado.partidas_terminal) + " de " + str(Estado.COTA_PARTIDAS)
	_mostrar(%Intro)
	Estado.anotar("O terminal do setor 02 paga fichas por partida vencida.")


func _iniciar_partida() -> void:
	_rodada = 0
	_proxima_rodada()


func _proxima_rodada() -> void:
	if _rodada >= DEGRAUS.size():
		Estado.partidas_terminal += 1
		Estado.ganhar_fichas(Estado.PREMIO_PARTIDA)
		_creditado.text = "Creditado: " + str(Estado.PREMIO_PARTIDA) + " fichas."
		_mostrar(%Vitoria)
		Estado.riscar("O terminal do setor 02 paga fichas por partida vencida.")
		return

	_contador.text = "RODADA %d DE %d" % [_rodada + 1, DEGRAUS.size()]
	var familia: String = DEGRAUS[_rodada].pick_random()

	if familia == "fluxo":
		_enunciado.text = LIGUE_TUDO
		_certa = -1
		_escolha.visible = false
		_grade.visible = true
		_fluxo.gerar()
		_andamento.text = _fluxo.progresso()
		_mostrar(%Rodada)
		return

	_escolha.visible = true
	_grade.visible = false

	var rodada := _gerar_rodada(familia, _rodada >= PRIMEIRO_DEGRAU_DIFICIL)
	_enunciado.text = rodada["enunciado"]
	_certa = rodada["certa"]

	var modelo: Dictionary = rodada["modelo"]
	_modelo.visible = not modelo.is_empty()
	if _modelo.visible:
		_forma_modelo.definir(modelo)
	else:
		_forma_modelo.limpar()

	var opcoes: Array = rodada["opcoes"]
	for i in _opcoes.get_child_count():
		var forma: Forma = _opcoes.get_child(i).get_node("Forma")
		forma.definir(opcoes[i])

	_mostrar(%Rodada)


func _ao_resolver_fluxo() -> void:
	Audio.tocar("aceito")
	_rodada += 1
	_proxima_rodada()


# ------------------------------------------------------- as famílias
#
# Toda família devolve { "enunciado", "opcoes" (4), "certa", "modelo" }.
# "certa" é o índice do botão que resolve a rodada.

func _gerar_rodada(familia: String, dificil: bool) -> Dictionary:
	match familia:
		"lados": return _familia_lados(dificil)
		"marcas": return _familia_marcas(dificil)
		"textura": return _familia_textura()
		"irregular": return _familia_irregular(dificil)
		"modelo": return _familia_modelo(dificil)
		"espelhado": return _familia_espelhado()
		_: return _familia_relacao()


# Três polígonos de n lados, um de m. Só o número de lados muda.
# No difícil a diferença é de um lado só, que é quando contar vértice
# deixa de ser automático.
func _familia_lados(dificil: bool) -> Dictionary:
	var n: int = [3, 4, 5, 6].pick_random() if not dificil else [5, 6, 7].pick_random()
	var distancia := 1 if dificil else 2
	var candidatos := []
	for m in [3, 4, 5, 6, 7, 8]:
		if absi(m - n) >= distancia and (not dificil or absi(m - n) == 1):
			candidatos.append(m)
	var m: int = candidatos.pick_random()
	return _intruso(
		{"lados": n, "textura": "vazado"},
		{"lados": m, "textura": "vazado"})


# Mesma figura, contagem de pontos diferente. No difícil são mais pontos,
# e aí não dá mais para ver a quantidade de relance: tem que contar. Não
# passa de 6 porque contar 7 contra 8 amontoados é chato, não é difícil.
func _familia_marcas(dificil: bool) -> Dictionary:
	var n: int = [4, 6].pick_random()
	var k := randi_range(5, 6) if dificil else randi_range(2, 4)
	var outro: int = k + ([-1, 1].pick_random())
	outro = maxi(outro, 1)
	if outro == k:
		outro = k + 1
	return _intruso(
		{"lados": n, "marcas": k},
		{"lados": n, "marcas": outro})


# Mesma figura, acabamento diferente. Hachura e tinta cheia no lugar
# onde um jogo colorido usaria duas cores.
func _familia_textura() -> Dictionary:
	var n: int = [3, 4, 5, 6].pick_random()
	var par: Array = [["hachura", "vazado"], ["vazado", "cheio"], ["cheio", "hachura"]].pick_random()
	return _intruso(
		{"lados": n, "textura": par[0]},
		{"lados": n, "textura": par[1]})


# Três polígonos regulares, um com um vértice afundado. No difícil o
# entalhe é raso e a figura torta quase passa por regular.
func _familia_irregular(dificil: bool) -> Dictionary:
	var n: int = [4, 5, 6].pick_random() if not dificil else [6, 7, 8].pick_random()
	var giro: int = randi_range(0, 3)
	return _intruso(
		{"lados": n, "giro": giro},
		{"lados": n, "giro": giro, "irregular": true,
			"afundar": 0.72 if dificil else 0.40})


# "Três símbolos e pegar o semelhante": a resposta é a cópia exata do
# modelo; os outros três erram um atributo cada.
func _familia_modelo(dificil: bool) -> Dictionary:
	var modelo := {
		"lados": [3, 4, 5, 6].pick_random() if not dificil else [5, 6, 7].pick_random(),
		"marcas": randi_range(1, 3) if not dificil else randi_range(4, 6),
		"textura": "vazado",
	}

	# Cada distrator erra em EXATAMENTE um atributo: lados, contagem ou
	# giro. No difícil o erro de lados é de um só, em vez de qualquer um.
	#
	# O giro é meia volta de quarto (45°) de propósito: 90° num quadrado
	# devolveria o próprio quadrado, e aí haveria duas respostas certas.
	# Nenhum polígono de 3 a 7 lados é simétrico a 45°.
	var erros := [
		{"lados": int(modelo["lados"]) + [-1, 1].pick_random() if dificil
			else _outro_lado(int(modelo["lados"]))},
		{"marcas": maxi(int(modelo["marcas"]) + [-1, 1].pick_random(), 0)},
		{"giro": 0.5},
	]
	var distratores := []
	for erro in erros:
		var copia := modelo.duplicate()
		for chave in erro:
			copia[chave] = erro[chave]
		distratores.append(copia)

	var rodada := _embaralhar(distratores, modelo.duplicate())
	rodada["enunciado"] = ACHE_O_IGUAL
	rodada["modelo"] = modelo
	return rodada


# Três giros do mesmo glifo assimétrico, e um reflexo dele. Como o
# glifo não tem eixo de simetria, o reflexo não coincide com giro
# nenhum, então existe uma única resposta defensável.
func _familia_espelhado() -> Dictionary:
	var giros := [0, 1, 2, 3]
	giros.shuffle()
	var normais := []
	for i in 3:
		normais.append({"glifo": "efe", "giro": giros[i], "textura": "vazado"})
	# o reflexo repete o giro de um dos três, para que exista sempre um par
	# na mesma orientação. Sem esse par, o jogador não teria como descobrir
	# que o giro é irrelevante e a regra viraria adivinhação.
	var intruso := {
		"glifo": "efe", "giro": giros[randi_range(0, 2)],
		"espelhado": true, "textura": "vazado",
	}
	return _embaralhar(normais, intruso)


# A regra não está em nenhuma figura sozinha: em três delas o número de
# pontos é igual ao número de lados, e numa não é.
func _familia_relacao() -> Dictionary:
	var lados := [3, 4, 5, 6]
	lados.shuffle()
	var normais := []
	for i in 3:
		normais.append({"lados": lados[i], "marcas": lados[i]})
	var n: int = lados[3]
	var intruso := {"lados": n, "marcas": _outro_lado(n)}
	return _embaralhar(normais, intruso)


# ------------------------------------------------------- ajudantes

func _outro_lado(n: int) -> int:
	var opcoes := [3, 4, 5, 6]
	opcoes.erase(n)
	return opcoes.pick_random()


# Três cópias da base mais o intruso, embaralhadas.
func _intruso(base: Dictionary, intruso: Dictionary) -> Dictionary:
	return _embaralhar([base.duplicate(), base.duplicate(), base.duplicate()], intruso)


func _embaralhar(normais: Array, intruso: Dictionary) -> Dictionary:
	var todas := normais.duplicate()
	todas.append(intruso)
	var ordem := [0, 1, 2, 3]
	ordem.shuffle()

	var opcoes := []
	var certa := 0
	for i in ordem.size():
		opcoes.append(todas[ordem[i]])
		if ordem[i] == 3:
			certa = i

	return {"enunciado": ACHE_O_INTRUSO, "opcoes": opcoes, "certa": certa, "modelo": {}}


func _responder(indice: int) -> void:
	if indice == _certa:
		Audio.tocar("aceito")
		_rodada += 1
		_proxima_rodada()
	else:
		Audio.tocar("recusado")
		Estado.partidas_terminal += 1
		_mostrar(%Recusa)
