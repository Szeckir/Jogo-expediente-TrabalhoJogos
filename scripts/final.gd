class_name Final
extends CanvasLayer

# Tela de vitória (cenas/ui/final.tscn). Mostra as portas do elevador se
# abrindo, e então o cartão do expediente com tempo, setores, móveis,
# fichas, os marcos da partida e a senha. Tudo é lido de Estado.
#
#   R               -> pede para recomeçar com outra cifra
#   E / ESC / ENTER -> pula a animação; depois dela, fecha a tela

signal reiniciar_pedido

const Dados = preload("res://dados/setores.gd")

const VERDE := Color(0.12, 0.31, 0.27)
const CINZA := Color(0.55, 0.55, 0.55)
const TINTA := Color(0.10, 0.10, 0.10)
const LARGURA_PORTA := 576.0
const ESCALA_CARIMBO := 2.4

var _animando := false
var _aberto_em := 0
var _sequencia: Tween

@onready var _raiz: Control = %Raiz
@onready var _brilho: Control = %Brilho
@onready var _portas: Control = %Portas
@onready var _porta_esq: Control = %PortaEsq
@onready var _porta_dir: Control = %PortaDir
@onready var _placa: Control = %Placa
@onready var _centro: Control = %Centro
@onready var _carimbo: Control = %Carimbo
@onready var _tempo: Label = %ValorTempo
@onready var _setores: Label = %ValorSetores
@onready var _moveis: Label = %ValorMoveis
@onready var _fichas: Label = %ValorFichas
@onready var _lista: VBoxContainer = %ListaMarcos
@onready var _senha: Label = %Senha
@onready var _bilhete: Label = %Bilhete
@onready var _faixa_senha: Control = %FaixaSenha
@onready var _rodape: Control = %Rodape


func _ready() -> void:
	# o carimbo gira e cresce em torno do próprio centro
	_carimbo.resized.connect(func(): _carimbo.pivot_offset = _carimbo.size * 0.5)


func abrir() -> void:
	_preencher_fixos()
	_estado_inicial()
	visible = true
	_aberto_em = Time.get_ticks_msec()
	_animando = true

	# Linha do tempo. Tudo roda em paralelo; cada passo tem o seu atraso (s).
	var t := create_tween().set_parallel(true)
	_sequencia = t
	t.finished.connect(func(): _animando = false)

	t.tween_property(_raiz, "modulate:a", 1.0, 0.25)

	# 1) o elevador chega: ding e a placa SAÍDA acende
	t.tween_callback(Audio.tocar.bind("elevador_ding")).set_delay(0.35)
	t.tween_property(_placa, "modulate:a", 1.0, 0.12).set_delay(0.35)
	t.tween_property(_placa, "modulate:a", 0.35, 0.12).set_delay(0.62)
	t.tween_property(_placa, "modulate:a", 1.0, 0.12).set_delay(0.80)

	# 2) as portas se abrem e a luz do lado de fora aparece
	t.tween_callback(Audio.tocar.bind("elevador")).set_delay(0.95)
	t.tween_property(_porta_esq, "position:x", -LARGURA_PORTA, 1.4) \
		.set_delay(1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_porta_dir, "position:x", LARGURA_PORTA * 2.0, 1.4) \
		.set_delay(1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_brilho, "modulate:a", 1.0, 1.4).set_delay(1.0)
	t.tween_callback(func(): _portas.visible = false).set_delay(2.45)

	# 3) o cartão sobe e recebe o carimbo
	t.tween_callback(Audio.tocar.bind("vitoria")).set_delay(1.9)
	t.tween_property(_centro, "modulate:a", 1.0, 0.45).set_delay(1.9)
	t.tween_property(_centro, "position:y", 0.0, 0.45) \
		.set_delay(1.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_carimbo, "modulate:a", 1.0, 0.08).set_delay(2.65)
	t.tween_property(_carimbo, "scale", Vector2.ONE, 0.16) \
		.set_delay(2.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(Audio.tocar.bind("carimbo")).set_delay(2.81)
	t.tween_property(_centro, "position:y", 5.0, 0.05).set_delay(2.81)
	t.tween_property(_centro, "position:y", 0.0, 0.16).set_delay(2.86)

	# 4) os números contam até o valor final
	var contagem := 1.0
	_contar(t, _tempo, 2.95, contagem, Estado.tempo, \
		func(v: float) -> String: return "%d:%02d" % [int(v) / 60, int(v) % 60])
	_contar(t, _setores, 2.95, contagem, float(Estado.visitados.size()), \
		func(v: float) -> String: return "%d/%d" % [int(round(v)), Dados.numeros().size()])
	_contar(t, _moveis, 2.95, contagem, float(Estado.examinados.size()), \
		func(v: float) -> String: return str(int(round(v))))
	_contar(t, _fichas, 2.95, contagem, float(Estado.fichas), \
		func(v: float) -> String: return str(int(round(v))))

	# 5) os marcos entram um a um
	for i in _lista.get_child_count():
		var linha: Control = _lista.get_child(i)
		var quando := 3.55 + 0.2 * i
		t.tween_property(linha, "modulate:a", 1.0, 0.2).set_delay(quando)
		if Estado.marcos.has(i + 1):
			t.tween_callback(Audio.tocar.bind("tecla")).set_delay(quando)

	# 6) a senha e a dica de teclas
	t.tween_property(_faixa_senha, "modulate:a", 1.0, 0.4).set_delay(4.7)
	t.tween_property(_rodape, "modulate:a", 1.0, 0.4).set_delay(4.9)
	t.tween_callback(Audio.tocar.bind("aceito")).set_delay(4.7)


func fechar() -> void:
	if not visible:
		return
	if _sequencia != null:
		_sequencia.kill()
	_animando = false
	Audio.tocar("overlay_fechar")
	var t := create_tween()
	t.tween_property(_raiz, "modulate:a", 0.0, 0.2)
	await t.finished
	visible = false


# Usado ao recomeçar a partida: some na hora.
func ocultar() -> void:
	if _sequencia != null:
		_sequencia.kill()
	_animando = false
	visible = false


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey):
		return
	# a tela de vitória é a única que responde enquanto está aberta
	get_viewport().set_input_as_handled()
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_R:
		reiniciar_pedido.emit()
		return
	# o mesmo E que fechou o último enigma não pode pular a animação
	if Time.get_ticks_msec() - _aberto_em < 400:
		return
	if event.keycode in [KEY_E, KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		if _animando:
			_pular()
		else:
			fechar()


# ------------------------------------------------------------ detalhes

func _pular() -> void:
	if _sequencia != null:
		_sequencia.kill()
	_animando = false
	_estado_final()


func _contar(t: Tween, rotulo: Label, atraso: float, dur: float, alvo: float, formato: Callable) -> void:
	rotulo.text = formato.call(0.0)
	t.tween_method(func(v: float): rotulo.text = formato.call(v), 0.0, alvo, dur) \
		.set_delay(atraso).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# Textos que não animam.
func _preencher_fixos() -> void:
	_senha.text = Estado.senha
	_bilhete.text = Estado.bilhete
	for i in _lista.get_child_count():
		var linha := _lista.get_child(i)
		var feito: bool = Estado.marcos.has(i + 1)
		var marca: Label = linha.get_node("Marca")
		var texto: Label = linha.get_node("Texto")
		marca.text = "✓" if feito else "—"
		marca.add_theme_color_override("font_color", VERDE if feito else CINZA)
		texto.text = Estado.MARCOS[i + 1]
		texto.add_theme_color_override("font_color", TINTA if feito else CINZA)


func _estado_inicial() -> void:
	_raiz.modulate.a = 0.0
	_brilho.modulate.a = 0.0
	_portas.visible = true
	_porta_esq.position.x = 0.0
	_porta_dir.position.x = LARGURA_PORTA
	_placa.modulate.a = 0.35
	_centro.modulate.a = 0.0
	_centro.position = Vector2(0.0, 28.0)
	_carimbo.modulate.a = 0.0
	_carimbo.scale = Vector2.ONE * ESCALA_CARIMBO
	_tempo.text = "0:00"
	_setores.text = "0/%d" % Dados.numeros().size()
	_moveis.text = "0"
	_fichas.text = "0"
	for linha in _lista.get_children():
		linha.modulate.a = 0.0
	_faixa_senha.modulate.a = 0.0
	_rodape.modulate.a = 0.0


func _estado_final() -> void:
	_raiz.modulate.a = 1.0
	_brilho.modulate.a = 1.0
	_portas.visible = false
	_placa.modulate.a = 1.0
	_centro.modulate.a = 1.0
	_centro.position = Vector2.ZERO
	_carimbo.modulate.a = 1.0
	_carimbo.scale = Vector2.ONE
	_tempo.text = "%d:%02d" % [int(Estado.tempo) / 60, int(Estado.tempo) % 60]
	_setores.text = "%d/%d" % [Estado.visitados.size(), Dados.numeros().size()]
	_moveis.text = str(Estado.examinados.size())
	_fichas.text = str(Estado.fichas)
	for linha in _lista.get_children():
		linha.modulate.a = 1.0
	_faixa_senha.modulate.a = 1.0
	_rodape.modulate.a = 1.0
