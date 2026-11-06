# Expediente - projeto em Godot

Grupo 07. Godot 4.4 ou mais novo (testado no 4.7), GDScript.

## Rodar

Abrir o Godot, **Importar**, apontar para o `project.godot` desta pasta, F5.

Teclas: setas ou A/D para andar (velocidade única, não tem mais SHIFT), **E** para interagir (apertar **E** de novo fecha o enigma), **M** para abrir e fechar o mapa, **ESC** para pausar (e para fechar enigma ou mapa), **R** para recomeçar depois de vencer. Na tela de vitória: **E**, **ESC** ou **ENTER** pulam a animação e depois fecham a tela, **R** recomeça.

## O que funciona

A cadeia inteira do pitch, do começo ao fim:

1. Setor 01, planta de evacuação -> descobre o elevador.
2. Setor 02, terminal -> vencer 4 rodadas (a última na grade de fluxo) -> 3 fichas.
3. Setor 05, máquina -> sanduíche por 2 fichas. O café custa 1 e não serve para nada, como planejado.
4. Setor 04, colega -> troca o sanduíche pela chave.
5. Setor 01 e 03, quadro de avisos e armário 14 -> tabela de cifra + bilhete de três letras.
6. Porta 06 com a chave -> setor 06, cofre, senha de três dígitos -> crachá de saída.
7. Setor 01, elevador -> fim.

Além disso:

- **Mapa do andar** em janela no meio da tela (tecla **M**). Cada setor é um cartão com número, nome e quantos móveis já foram examinados. O setor onde você está fica em verde, os visitados em branco, os que você só viu a porta ficam tracejados com "?", e a porta trancada aparece com cadeado. A placa SAÍDA surge quando você descobre o elevador. Com o mapa aberto o boneco fica parado.
- **Caderno** que anota e risca a linha quando a pendência se resolve.
- **Os cinco marcos** do slide 10, detectados de verdade. O primeiro dispara quando o jogador completa uma volta inteira sem perceber.
- **Fade preto de 0,5 s ao passar por uma porta**: a tela escurece em 0,25 s, o setor troca no escuro e clareia em 0,25 s, com um som próprio de porta (trinco, rangido e batida). Durante o fade o boneco e as teclas ficam travados.
- **Tela de vitória animada**: o elevador toca, as portas de aço se abrem, e o cartão do expediente sobe com o carimbo "EXPEDIENTE ENCERRADO", tempo, setores, móveis, fichas (os números contam até o valor final), os cinco marcos da partida e a senha com o bilhete. **R** recomeça com outra cifra; **ESC** volta ao andar.
- **Tela de título** e **pausa com controle de volume**.
- **17 efeitos sonoros** e o zumbido de lâmpada fluorescente em loop.
- Cifra e bilhete sorteados a cada partida, então a senha nunca repete.

## A arte

Tudo do mundo do jogo agora é imagem, não retângulo nem desenho por código (a interface, com HUD, pausa e título, continua em retângulos e texto): os 13 tipos de móvel, o boneco com animação (parado, andando, interagindo), a parede, o carpete e as luminárias. Estilo flat minimalista, tudo original, inspirado na estética de escritório estéril da série (paredes brancas, carpete verde-claro, luz fluorescente), sem copiar logo, personagem ou cenário dela.

As imagens ficam em `arte/` e **são trocáveis sem mexer em código**: basta sobrescrever o PNG com o mesmo nome. Veja "Como trocar uma imagem" mais abaixo.

## Tudo é cena

O jogo é montado no editor, com cenas encaixadas umas nas outras. Abra `main.tscn` e a árvore inteira está lá:

```
Jogo (main.tscn)
├─ Cenario     parede e chão (imagens em tile, rolam com o jogador)
├─ Mundo       o setor atual entra aqui quando o jogo roda
├─ Jogador     o boneco animado, parado no centro
├─ HUD         cabeçalho, prompt, aviso, painel (bolso, caderno)
├─ Overlay     a janela dos enigmas (só a moldura)
├─ Mapa        a janela do mapa (tecla M)
├─ Final       a tela de vitória (portas do elevador, cartão, carimbo)
├─ Pausa
├─ Transicao   o fade preto das portas
└─ Titulo
```

## Os arquivos

```
project.godot            configuração e autoloads
main.tscn                a raiz do jogo

arte/
  movel/                 um PNG por tipo de móvel
  jogador/               parado_0..3, andar_0..7, interagir_0..2
  cenario/               parede.png, chao.png, luminaria.png
  fontes/                os desenhos em SVG (para editar no Inkscape/Figma)

cenas/
  cenario/               fundo
  jogador/               o boneco e jogador_frames.tres (as animações)
  movel/                 movel.tscn (base) + uma cena por tipo: porta, quadro,
						 planta, terminal, armario, maquina, colega, cofre,
						 elevador, neutro (caixa de arquivo), vaso, bebedouro,
						 mesa, banco
  setores/               setor_01 ... setor_06 (os móveis posicionados no editor)
						 e luminaria.tscn
  ui/                    hud, mapa (janela) com minimapa (o desenho), caderno_entrada,
						 overlay, final (vitória), transicao (fade), pausa, titulo,
						 forma (um símbolo do terminal), fluxo (a grade)
  paginas/               uma cena por enigma (o conteúdo da janela do Overlay)

scripts/
  estado.gd              autoload: fichas, itens, cifra, caderno, marcos
  audio.gd               autoload: efeitos sonoros
  jogo.gd                corredor circular, interação, troca de setor
  setor.gd               o anel de um setor (distâncias, posicionar, móvel mais perto)
  item_do_anel.gd        tudo que mora no anel (móveis e luminárias)
  movel.gd, porta.gd     comportamento dos móveis
  cenario.gd             rola a parede e o chão
  jogador.gd             escolhe a animação (parado, correr, interagir)
  forma.gd               desenha os símbolos do terminal (sem PNG e sem cor)
  fluxo.gd               a grade de fluxo da última rodada do terminal
  mapa.gd                a janela do mapa (abrir, fechar, textos)
  final.gd               a tela de vitória (linha do tempo da animação, pular, fechar)
  transicao.gd           o fade preto das portas (`duracao` editável no Inspetor)
  minimapa.gd            o desenho do mapa (cartões, corredores, legenda)
  hud.gd, overlay.gd, pausa.gd, titulo.gd
  paginas/               um script por enigma (pagina.gd é a base)

dados/setores.gd         catálogo: lista as cenas dos setores e lê dados delas
```

Os autoloads `Estado` e `Audio` continuam sendo código puro (não têm o que desenhar). `Audio` ainda gera os sons por código.

## Como fazer cada coisa

### Mexer num setor (mover móvel, mudar nome, perímetro)

Abra `cenas/setores/setor_NN.tscn`. A linha **verde** na tela é o anel, e a **vermelha** é onde ele fecha e volta ao 0 (só aparece no editor). Arraste o móvel pelo eixo X (deixe o Y em 0, que é o chão). No nó raiz, o Inspetor tem `Nome`, `Perimetro` e `Posicao Mapa` (onde o cartão do setor fica no mapa, em **colunas e linhas**: `(0, 0)` é o canto de cima à esquerda, `(1, 0)` é o cartão ao lado, `(0, 1)` é o de baixo). O mapa se centraliza sozinho e, se tiver muitos setores, diminui para caber.

### Criar um móvel num setor

Arraste `cenas/movel/<tipo>.tscn` para dentro do setor e preencha `Rotulo` no Inspetor. Se for uma **porta**, preencha também `Destino` (número do setor para onde ela leva) e, se precisar de chave, marque `Exige Chave`.

### Criar um tipo de móvel novo

Em `cenas/movel/`, clique com o botão direito em `movel.tscn` -> **Nova cena herdada**. No nó `Imagem`, arraste o PNG novo para o campo `Texture` e acerte o `Offset` (veja abaixo). Aponte o campo `Pagina` para a tela que ele abre.

### Como trocar uma imagem

Sobrescreva o PNG de `arte/` com o mesmo nome e abra o Godot. Só isso.

Regras para o desenho novo:

- **O PNG termina nos pés.** A borda de baixo da imagem é o chão. Sem folga embaixo.
- **O jogo mostra cada PNG a 50%** (`Scale` 0.5 no nó), então o arquivo tem o dobro do tamanho que aparece. Isso deixa nítido em tela grande. Mantendo o mesmo tamanho em pixels do arquivo atual, nada mais precisa mudar.
- Se o PNG novo tiver **outra altura**, ajuste `Offset` Y do nó `Imagem` (ou `Sprite`, no jogador) para **menos metade da altura do PNG**. Exemplo: PNG de 300 px de altura -> `Offset` = (0, -150). É isso que mantém o pé no chão.
- Coisa pendurada na parede (quadro, planta de evacuação) é um PNG alto com espaço transparente até o chão, para o pé ficar na origem como os outros.
- Parede e chão se repetem a cada 100 px na horizontal. O desenho novo precisa **emendar nas bordas esquerda e direita**.

| Arquivo | Tamanho do PNG | Na tela |
|---|---|---|
| `movel/porta.png` | 288 x 424 | 144 x 212 |
| `movel/elevador.png` | 328 x 464 | 164 x 232 |
| `movel/armario.png` | 232 x 376 | 116 x 188 |
| `movel/maquina.png` | 256 x 388 | 128 x 194 |
| `movel/terminal.png` | 288 x 284 | 144 x 142 |
| `movel/cofre.png` | 248 x 212 | 124 x 106 |
| `movel/quadro.png` | 320 x 440 | 160 x 220 |
| `movel/planta.png` | 280 x 432 | 140 x 216 |
| `movel/neutro.png` (caixa de arquivo) | 184 x 140 | 92 x 70 |
| `movel/vaso.png` | 200 x 260 | 100 x 130 |
| `movel/bebedouro.png` | 144 x 272 | 72 x 136 |
| `movel/mesa.png` | 336 x 212 | 168 x 106 |
| `movel/banco.png` | 312 x 100 | 156 x 50 |
| `movel/colega.png` | 232 x 264 | 116 x 132 |
| `jogador/*.png` (23 quadros: parado 4, andar 8, correr 8, interagir 3) | 232 x 264 | 116 x 132 |
| `cenario/parede.png` | 200 x 940 | 100 x 470 |
| `cenario/chao.png` | 200 x 356 | 100 x 178 |
| `cenario/luminaria.png` | 400 x 388 | 200 x 194 |

O número da porta é um `Label` em cima da plaquetinha branca do desenho (`porta.png`). Se trocarem a porta, deixem a plaquetinha no mesmo lugar ou movam o nó `Numero`.

### Trocar ou acrescentar quadros da animação do jogador

As animações estão em `cenas/jogador/jogador_frames.tres`. Dê dois cliques nele: o painel SpriteFrames do Godot abre, e dá para arrastar quadros novos, mudar a velocidade (FPS) e a ordem. Hoje: `parado` (4 quadros, 4 FPS), `correr` (8 quadros, 14 FPS) e `interagir` (3 quadros, 10 FPS, toca uma vez). A `andar` (8 quadros, 11 FPS) continua no arquivo mas o jogo não usa mais: existe uma velocidade só, e ela é de corrida. O boneco olha para a direita; para a esquerda o Godot espelha sozinho.

Para editar a arte em si, os SVGs de origem estão em `arte/fontes/` (a pasta é ignorada pelo Godot).

### Criar um setor novo

Duplique um `setor_NN.tscn`, renomeie, ajuste os móveis e as portas. Escolha uma célula livre em `Posicao Mapa` para ele aparecer no mapa. Depois acrescente a linha dele em `CENAS` no `dados/setores.gd`.

### Criar um enigma novo

1. Em `cenas/paginas/`, crie uma cena com raiz **VBoxContainer** e um script que começa com `extends Pagina`.
2. Monte labels e botões no editor. Para o que acontece quando a página abre, escreva `ao_abrir()`.
3. No móvel que deve abri-la, aponte o campo `Pagina` para essa cena.

O título da janela vem do campo `Titulo` da página. Se ficar vazio, usa o rótulo do móvel.

### Tabela rápida

| Quero... | Vou em |
|---|---|
| mover um móvel, mudar perímetro de setor | `cenas/setores/setor_NN.tscn` |
| trocar a imagem de um móvel | sobrescrever o PNG em `arte/movel/` (ver "Como trocar uma imagem") |
| mexer nas animações do boneco | `cenas/jogador/jogador_frames.tres` |
| trocar parede, chão ou luminária | `arte/cenario/` |
| mudar o texto ou o layout de um enigma | a cena em `cenas/paginas/` |
| mexer nos símbolos do terminal (famílias de regra, dificuldade) | `DEGRAUS` e as `_familia_*` em `scripts/paginas/pagina_terminal.gd` |
| mudar como um símbolo é desenhado | `scripts/forma.gd` |
| mudar a lógica de um enigma | o script em `scripts/paginas/` |
| mudar preço, prêmio ou cota | `scripts/estado.gd` |
| mudar o tamanho da grade de fluxo ou o número de pares | `Colunas`, `Linhas` e `Pares` no nó Fluxo (`cenas/ui/fluxo.tscn`) |
| mudar velocidade ou raio de interação | constantes no topo de `scripts/jogo.gd` |
| mexer no visual do mapa (cores, tamanho dos cartões, legenda) | `scripts/minimapa.gd` (constantes no topo) e `cenas/ui/mapa.tscn` (a moldura) |
| mudar onde um setor aparece no mapa | `Posicao Mapa` na cena do setor |
| mudar o tempo do fade das portas | `Duracao` no nó raiz de `cenas/ui/transicao.tscn` |
| mudar o visual da tela de vitória (cores, textos, tamanhos) | `cenas/ui/final.tscn` |
| mudar o ritmo da animação da vitória (quando cada coisa aparece) | `abrir()` em `scripts/final.gd` (os números são os atrasos, em segundos) |
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

O perímetro de cada setor está no nó raiz da cena do setor. A 256 px/s, o setor 01 (3000 px) dá uma volta em ~12 segundos, que é o alvo do GDD.

**Atenção ao criar setor novo:** a parede e o chão são tiles de 100 px (`PERIODO` em `scripts/cenario.gd`). O perímetro do setor precisa ser **múltiplo de 100** (hoje: 1900, 2100, 2200, 2400 e 3000). Se não for, o fundo dá um pulinho quando a volta fecha.

## Fade das portas e tela de vitória

**Fade.** `Jogo._atravessar()` pede ao nó `Transicao` para escurecer; no meio, com a tela preta, ele chama `entrar_no_setor()`. Isso faz parecer que você saiu por uma porta e entrou em outra. Enquanto `Transicao.ativa` é verdadeiro, `jogo.gd` ignora andar, E, M e ESC. O som `porta_passagem` toca junto (trinco no início e a batida da porta justo depois do preto total).

**Vitória.** Quando o enigma do elevador fecha, `Jogo` chama `Final.abrir()`. O `final.gd` lê tudo de `Estado` (tempo, setores visitados, móveis examinados, fichas, marcos, senha, bilhete) e monta uma linha do tempo de ~5 s com Tweens: ding do elevador, portas abrindo, cartão, carimbo, contagem dos números, marcos um a um e a senha. Dá para pular com E, ESC ou ENTER. O `R` pede para recomeçar (o sinal `reiniciar_pedido` está ligado em `main.tscn`, igual ao da pausa).

## O terminal de formas

O terminal do setor 02 era cinco regras de aritmética (quadrados, múltiplos de 5, pares, primos, múltiplos de 3), e o enunciado entregava a regra de bandeja ("Três são primos"). Isso testava escolaridade, não percepção, e contradizia a própria dica da tela.

Hoje são **sete famílias de forma**, em três degraus de dificuldade (`DEGRAUS` no topo de `scripts/paginas/pagina_terminal.gd`):

| Família | A regra | Degrau |
|---|---|---|
| `lados` | três polígonos de n lados, um de m | 1 |
| `marcas` | mesma figura, contagem de pontos diferente | 1 |
| `textura` | mesma figura, acabamento diferente (vazado, cheio, hachurado) | 1 e 2 |
| `irregular` | três polígonos regulares, um com um vértice afundado | 2 |
| `modelo` | "ache o igual ao modelo"; os outros erram um atributo cada | 2 |
| `espelhado` | três giros do mesmo glifo assimétrico, e um reflexo dele | 3 |
| `relacao` | em três delas o número de pontos é igual ao de lados, numa não | 3 |

Duas regras valem para todas:

- **Nunca há cor.** O que separa as figuras é lado, giro, reflexo, contagem e textura. A hachura é o "preenchido" que não usa cor.
- **O enunciado nunca diz a regra.** Descobrir a regra é o enigma, que é o que a dica da tela sempre prometeu.

A unicidade da resposta é estrutural: numa rodada, as quatro opções são **idênticas em todos os atributos menos no único que define o intruso**. Dois casos mereceram cuidado:

- Na família `espelhado`, o reflexo sempre repete o giro de um dos três, para que exista um par na mesma orientação — sem esse par o jogador não teria como descobrir que o giro é irrelevante.
- Na família `modelo`, o distrator de rotação gira 45°, não 90°: num quadrado, 90° devolveria o próprio quadrado e haveria duas respostas certas. Nenhum polígono de 3 a 7 lados é simétrico a 45°.

**Do degrau 3 em diante as famílias apertam**: a diferença de lados cai para um só, os pontos passam de cinco (não dá mais para ver a quantidade de relance), o entalhe do `irregular` fica raso, e os distratores do `modelo` erram por um fio.

As figuras não são PNG: `scripts/forma.gd` desenha tudo com `draw_*` a partir de um dicionário (`lados`, `giro`, `espelhado`, `marcas`, `textura`, `irregular`, `afundar`, `glifo`). Para inventar um símbolo novo, acrescente uma chave lá; para inventar uma regra nova, escreva uma `_familia_*` e ponha o nome dela no degrau que quiser.

### A última rodada: a grade de fluxo

A rodada 4 não é de escolher: é **ligar cada par de pontas sem cruzar ninguém e sem deixar célula vazia** (`scripts/fluxo.gd`). Arraste de uma ponta à outra; arrastar de volta por cima do próprio rastro desfaz; passar por cima da trilha de outro par corta ela ali. O botão **Limpar** tira tudo da mesa.

Sem cor aqui também. O que separa um par do outro é o **traço** (cheio, tracejado, pontilhado, vazado) e o **marcador** da ponta (círculo, quadrado, triângulo, losango). São quatro de cada, que é por isso que o máximo é 4 pares.

**Como as cartelas sempre têm solução:** todo caminho que passa uma vez por cada célula (um caminho hamiltoniano), cortado em pedaços, já é uma solução válida que cobre a grade inteira. Então o gerador sorteia um hamiltoniano — começa na serpentina e embaralha com o *backbite*: pega uma ponta, escolhe um vizinho dela que já esteja no caminho e inverte o trecho entre os dois — corta em pedaços de tamanho parecido e esconde o miolo, deixando só as pontas. Os pedaços saem com tamanho parecido de propósito: um corte livre produzia uma cobra de 13 células e três tocos de 3, que é um puzzle chato. Cartelas com as duas pontas de um par encostadas são descartadas.

**Esta rodada não tem resposta errada.** Dá para limpar e tentar à vontade. Isso é de propósito: ver abaixo.

### A cota, e por que ela é o que é

O terminal é a **única** fonte de fichas do jogo, e o sanduíche que compra a chave custa 2. Se o jogador esgotar a cota sem vencer nenhuma partida, o jogo fica impossível de terminar. Por isso, ao dificultar o terminal, duas coisas mudaram junto:

- a cota subiu de 2 para 4 partidas (`COTA_PARTIDAS` em `scripts/estado.gd`);
- a cota conta partidas **encerradas** (vencidas, ou perdidas num erro), não partidas começadas. Fechar a janela no meio de uma rodada não queima nada — você só perde o progresso daquela partida.

Se mexerem na dificuldade, confiram essa conta de novo.

## Sobre o som

Os efeitos são **gerados por código** em `audio.gd`, sem nenhum arquivo de áudio. Isso existe para o jogo ter som agora, não para ficar assim. Quando vocês gravarem ou baixarem os sons de verdade, troquem o corpo de `_criar_sons()` por `load("res://sons/porta.wav")` e o resto continua funcionando igual.

## O que falta para o T2

1. ~~Sprites no lugar dos retângulos~~ e ~~animação do jogador~~: feitos (ver "A arte"). Se a turma quiser arte própria, é sobrescrever os PNGs.
2. **Sons de verdade** no lugar dos gerados.
3. ~~Mais variedade no terminal~~: feito. As cinco regras de aritmética viraram sete famílias de forma (ver "O terminal de formas").
4. **Balanceamento** com gente de fora: velocidade, perímetro, economia.
5. **Salvamento** - só no T3, segundo o próprio GDD.

## Divisão possível entre três

- **Arte e animação:** refinar ou substituir os PNGs de `arte/`, e a tela de título e os painéis (`cenas/ui/`), que ainda são retângulos e texto. Não encosta na lógica.
- **Som e interface:** item 2, mais ajustes de `cenas/ui/` (HUD, mapa, título, pausa).
- **Conteúdo e balanceamento:** itens 3 e 4, mais `cenas/paginas/` e `cenas/setores/`.

Os três tocam pastas diferentes, então dá para trabalhar em paralelo sem conflito. Cena `.tscn` é texto e resolve bem no Git, mas evitem duas pessoas mexendo na **mesma** cena ao mesmo tempo.
