class_name Pagina
extends VBoxContainer

# Base de toda tela de enigma que abre no Overlay. Cada página é uma
# cena em cenas/paginas/ cujo nó raiz é um VBoxContainer com um script
# que herda desta classe.
#
# Para criar uma página nova:
#   1. Cena nova com raiz VBoxContainer e um script "extends Pagina".
#   2. Monte os nós no editor (labels, botões...).
#   3. Escreva o que acontece ao abrir em ao_abrir().
#   4. No móvel que deve abri-la, aponte o campo Pagina para a cena.

## Título no topo da janela. Vazio = usa o rótulo do móvel.
@export var titulo := ""


# Chamada logo depois que a página entra na janela. "movel" é quem
# abriu (pode ser null, como no fim do jogo).
func ao_abrir(_movel: Movel) -> void:
	pass


# O marco 3 é o momento em que dois móveis de setores diferentes
# se revelam parte do mesmo enigma.
func _checar_cruzamento() -> void:
	if Estado.foi_examinado(1, "Quadro de avisos") and Estado.foi_examinado(3, "Armário 14"):
		Estado.cumprir_marco(3)
