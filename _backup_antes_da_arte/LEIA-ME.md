# Expediente - projeto em Godot

Grupo 07. Godot 4.4 ou mais novo (testado no 4.7), GDScript.

## Rodar

Abrir o Godot, **Importar**, apontar para o `project.godot` desta pasta, F5.

Teclas: setas ou A/D para andar, **E** para interagir, **ESC** para pausar (e para fechar enigma), **R** para recomeçar depois de vencer.

## O que funciona

A cadeia inteira do pitch, do começo ao fim:

1. Setor 01, planta de evacuação -> descobre o elevador.
2. Setor 02, terminal -> vencer 3 rodadas -> 3 fichas.
3. Setor 05, máquina -> sanduíche por 2 fichas. O café custa 1 e não serve para nada, como planejado.
4. Setor 04, colega -> troca o sanduíche pela chave.
5. Setor 01 e 03, quadro de avisos e armário 14 -> tabela de cifra + bilhete de três letras.
6. Porta 06 com a chave -> setor 06, cofre, senha de três dígitos -> crachá nível 4.
7. Setor 01, elevador -> fim.

Além disso:

- **Minimapa** que se desenha sozinho, com setor visitado, setor conhecido mas não visitado, porta trancada tracejada e um ponto por móvel examinado.
- **Caderno** que anota e risca a linha quando a pendência se resolve.
- **Os cinco marcos** do slide 10, detectados de verdade. O primeiro dispara quando o jogador completa uma volta inteira sem perceber.
- **Tela de título**, **pausa com controle de volume** e **tela final** com resumo e os marcos cumpridos.
- **14 efeitos sonoros** e o zumbido de lâmpada fluorescente em loop.
- Cifra e bilhete sorteados a cada partida, então a senha nunca repete.

## Tudo é cena

O jogo é montado no editor, com cenas encaixadas umas nas outras. Abra `main.tscn` e a árvore inteira está lá:

```
Jogo (main.tscn)
├─ Cenario     parede, rodapé, chão
├─ Mundo       o setor atual entra aqui quando o jogo roda
├─ Jogador     o boneco, parado no centro
├─ HUD         cabeçalho, prompt, aviso, painel (minimapa, bolso, caderno)
├─ Overlay     a janela dos enigmas (só a moldura)
├─ Pausa
└─ Titulo
```

## Os arquivos

```
project.godot            configuração e autoloads
main.tscn                a raiz do jogo

cenas/
  cenario/               fundo
  jogador/               o boneco
  movel/                 movel.tscn (base) + uma cena por tipo: porta, quadro,
                         planta, terminal, armario, maquina, colega, cofre,
                         elevador, neutro
  setores/               setor_01 ... setor_06 (os móveis posicionados no editor)
                         e luminaria.tscn
  ui/                    hud, minimapa, caderno_entrada, overlay, pausa, titulo
  paginas/               uma cena por enigma (o conteúdo da janela do Overlay)

scripts/
  estado.gd              autoload: fichas, itens, cifra, caderno, marcos
  audio.gd               autoload: efeitos sonoros
  jogo.gd                corredor circular, interação, troca de setor
  setor.gd               o anel de um setor (distâncias, posicionar, móvel mais perto)
  item_do_anel.gd        tudo que mora no anel (móveis e luminárias)
  movel.gd, porta.gd     comportamento dos móveis
  jogador.gd, hud.gd, minimapa.gd, overlay.gd, pausa.gd, titulo.gd
  paginas/               um script por enigma (pagina.gd é a base)

dados/setores.gd         catálogo: lista as cenas dos setores e lê dados delas
```

Os autoloads `Estado` e `Audio` continuam sendo código puro (não têm o que desenhar). `Audio` ainda gera os sons por código.

## Como fazer cada coisa

### Mexer num setor (mover móvel, mudar nome, perímetro)

Abra `cenas/setores/setor_NN.tscn`. A linha **verde** na tela é o anel, e a **vermelha** é onde ele fecha e volta ao 0 (só aparece no editor). Arraste o móvel pelo eixo X (deixe o Y em 0, que é o chão). No nó raiz, o Inspetor tem `Nome`, `Perimetro` e `Posicao Mapa` (onde o setor aparece no minimapa).

### Criar um móvel num setor

Arraste `cenas/movel/<tipo>.tscn` para dentro do setor e preencha `Rotulo` no Inspetor. Se for uma **porta**, preencha também `Destino` (número do setor para onde ela leva) e, se precisar de chave, marque `Exige Chave`.

### Criar um tipo de móvel novo

Em `cenas/movel/`, clique com o botão direito em `movel.tscn` -> **Nova cena herdada**. Ajuste o tamanho/cor do nó `Caixa` e aponte o campo `Pagina` para a tela que ele abre.

### Criar um setor novo

Duplique um `setor_NN.tscn`, renomeie, ajuste os móveis e as portas. Depois acrescente a linha dele em `CENAS` no `dados/setores.gd`.

### Criar um enigma novo

1. Em `cenas/paginas/`, crie uma cena com raiz **VBoxContainer** e um script que começa com `extends Pagina`.
2. Monte labels e botões no editor. Para o que acontece quando a página abre, escreva `ao_abrir()`.
3. No móvel que deve abri-la, aponte o campo `Pagina` para essa cena.

O título da janela vem do campo `Titulo` da página. Se ficar vazio, usa o rótulo do móvel.

### Tabela rápida

| Quero... | Vou em |
|---|---|
| mover um móvel, mudar perímetro de setor | `cenas/setores/setor_NN.tscn` |
| trocar retângulo por sprite | a cena do tipo, em `cenas/movel/` (ver "O que falta para o T2") |
| mudar o texto ou o layout de um enigma | a cena em `cenas/paginas/` |
| mudar a lógica de um enigma | o script em `scripts/paginas/` |
| mudar preço, prêmio ou cota | `scripts/estado.gd` |
| mudar velocidade ou raio de interação | constantes no topo de `scripts/jogo.gd` |
| mexer no HUD, título ou pausa | `cenas/ui/` |
| trocar som gerado por arquivo | `_criar_sons()` em `scripts/audio.gd` |

## Como o corredor circular funciona

O truque está em `setor.gd`. **O jogador nunca se move** - fica travado no centro da tela. O que muda é a posição de cada móvel:

```gdscript
func delta_anel(de: float, para: float) -> float:
	return fposmod(para - de + perimetro / 2.0, perimetro) - perimetro / 2.0
```

Isso devolve a distância pelo caminho mais curto do anel. Como nada nunca está "do outro lado", não existe momento de emenda e não existe câmera para pular quando a volta fecha.

O X que cada móvel tem no editor é a posição dele no anel. O `jogo.gd` guarda onde o jogador está no anel (`posicao`) e, a cada quadro, pede ao setor para empurrar os móveis pela tela. A coluna e a altura do chão em que o jogador fica são as do nó `Jogador` em `main.tscn`.

O perímetro de cada setor está no nó raiz da cena do setor. A 160 px/s, o setor 01 (1900 px) dá uma volta em ~12 segundos, que é o alvo do GDD.

## Sobre o som

Os efeitos são **gerados por código** em `audio.gd`, sem nenhum arquivo de áudio. Isso existe para o jogo ter som agora, não para ficar assim. Quando vocês gravarem ou baixarem os sons de verdade, troquem o corpo de `_criar_sons()` por `load("res://sons/porta.wav")` e o resto continua funcionando igual.

## O que falta para o T2

1. **Sprites no lugar dos retângulos.** Em cada cena de `cenas/movel/`, adicionar um `Sprite2D` (com o pé do desenho na origem do móvel) e desligar o `Visible` do nó `Caixa`. Nó herdado não pode ser apagado, só escondido.
2. **Animação do jogador.** Hoje `jogador.gd` desenha com `_draw()`. Em `cenas/jogador/jogador.tscn`, trocar por `AnimatedSprite2D` com as três animações.
3. **Sons de verdade** no lugar dos gerados.
4. **Mais variedade no terminal.** Hoje são cinco regras (quadrados, múltiplos de 5, pares, primos, múltiplos de 3). É o pedaço mais fraco do conjunto. Está em `scripts/paginas/pagina_terminal.gd`.
5. **Balanceamento** com gente de fora: velocidade, perímetro, economia.
6. **Salvamento** - só no T3, segundo o próprio GDD.

## Divisão possível entre três

- **Arte e animação:** itens 1 e 2. Mexe nas cenas de `cenas/movel/` e em `cenas/jogador/`, não encosta na lógica.
- **Som e interface:** item 3, mais ajustes de `cenas/ui/` (HUD, minimapa, título, pausa).
- **Conteúdo e balanceamento:** itens 4 e 5, mais `cenas/paginas/` e `cenas/setores/`.

Os três tocam pastas diferentes, então dá para trabalhar em paralelo sem conflito. Cena `.tscn` é texto e resolve bem no Git, mas evitem duas pessoas mexendo na **mesma** cena ao mesmo tempo.
