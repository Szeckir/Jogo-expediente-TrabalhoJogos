class_name Termo
extends VBoxContainer

# Termo (cenas/ui/termo.tscn): descobrir uma palavra de 5 letras em até
# 6 tentativas. É o prêmio de consolação do terminal: quando a cota de
# partidas acaba, ganhar uma rodada aqui devolve as tentativas.
#
#   verde     a letra está na palavra e na posição certa
#   amarelo   está na palavra, mas em outra posição
#   cinza     não está na palavra
#
# Letra repetida conta uma vez por ocorrência real na palavra (a marcação
# padrão: primeiro os verdes, depois os amarelos até acabar o estoque).
#
# Acento é cortesia, não regra: o jogador digita só as letras, a palavra é
# comparada sem acento, e quando o chute acerta a posição o tile mostra a
# letra já acentuada (AVIAO vira AVIÃO). Acento nunca entra nas dicas.
#
# O quadradinho onde a próxima letra entra é o selecionado (borda grossa):
# dá para clicar em qualquer um da linha atual, ou andar com ← →, e escrever
# fora de ordem. ENTER só vale com os 5 preenchidos.
#
# Não há dicionário: qualquer sequência de 5 letras vale como chute. Só as
# respostas saem da lista abaixo, que é de palavras fáceis.

## Disparado assim que o chute certo é enviado (antes da animação acabar).
signal ganhou

const TAM := 5
const TENTATIVAS := 6
const CELULA := 36.0

const PALAVRAS := [
	"AMIGO", "CASAL", "TEMPO", "PRAIA", "FESTA", "LIVRO", "FELIZ", "SONHO",
	"VERDE", "CARRO", "PORTA", "JOGAR", "NOITE", "FAZER", "DENTE", "BANCO",
	"CHAVE", "FÁCIL", "ÁGUIA", "AVIÃO", "LIMÃO", "BALÃO", "MAMÃE", "ÚNICO",
	"SÁBIO", "CINCO", "TERRA", "FLORA", "MUNDO", "GENTE", "PLANO", "SALTO",
	"PEDRA", "NUVEM", "CHUVA", "BRISA", "LUZES", "CORPO", "FORTE", "RISCO",
	"TURMA", "VIDRO", "PAPEL", "LINHA", "MESAS", "TORRE", "BOLSA", "SABOR",
	"PRATO", "FRUTA",
]

const ACENTOS := {
	"Á": "A", "À": "A", "Â": "A", "Ã": "A", "Ä": "A",
	"É": "E", "È": "E", "Ê": "E", "Ë": "E",
	"Í": "I", "Ì": "I", "Î": "I", "Ï": "I",
	"Ó": "O", "Ò": "O", "Ô": "O", "Õ": "O", "Ö": "O",
	"Ú": "U", "Ù": "U", "Û": "U", "Ü": "U",
	"Ç": "C",
}

const LINHAS_TECLADO := ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]

const TINTA := Color(0.10, 0.10, 0.10)
const BRANCO := Color(1, 1, 1)
const VAZIO := Color(0.99, 0.99, 0.98)
const BORDA := Color(0.62, 0.65, 0.63)
const BORDA_CHEIA := Color(0.20, 0.22, 0.21)
const COR_VERDE := Color(0.18, 0.52, 0.34)
const COR_AMARELO := Color(0.80, 0.64, 0.14)
const COR_CINZA := Color(0.42, 0.44, 0.43)

var _segredo := ""     # com acento, como sai da lista
var _base := ""        # sem acento, é o que se compara
var _linha := 0
var _letras: Array = ["", "", "", "", ""]   # a linha atual, "" = vazio
var _cursor := 0                            # quadradinho selecionado
var _fim := false
var _travado := false  # a animação de revelar está rodando

var _paineis: Array[PanelContainer] = []
var _rotulos: Array[Label] = []
var _teclas := {}          # letra -> Button
var _melhor := {}          # letra -> 0 errada, 1 presente, 2 certa
var _status: Label
var _ajuda: PopupPanel
var _outra: Button


func _ready() -> void:
	add_theme_constant_override("separation", 8)

	# cabeçalho: título e o botão da lâmpada, que abre a ajuda
	var topo := HBoxContainer.new()
	add_child(topo)
	var titulo := Label.new()
	titulo.text = "TERMO · 5 letras, 6 tentativas"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.add_theme_font_size_override("font_size", 13)
	titulo.add_theme_color_override("font_color", TINTA)
	topo.add_child(titulo)
	var lampada := _botao("", Vector2(42, 40), _abrir_ajuda)
	lampada.tooltip_text = "Como jogar"
	# fundo claro, como as teclas ainda não usadas
	lampada.add_theme_stylebox_override("normal", _estilo(Color(0.99, 0.97, 0.88), Color(0.90, 0.62, 0.10)))
	lampada.add_theme_stylebox_override("hover", _estilo(Color(1.0, 0.93, 0.70), Color(0.90, 0.62, 0.10)))
	lampada.add_theme_stylebox_override("pressed", _estilo(Color(0.98, 0.86, 0.50), Color(0.90, 0.62, 0.10)))
	lampada.draw.connect(_desenhar_lampada.bind(lampada))
	topo.add_child(lampada)
	_montar_ajuda()

	var grade := GridContainer.new()
	grade.columns = TAM
	grade.add_theme_constant_override("h_separation", 4)
	grade.add_theme_constant_override("v_separation", 4)
	grade.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(grade)
	for _i in TAM * TENTATIVAS:
		var painel := PanelContainer.new()
		painel.custom_minimum_size = Vector2(CELULA, CELULA)
		var rotulo := Label.new()
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rotulo.add_theme_font_size_override("font_size", 22)
		rotulo.add_theme_color_override("font_color", TINTA)
		painel.add_child(rotulo)
		painel.gui_input.connect(_ao_clicar_celula.bind(_paineis.size() % TAM, _paineis.size() / TAM))
		grade.add_child(painel)
		_paineis.append(painel)
		_rotulos.append(rotulo)

	_status = Label.new()
	_status.custom_minimum_size = Vector2(560, 0)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 14)
	_status.add_theme_color_override("font_color", TINTA)
	add_child(_status)

	for letras in LINHAS_TECLADO:
		var fila := HBoxContainer.new()
		fila.alignment = BoxContainer.ALIGNMENT_CENTER
		fila.add_theme_constant_override("separation", 4)
		add_child(fila)
		if letras == LINHAS_TECLADO[2]:
			fila.add_child(_botao("ENTER", Vector2(62, 30), _enviar))
		for letra in letras:
			var botao := _botao(letra, Vector2(34, 30), _digitar.bind(letra))
			fila.add_child(botao)
			_teclas[letra] = botao
		if letras == LINHAS_TECLADO[2]:
			fila.add_child(_botao("⌫", Vector2(48, 30), _apagar))

	_outra = _botao("Outra palavra", Vector2(0, 34), novo_jogo)
	_outra.visible = false
	add_child(_outra)

	novo_jogo()


func _botao(texto: String, tamanho: Vector2, ao_apertar: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = tamanho
	b.focus_mode = Control.FOCUS_NONE   # ENTER/espaço não podem apertar o botão em foco
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(ao_apertar)
	return b


# ---------------------------------------------------------- partida

# Sorteia uma palavra nova e limpa tudo. Também é o "Outra palavra".
func novo_jogo() -> void:
	var palavra: String = PALAVRAS.pick_random()
	_segredo = palavra
	_base = _sem_acento(palavra)
	_linha = 0
	_letras = ["", "", "", "", ""]
	_cursor = 0
	_fim = false
	_travado = false
	_melhor.clear()

	for i in _paineis.size():
		_rotulos[i].text = ""
		_rotulos[i].add_theme_color_override("font_color", TINTA)
		_paineis[i].add_theme_stylebox_override("panel", _estilo(VAZIO, BORDA))
	for letra in _teclas:
		_pintar_tecla(letra, -1)

	_outra.visible = false
	_mostrar_digitado()
	_dizer("Digite e aperte ENTER.")


# Verdadeiro quando a partida acabou (acerto ou tentativas esgotadas).
func encerrado() -> bool:
	return _fim


func _dizer(texto: String) -> void:
	_status.text = texto


func _sem_acento(texto: String) -> String:
	var saida := ""
	for c in texto.to_upper():
		saida += str(ACENTOS.get(c, c))
	return saida


# Para cada posição: 2 certa, 1 presente em outro lugar, 0 ausente.
func _avaliar(chute: String) -> Array:
	var resultado := [0, 0, 0, 0, 0]
	var sobra := {}
	for i in TAM:
		if chute[i] == _base[i]:
			resultado[i] = 2
		else:
			var b: String = _base[i]
			sobra[b] = int(sobra.get(b, 0)) + 1
	for i in TAM:
		if resultado[i] == 2:
			continue
		var c: String = chute[i]
		if int(sobra.get(c, 0)) > 0:
			resultado[i] = 1
			sobra[c] = int(sobra[c]) - 1
	return resultado


# ------------------------------------------------------------ entrada

func _input(event: InputEvent) -> void:
	if _fim or not is_visible_in_tree() or _ajuda.visible:
		return
	var tecla := event as InputEventKey
	if tecla == null or not tecla.pressed:
		return

	if tecla.keycode == KEY_BACKSPACE:
		_apagar()
	elif tecla.keycode == KEY_LEFT or tecla.keycode == KEY_RIGHT:
		_mover(-1 if tecla.keycode == KEY_LEFT else 1)
	elif tecla.keycode == KEY_ENTER or tecla.keycode == KEY_KP_ENTER:
		if tecla.echo:
			return
		_enviar()
	elif tecla.keycode == KEY_ESCAPE or tecla.echo or tecla.unicode <= 0:
		return      # ESC continua fechando a janela
	else:
		var c: String = _sem_acento(String.chr(tecla.unicode))
		if c.length() != 1 or c < "A" or c > "Z":
			return
		_digitar(c)
	# letras como o E não podem vazar para o Overlay (E fecha a janela)
	get_viewport().set_input_as_handled()


func _digitar(letra: String) -> void:
	if _fim or _travado:
		return
	_letras[_cursor] = letra
	if _cursor < TAM - 1:
		_cursor += 1
	Audio.tocar("tecla")
	_mostrar_digitado()


# Apaga a letra selecionada; se ela já está vazia, volta um e apaga aquela.
func _apagar() -> void:
	if _fim or _travado:
		return
	if _letras[_cursor] == "" and _cursor > 0:
		_cursor -= 1
	_letras[_cursor] = ""
	_mostrar_digitado()


func _mover(passo: int) -> void:
	if _fim or _travado:
		return
	_cursor = clampi(_cursor + passo, 0, TAM - 1)
	_mostrar_digitado()


func _ao_clicar_celula(evento: InputEvent, coluna: int, linha: int) -> void:
	var clique := evento as InputEventMouseButton
	if clique == null or not clique.pressed or clique.button_index != MOUSE_BUTTON_LEFT:
		return
	if _fim or _travado or linha != _linha:
		return
	_cursor = coluna
	_mostrar_digitado()


# Desenha a linha atual: letra de cada quadradinho e a borda grossa no
# selecionado.
func _mostrar_digitado() -> void:
	for i in TAM:
		var k := _linha * TAM + i
		if k >= _paineis.size():
			return
		var letra: String = _letras[i]
		_rotulos[k].text = letra
		var selecionada := (i == _cursor) and not _fim
		var estilo := _estilo(VAZIO, BORDA_CHEIA if letra != "" else BORDA)
		if selecionada:
			estilo = _estilo(VAZIO, TINTA, 5)
		_paineis[k].add_theme_stylebox_override("panel", estilo)


func _enviar() -> void:
	if _fim or _travado:
		return
	if _letras.has(""):
		Audio.tocar("recusado")
		_dizer("Faltam letras: a palavra tem 5.")
		return

	var chute := "".join(_letras)
	var resultado := _avaliar(chute)
	var linha := _linha
	var venceu := chute == _base
	_letras = ["", "", "", "", ""]
	_cursor = 0
	_linha += 1
	var acabou := venceu or _linha >= TENTATIVAS
	_fim = acabou
	_travado = true
	_dizer("")
	if not acabou:
		_mostrar_digitado()   # o cursor já vai para a linha de baixo

	if venceu:
		ganhou.emit()

	# revela uma letra de cada vez
	var t := create_tween()
	for i in TAM:
		t.tween_callback(_revelar.bind(linha, i, chute, int(resultado[i])))
		t.tween_interval(0.14)
	t.tween_callback(_depois_de_revelar.bind(venceu, acabou))


func _revelar(linha: int, i: int, chute: String, estado: int) -> void:
	var k := linha * TAM + i
	# acertou a posição: mostra a letra da palavra, com o acento dela
	_rotulos[k].text = _segredo[i] if chute[i] == _base[i] else chute[i]
	var cor := [COR_CINZA, COR_AMARELO, COR_VERDE][estado] as Color
	_rotulos[k].add_theme_color_override("font_color", BRANCO)
	_paineis[k].add_theme_stylebox_override("panel", _estilo(cor, cor))
	var letra: String = chute[i]
	if estado > int(_melhor.get(letra, -1)):
		_melhor[letra] = estado
		_pintar_tecla(letra, estado)
	Audio.tocar("tecla")


func _depois_de_revelar(venceu: bool, acabou: bool) -> void:
	_travado = false
	if venceu:
		_dizer("Acertou!")
	elif acabou:
		_dizer("Acabaram as tentativas. A palavra era %s." % _segredo)
		_outra.visible = true


# ------------------------------------------------------------- ajuda

func _abrir_ajuda() -> void:
	_ajuda.popup_centered()


# A mini janela de "como jogar", que abre pela lâmpada. As cores aparecem
# como amostras de verdade, do mesmo jeito que nos quadradinhos.
func _montar_ajuda() -> void:
	_ajuda = PopupPanel.new()
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.96, 0.95, 0.93)
	fundo.border_color = TINTA
	fundo.set_border_width_all(2)
	fundo.set_content_margin_all(18)
	_ajuda.add_theme_stylebox_override("panel", fundo)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 8)
	_ajuda.add_child(coluna)

	coluna.add_child(_texto_ajuda("COMO JOGAR", 15))
	coluna.add_child(_texto_ajuda(
		"Descubra a palavra secreta de 5 letras em até 6 tentativas. Digite e aperte ENTER.", 13))
	coluna.add_child(_linha_ajuda(COR_VERDE, "A letra está na palavra e no lugar certo."))
	coluna.add_child(_linha_ajuda(COR_AMARELO, "A letra está na palavra, mas em outra posição."))
	coluna.add_child(_linha_ajuda(COR_CINZA, "A letra não está na palavra."))

	coluna.add_child(_texto_ajuda("DICAS", 15))
	coluna.add_child(_texto_ajuda(
		"• Clique num quadradinho (ou use ← →) para escrever fora de ordem.\n"
		+ "• Comece com uma palavra de vogais variadas, como MOEDA.\n"
		+ "• Letras podem se repetir na palavra.\n"
		+ "• Acentos entram sozinhos e nunca contam nas dicas.\n"
		+ "• Olhe o teclado: as teclas coloridas lembram o que você já testou.", 13))

	var fechar := Button.new()
	fechar.text = "Entendi"
	fechar.custom_minimum_size = Vector2(0, 32)
	fechar.focus_mode = Control.FOCUS_NONE
	fechar.pressed.connect(_ajuda.hide)
	coluna.add_child(fechar)

	add_child(_ajuda)


func _texto_ajuda(texto: String, tamanho: int) -> Label:
	var l := Label.new()
	l.text = texto
	l.custom_minimum_size = Vector2(430, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", TINTA)
	return l


func _linha_ajuda(cor: Color, texto: String) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	var amostra := PanelContainer.new()
	amostra.custom_minimum_size = Vector2(26, 26)
	amostra.add_theme_stylebox_override("panel", _estilo(cor, cor))
	linha.add_child(amostra)
	var l := _texto_ajuda(texto, 13)
	l.custom_minimum_size = Vector2(390, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(l)
	return linha


# Ícone de lâmpada desenhado em cima do botão (evita depender de emoji):
# bulbo com brilho, pescoço, rosca e raios.
func _desenhar_lampada(b: Button) -> void:
	var c := b.size / 2.0 + Vector2(0.0, -3.0)
	var vidro := Color(0.99, 0.84, 0.25)
	var ambar := Color(0.90, 0.62, 0.10)
	var metal := Color(0.45, 0.47, 0.46)
	for i in 5:
		var ang := deg_to_rad(-150.0 + i * 30.0)
		var dir := Vector2(cos(ang), sin(ang))
		b.draw_line(c + dir * 12.5, c + dir * 16.5, ambar, 2.0)
	b.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-5.0, 7.0), c + Vector2(5.0, 7.0),
		c + Vector2(3.5, 12.0), c + Vector2(-3.5, 12.0)]), vidro)
	b.draw_circle(c, 9.0, vidro)
	b.draw_arc(c, 9.0, 0.0, TAU, 24, Color(0.15, 0.15, 0.15), 1.6, true)
	b.draw_circle(c + Vector2(-3.2, -3.2), 2.4, Color(1, 1, 1, 0.75))
	b.draw_rect(Rect2(c + Vector2(-4.0, 12.5), Vector2(8.0, 2.4)), metal)
	b.draw_rect(Rect2(c + Vector2(-2.6, 15.6), Vector2(5.2, 2.2)), metal)


# ------------------------------------------------------------ visual

func _pintar_tecla(letra: String, estado: int) -> void:
	var botao: Button = _teclas[letra]
	if estado < 0:
		# tecla ainda não usada: clara, para as usadas (cinza escuro, amarelo,
		# verde) se destacarem
		botao.add_theme_stylebox_override("normal", _estilo(Color(0.93, 0.93, 0.91), BORDA))
		botao.add_theme_stylebox_override("hover", _estilo(Color(0.87, 0.88, 0.86), BORDA))
		botao.add_theme_stylebox_override("pressed", _estilo(Color(0.80, 0.82, 0.80), BORDA))
		for nome in ["font_color", "font_hover_color", "font_pressed_color"]:
			botao.add_theme_color_override(nome, TINTA)
		return
	var cor := [COR_CINZA, COR_AMARELO, COR_VERDE][estado] as Color
	for nome in ["normal", "hover", "pressed"]:
		botao.add_theme_stylebox_override(nome, _estilo(cor, cor))
	for nome in ["font_color", "font_hover_color", "font_pressed_color"]:
		botao.add_theme_color_override(nome, BRANCO)


func _estilo(fundo: Color, borda: Color, espessura := 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = borda
	s.set_border_width_all(espessura)
	s.set_corner_radius_all(3)
	return s
