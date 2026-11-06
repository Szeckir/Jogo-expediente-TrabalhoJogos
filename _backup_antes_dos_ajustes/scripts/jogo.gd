extends Node2D

# Raiz do jogo (main.tscn). Os pedaços visuais são cenas filhas:
#   Cenario, Mundo (onde o setor atual entra), Jogador, HUD, Overlay,
#   Pausa e Titulo. Aqui fica só a orquestração: o corredor circular,
#   a interação e a troca de setor.

const Dados = preload("res://dados/setores.gd")

const VELOCIDADE := 160.0   # px/s. Perímetro 1900 dá uma volta em ~12s
const RAIO_INTERACAO := 70.0

var setor_atual := 1
var perimetro := 1900.0
var posicao := 0.0          # posição do jogador no anel, sempre em [0, perimetro)

var _setor: Setor
var _alvo: Movel = null
var _final_mostrado := false
var _comecou := false

var _andado := 0.0          # distância acumulada, para detectar a primeira volta
var _passo_t := 0.0

@onready var _cenario: Cenario = $Cenario
@onready var _mundo: Node2D = $Mundo
@onready var _jogador: Jogador = $Jogador
@onready var _hud: Hud = $HUD
@onready var _overlay: Overlay = $Overlay
@onready var _pausa: Pausa = $Pausa
@onready var _titulo: Titulo = $Titulo

# O jogador fica parado onde você o colocar no editor. O mundo gira em
# volta dele: _centro_x é a coluna dele e _chao_y é a altura do chão.
@onready var _centro_x: float = _jogador.position.x
@onready var _chao_y: float = _jogador.position.y


func _ready() -> void:
	randomize()
	entrar_no_setor(1, 300.0)


# ------------------------------------------------------------- setor

func entrar_no_setor(numero: int, entrada_x: float) -> void:
	setor_atual = numero

	if _setor != null:
		_mundo.remove_child(_setor)
		_setor.queue_free()
	_alvo = null

	_setor = Dados.CENAS[numero].instantiate()
	_mundo.add_child(_setor)

	perimetro = _setor.perimetro
	posicao = fposmod(entrada_x, perimetro)
	_andado = 0.0

	Estado.visitados[numero] = true
	Estado.mapa_mudou.emit()

	_hud.definir_setor(numero, _setor.nome)
	_posicionar()
	_atualizar_marcas()


# Móvel já examinado ganha um tique na etiqueta.
func _atualizar_marcas() -> void:
	for m in _setor.moveis:
		m.marcar_examinado(Estado.foi_examinado(setor_atual, m.rotulo))


# -------------------------------------------------------------- loop

func _process(delta: float) -> void:
	if _overlay.visible or _titulo.visible or not _comecou:
		_jogador.andando = false
		return

	var direcao := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		direcao -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		direcao += 1.0

	if direcao != 0.0:
		var avanco := VELOCIDADE * delta
		posicao = fposmod(posicao + direcao * avanco, perimetro)
		_jogador.virado = int(direcao)

		# marco 1: a primeira volta completa
		_andado += avanco
		if _andado >= perimetro and not Estado.marcos.has(1):
			Estado.cumprir_marco(1)

		_passo_t += delta
		if _passo_t > 0.34:
			_passo_t = 0.0
			Audio.tocar("passo")

	_jogador.andando = direcao != 0.0

	_posicionar()
	_procurar_alvo()


func _posicionar() -> void:
	_cenario.atualizar(posicao)
	_setor.posicionar(posicao, _centro_x, _chao_y)


func _procurar_alvo() -> void:
	_alvo = _setor.movel_mais_proximo(posicao, RAIO_INTERACAO)
	if _alvo == null:
		_hud.definir_prompt("")
	else:
		_hud.definir_prompt("E  ·  " + _alvo.rotulo)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if not _comecou:
		return

	if event.keycode == KEY_ESCAPE and not _overlay.visible:
		if _pausa.visible:
			_pausa.fechar()
		else:
			_pausa.abrir()
		return

	if event.keycode == KEY_R and Estado.venceu:
		_reiniciar()
		return

	if event.keycode == KEY_E and not _overlay.visible and _alvo != null:
		_interagir(_alvo)


# ---------------------------------------------------------- interação

func _interagir(m: Movel) -> void:
	_jogador.estender_braco()
	Estado.marcar_examinado(setor_atual, m.rotulo)
	_atualizar_marcas()

	if m is Porta:
		if m.exige_chave and not Estado.tem_chave:
			_overlay.abrir(m.pagina_trancada, m)
		else:
			Audio.tocar("porta_abrir")
			_atravessar(m.destino)
	else:
		# cada móvel já sabe qual tela abre (ver o campo Pagina na cena dele)
		_overlay.abrir(m.pagina, m)


func _atravessar(destino: int) -> void:
	# chega ao lado da porta que volta para o setor de onde veio
	var entrada := 300.0
	for p in Dados.info(destino)["portas"]:
		if p["destino"] == setor_atual:
			entrada = p["x"] + 90.0
			break
	entrar_no_setor(destino, entrada)


# --------------------------------------------- sinais das cenas filhas
# (conectados em main.tscn, aba Nó > Sinais)

func _ao_comecar() -> void:
	_comecou = true


func _ao_fechar_overlay() -> void:
	if Estado.venceu and not _final_mostrado:
		_final_mostrado = true
		_mostrar_final()


func _mostrar_final() -> void:
	var linhas := "Saiu em %d min %02d s.\n\n" % [int(Estado.tempo) / 60, int(Estado.tempo) % 60]
	linhas += "Setores abertos: %d de 6\n" % Estado.visitados.size()
	linhas += "Móveis examinados: %d\n" % Estado.examinados.size()
	linhas += "Fichas que sobraram: %d\n\n" % Estado.fichas
	linhas += "MARCOS DA PARTIDA\n"
	for numero in [1, 2, 3, 4, 5]:
		linhas += ("✓  " if Estado.marcos.has(numero) else "—  ") + Estado.MARCOS[numero] + "\n"
	linhas += "\nA senha era %s, do bilhete %s.\n" % [Estado.senha, Estado.bilhete]
	linhas += "\nR para bater o ponto de novo, com outra cifra."
	_overlay.abrir_documento("Fim de expediente", linhas)


func _reiniciar() -> void:
	Estado.reiniciar()
	_final_mostrado = false
	_overlay.visible = false
	entrar_no_setor(1, 300.0)
