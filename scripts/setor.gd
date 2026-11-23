@tool
class_name Setor
extends Node2D

# Um setor do escritório. Cada setor é uma cena em cenas/setores/.
#
# Para montar um setor no editor:
#   - arraste móveis (cenas/movel/*.tscn) para dentro dele;
#   - a posição X de cada móvel é o ponto dele no anel, de 0 até o
#     perímetro; deixe Y em 0 (é o chão);
#   - a linha verde que aparece no editor mostra o anel inteiro, e a
#     vermelha é onde ele fecha (e volta para o 0).
#
# As luminárias do teto e a decoração do ambiente são criadas sozinhas
# ao longo do anel. Gente de fundo (Npc) a gente põe na mão, na cena.

const LUMINARIA := preload("res://cenas/setores/luminaria.tscn")

## A "cara" do setor. Decide as luminárias e a decoração que nascem
## sozinhas:
##   COMUM      escritório limpo, sem nada de especial
##   FRIO       luz fria tremendo e racks de servidor piscando
##   ARMARIOS   fileira de armários de aço ao fundo
##   DESTRUIDO  paredes quebradas e rachadas, entulho, lâmpadas
##              balançando, tortas e queimadas
##   MAQUINAS   canos pela parede toda, com válvulas soltando vapor
##   ARQUIVO    pilhas de caixas e lâmpadas queimadas
enum Ambiente { COMUM, FRIO, ARMARIOS, DESTRUIDO, MAQUINAS, ARQUIVO }

## Número do setor (1 a 6). Tem que bater com o das portas que levam até ele.
@export var numero := 1
## Nome que aparece no cabeçalho do jogo.
@export var nome := ""
## Comprimento do anel em pixels. O jogador anda em x, e quando passa
## do perímetro a posição volta a zero.
@export var perimetro := 1500.0:
	set(valor):
		perimetro = valor
		queue_redraw()
## Onde o cartão deste setor fica no mapa (tecla M), em colunas e linhas:
## (0, 0) é o canto de cima à esquerda, (1, 0) é o cartão ao lado e
## (0, 1) é o de baixo.
@export var posicao_mapa := Vector2.ZERO
## Distância entre luminárias no teto. 0 desliga.
@export var espaco_luminarias := 320.0
@export var ambiente: Ambiente = Ambiente.COMUM
## Tinta aplicada à parede, ao chão e (mais de leve) aos móveis do setor.
## Branco deixa tudo como está.
@export var tom := Color.WHITE

## Tudo que mora no anel (móveis e luminárias).
var itens: Array[ItemDoAnel] = []
## Só os móveis.
var moveis: Array[Movel] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_criar_luminarias()
	_criar_decoracao()
	for filho in get_children():
		if filho is ItemDoAnel:
			itens.append(filho)
		if filho is Movel:
			moveis.append(filho)


func _criar_luminarias() -> void:
	if espaco_luminarias <= 0.0:
		return
	var quantas := int(perimetro / espaco_luminarias)
	for i in quantas:
		var luz: Luminaria = LUMINARIA.instantiate()
		luz.position.x = i * espaco_luminarias
		luz.estilo = _estilo_da_luminaria(i)
		luz.fase = i * 1.7
		add_child(luz)
		move_child(luz, i)   # ficam atrás dos móveis


func _estilo_da_luminaria(i: int) -> Luminaria.Estilo:
	match ambiente:
		Ambiente.FRIO:
			return Luminaria.Estilo.PISCANDO
		Ambiente.DESTRUIDO:
			return [Luminaria.Estilo.BALANCANDO, Luminaria.Estilo.TORTA,
				Luminaria.Estilo.PISCANDO][i % 3]
		Ambiente.ARQUIVO:
			return Luminaria.Estilo.APAGADA if i % 3 == 1 else Luminaria.Estilo.FIXA
	return Luminaria.Estilo.FIXA


# Espalha a decoração do ambiente ao longo do anel. O sorteio é semeado
# pelo número do setor, então o setor é sempre igual a cada visita.
func _criar_decoracao() -> void:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = numero * 7919
	# Pouca coisa de propósito: a decoração é tempero, não papel de parede.
	match ambiente:
		Ambiente.DESTRUIDO:
			_espalhar(sorteio, 430.0, 130.0, [Decor.Tipo.BURACO, Decor.Tipo.RACHADURA,
				Decor.Tipo.ESCOMBRO, Decor.Tipo.RACHADURA])
		Ambiente.FRIO:
			_espalhar(sorteio, 900.0, 160.0, [Decor.Tipo.RACK])
		Ambiente.ARMARIOS:
			_espalhar(sorteio, 1000.0, 160.0, [Decor.Tipo.ARMARIOS])
		Ambiente.ARQUIVO:
			_espalhar(sorteio, 560.0, 130.0, [Decor.Tipo.CAIXAS])
		Ambiente.MAQUINAS:
			# um cano só, contínuo: trechos de 200 px que se encostam e fecham
			# o anel. Só alguns trechos têm válvula (semente múltipla de 4), longe das portas.
			var trechos := maxi(1, roundi(perimetro / 200.0))
			for i in trechos:
				var semente := (sorteio.randi() & ~3) | (0 if i in [3, 8] else 1)
				_colocar(Decor.Tipo.CANO, i * perimetro / trechos, semente)


# Um item a cada `passo` px (com folga aleatória), pulando as posições a
# menos de `folga` de qualquer móvel, para não esconder porta nem enigma.
func _espalhar(sorteio: RandomNumberGenerator, passo: float, folga: float, tipos: Array) -> void:
	var x := passo * 0.6
	var n := 0
	while x < perimetro - passo * 0.5:
		var tipo: Decor.Tipo = tipos[n % tipos.size()]
		n += 1
		if not _perto_de_movel(x, folga):
			_colocar(tipo, x, sorteio.randi())
			if tipo == Decor.Tipo.BURACO:
				_colocar(Decor.Tipo.ESCOMBRO, x + sorteio.randf_range(-20.0, 20.0), sorteio.randi())
		x += passo + sorteio.randf_range(-passo * 0.2, passo * 0.2)


func _perto_de_movel(x: float, folga: float) -> bool:
	for filho in get_children():
		if filho is Movel and absf(delta_anel(x, filho.position.x)) < folga:
			return true
	return false


func _colocar(tipo: Decor.Tipo, x: float, semente: int) -> void:
	var d := Decor.new()
	d.tipo = tipo
	d.semente = semente
	d.position.x = x
	add_child(d)
	move_child(d, 0)   # atrás de tudo


# Distância entre dois pontos do anel, sempre pelo caminho mais curto.
# É daqui que sai a ilusão: nada nunca está "do outro lado".
func delta_anel(de: float, para: float) -> float:
	return fposmod(para - de + perimetro / 2.0, perimetro) - perimetro / 2.0


# Empurra cada item para o lugar certo da tela, dado onde o jogador está.
func posicionar(posicao_jogador: float, centro_x: float, chao_y: float) -> void:
	for item in itens:
		var dx := delta_anel(posicao_jogador, item.x_anel)
		if absf(dx) > 700.0:
			item.visible = false
		else:
			item.visible = true
			item.position = Vector2(centro_x + dx, chao_y)


# O móvel mais perto do jogador dentro do raio, ou null.
func movel_mais_proximo(posicao_jogador: float, raio: float) -> Movel:
	var melhor: Movel = null
	var menor := raio
	for m in moveis:
		var d := absf(delta_anel(posicao_jogador, m.x_anel))
		if d < menor:
			menor = d
			melhor = m
	return melhor


# Só no editor: régua do anel, para saber até onde dá para colocar móvel.
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var verde := Color(0.12, 0.31, 0.27, 0.85)
	var vermelho := Color(0.80, 0.20, 0.20, 0.90)
	var fonte := ThemeDB.fallback_font
	draw_line(Vector2(0, 0), Vector2(perimetro, 0), verde, 2.0)
	draw_line(Vector2(0, -200), Vector2(0, 40), verde, 2.0)
	draw_line(Vector2(perimetro, -200), Vector2(perimetro, 40), vermelho, 2.0)
	draw_string(fonte, Vector2(6, 64), "início do anel (x = 0)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, verde)
	draw_string(fonte, Vector2(perimetro - 300, 64),
		"fim do anel (x = %d) · volta ao 0" % int(perimetro),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, vermelho)
