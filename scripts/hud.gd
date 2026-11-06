class_name Hud
extends CanvasLayer

# Interface que fica sempre na tela (cenas/ui/hud.tscn): cabeçalho do
# setor, prompt de interação, aviso deslizante e o painel lateral com
# bolso e caderno. O mapa tem janela própria (cenas/ui/mapa.tscn, tecla
# M). O visual é todo da cena; aqui só entra o texto que muda durante o
# jogo.

const APAGADO := Color(0.55, 0.55, 0.55)
const ENTRADA := preload("res://cenas/ui/caderno_entrada.tscn")

@onready var _cabecalho: Label = %Cabecalho
@onready var _prompt: Label = %Prompt
@onready var _aviso: Label = %Aviso
@onready var _bolso: Label = %Bolso
@onready var _caderno: VBoxContainer = %Caderno
@onready var _caderno_vazio: Label = %Vazio

var _aviso_t := 0.0


func _ready() -> void:
	Estado.bolso_mudou.connect(_atualizar_bolso)
	Estado.caderno_mudou.connect(_atualizar_caderno)
	Estado.aviso.connect(mostrar_aviso)
	Estado.marco_cumprido.connect(_ao_cumprir_marco)

	_atualizar_bolso()
	_atualizar_caderno()


func _process(delta: float) -> void:
	if _aviso_t > 0.0:
		_aviso_t -= delta
		if _aviso_t <= 0.0:
			_aviso.text = ""


func definir_setor(numero: int, nome: String) -> void:
	_cabecalho.text = "SETOR %02d - %s" % [numero, nome.to_upper()]


func definir_prompt(texto: String) -> void:
	_prompt.text = texto


func mostrar_aviso(texto: String) -> void:
	_aviso.text = texto
	_aviso_t = 2.8


func _ao_cumprir_marco(_numero: int, texto: String) -> void:
	mostrar_aviso(texto)


# O bolso lista só o que o jogador já tem na mão. Antes havia uma linha
# fixa por item, com um traço no lugar do "sim", e isso entregava o jogo:
# a tela anunciava que existe um crachá de saída e uma chave do arquivo
# antes de o jogador ter qualquer motivo para desconfiar disso.
func _atualizar_bolso() -> void:
	var linhas := []
	if Estado.fichas > 0:
		linhas.append("Fichas: " + str(Estado.fichas))
	if Estado.tem_sanduiche:
		linhas.append("Sanduíche")
	if Estado.tem_chave:
		linhas.append("Chave do arquivo")
	if Estado.tem_cracha:
		linhas.append("Crachá de saída")
	_bolso.text = "\n".join(linhas) if not linhas.is_empty() else "vazio"


func _atualizar_caderno() -> void:
	for filho in _caderno.get_children():
		if filho != _caderno_vazio:
			_caderno.remove_child(filho)
			filho.queue_free()

	_caderno_vazio.visible = Estado.caderno.is_empty()

	for entrada in Estado.caderno:
		var l: Label = ENTRADA.instantiate()
		l.text = ("✓ " if entrada["resolvido"] else "• ") + entrada["texto"]
		if entrada["resolvido"]:
			l.add_theme_color_override("font_color", APAGADO)
		_caderno.add_child(l)
