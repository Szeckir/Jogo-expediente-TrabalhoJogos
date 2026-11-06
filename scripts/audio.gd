extends Node

# Gerenciador de audio. Os efeitos sao gerados por codigo, sem arquivo
# de som: da para ouvir o jogo inteiro antes de existir qualquer .wav.
# Quando o grupo gravar ou baixar os sons de verdade, e so trocar o
# conteudo de _criar_sons() por load() dos arquivos.

const TAXA := 22050.0

var volume := 0.6:
	set(v):
		volume = clampf(v, 0.0, 1.0)
		_aplicar_volume()

var _sons := {}
var _vozes: Array = []
var _proxima := 0
var _ambiente: AudioStreamPlayer


func _ready() -> void:
	_criar_sons()

	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_vozes.append(p)

	_ambiente = AudioStreamPlayer.new()
	add_child(_ambiente)
	_ambiente.stream = _sons["ambiente"]
	_ambiente.play()
	_aplicar_volume()


func tocar(nome: String) -> void:
	if not _sons.has(nome) or volume <= 0.0:
		return
	var p: AudioStreamPlayer = _vozes[_proxima]
	_proxima = (_proxima + 1) % _vozes.size()
	p.stream = _sons[nome]
	p.volume_db = linear_to_db(volume)
	p.play()


func _aplicar_volume() -> void:
	if is_instance_valid(_ambiente):
		# o zumbido da lampada fica bem abaixo dos efeitos
		_ambiente.volume_db = linear_to_db(volume * 0.18) if volume > 0.0 else -80.0


# ------------------------------------------------------- geracao

func _criar_sons() -> void:
	_sons["passo"] = _wav(_ruido(0.05, 0.22, 14.0))
	_sons["porta_abrir"] = _wav(_varredura(420.0, 150.0, 0.30, 0.30, 5.0))
	_sons["porta_travada"] = _mix(_varredura(120.0, 90.0, 0.14, 0.40, 16.0), _ruido(0.06, 0.18, 30.0))
	_sons["overlay_abrir"] = _wav(_varredura(320.0, 620.0, 0.09, 0.22, 12.0))
	_sons["overlay_fechar"] = _wav(_varredura(620.0, 300.0, 0.09, 0.22, 12.0))
	_sons["tecla"] = _wav(_varredura(880.0, 880.0, 0.04, 0.25, 30.0))
	_sons["aceito"] = _wav(_juntar([_varredura(660.0, 660.0, 0.08, 0.25, 14.0), _varredura(990.0, 990.0, 0.12, 0.25, 10.0)]))
	_sons["recusado"] = _wav(_varredura(180.0, 130.0, 0.22, 0.30, 7.0))
	_sons["ficha"] = _wav(_juntar([_varredura(1300.0, 1100.0, 0.05, 0.20, 26.0), _varredura(950.0, 800.0, 0.06, 0.18, 22.0)]))
	_sons["anotar"] = _wav(_ruido(0.11, 0.10, 9.0))
	_sons["cracha_aprovado"] = _wav(_juntar([_varredura(700.0, 700.0, 0.10, 0.26, 12.0), _varredura(1400.0, 1400.0, 0.18, 0.26, 8.0)]))
	_sons["cracha_negado"] = _wav(_juntar([_varredura(220.0, 220.0, 0.12, 0.28, 10.0), _varredura(150.0, 150.0, 0.20, 0.28, 8.0)]))
	_sons["elevador"] = _wav(_varredura(90.0, 320.0, 0.80, 0.24, 1.6))
	_sons["porta_passagem"] = _wav(_passagem_de_porta())
	_sons["elevador_ding"] = _wav(_camadas([
		[_sino(988.0, 0.90, 0.30, 4.5), 0.0],
		[_sino(740.0, 1.10, 0.30, 4.0), 0.42]]))
	_sons["carimbo"] = _wav(_carimbo())
	_sons["vitoria"] = _wav(_camadas([
		[_sino(523.0, 0.9, 0.17, 4.0), 0.0],
		[_sino(659.0, 0.9, 0.17, 4.0), 0.16],
		[_sino(784.0, 0.9, 0.17, 4.0), 0.32],
		[_sino(1047.0, 1.4, 0.19, 3.4), 0.48]]))
	_sons["ambiente"] = _wav(_zumbido(2.0), true)


# Passar por uma porta, em ~0,55 s: trinco, rangido com o vento do corredor
# e a porta batendo do outro lado (casa com o fade preto de 0,5 s).
func _passagem_de_porta() -> PackedFloat32Array:
	var trinco := _camadas([
		[_ruido(0.012, 0.40, 6.0), 0.0],
		[_varredura(240.0, 150.0, 0.07, 0.34, 9.0), 0.0],
		[_varredura(130.0, 90.0, 0.05, 0.22, 10.0), 0.045]])
	# vento: ruido passado por um filtro de uma polo, com envelope em sino
	var vento := _filtro(_ruido(0.30, 1.0, 0.0), 0.10)
	for i in vento.size():
		var t := float(i) / vento.size()
		vento[i] *= sin(PI * t) * 0.85
	# rangido: tom que sobe devagar com tremor rapido
	var n := int(0.26 * TAXA)
	var rangido := PackedFloat32Array()
	rangido.resize(n)
	var fase := 0.0
	for i in n:
		var t := float(i) / n
		fase += TAU * lerpf(150.0, 235.0, t) / TAXA
		var tremor := 0.55 + 0.45 * sin(TAU * 34.0 * float(i) / TAXA)
		var onda := sin(fase) + 0.5 * sin(2.0 * fase) + 0.3 * sin(3.0 * fase)
		rangido[i] = onda * tremor * sin(PI * t) * 0.07
	var batida := _camadas([
		[_varredura(110.0, 48.0, 0.20, 0.52, 7.0), 0.0],
		[_filtro(_ruido(0.09, 0.9, 12.0), 0.20), 0.0]])
	return _camadas([[trinco, 0.0], [vento, 0.04], [rangido, 0.05], [batida, 0.33]])


# Carimbo batendo no papel: pancada grave e o estalo do papel.
func _carimbo() -> PackedFloat32Array:
	return _camadas([
		[_varredura(150.0, 55.0, 0.16, 0.60, 8.0), 0.0],
		[_filtro(_ruido(0.07, 1.0, 10.0), 0.35), 0.0],
		[_ruido(0.025, 0.25, 8.0), 0.0]])


# Sino de elevador: fundamental mais parciais inarmonicas.
func _sino(freq: float, dur: float, vol: float, queda: float) -> PackedFloat32Array:
	var n := int(dur * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(n)
	for i in n:
		var t := float(i) / TAXA
		var env: float = exp(-queda * float(i) / n) * minf(1.0, float(i) / 40.0)
		var v := sin(TAU * freq * t)
		v += 0.38 * sin(TAU * freq * 2.76 * t) * exp(-3.0 * t)
		v += 0.16 * sin(TAU * freq * 5.4 * t) * exp(-6.0 * t)
		saida[i] = v * env * vol * 0.7
	return saida


# Filtro passa-baixa de um polo (a pequeno = mais abafado).
func _filtro(x: PackedFloat32Array, a: float) -> PackedFloat32Array:
	var y := x.duplicate()
	var acc := 0.0
	for i in y.size():
		acc += a * (x[i] - acc)
		y[i] = acc
	return y


# Soma varias partes, cada uma com seu atraso em segundos: [[amostras, atraso], ...]
func _camadas(partes: Array) -> PackedFloat32Array:
	var total := 0
	for p in partes:
		total = maxi(total, int(float(p[1]) * TAXA) + (p[0] as PackedFloat32Array).size())
	var saida := PackedFloat32Array()
	saida.resize(total)
	for p in partes:
		var base := int(float(p[1]) * TAXA)
		var amostras: PackedFloat32Array = p[0]
		for i in amostras.size():
			saida[base + i] += amostras[i]
	return saida


# Uma varredura de frequencia com queda exponencial de volume.
func _varredura(f0: float, f1: float, dur: float, vol: float, queda: float) -> PackedFloat32Array:
	var n := int(dur * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(n)
	var fase := 0.0
	for i in n:
		var t := float(i) / n
		var freq: float = lerpf(f0, f1, t)
		fase += TAU * freq / TAXA
		var env: float = exp(-queda * t) * minf(1.0, float(i) / 80.0)
		saida[i] = sin(fase) * env * vol
	return saida


func _ruido(dur: float, vol: float, queda: float) -> PackedFloat32Array:
	var n := int(dur * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(n)
	for i in n:
		var t := float(i) / n
		saida[i] = (randf() * 2.0 - 1.0) * exp(-queda * t) * vol
	return saida


# Zumbido de lampada fluorescente: harmonicas da rede mais um chiado.
func _zumbido(dur: float) -> PackedFloat32Array:
	var n := int(dur * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(n)
	for i in n:
		var t := float(i) / TAXA
		var v := sin(TAU * 120.0 * t) * 0.5
		v += sin(TAU * 240.0 * t) * 0.22
		v += sin(TAU * 60.0 * t) * 0.14
		v += (randf() * 2.0 - 1.0) * 0.05
		saida[i] = v * 0.5
	# tira o estalo da emenda do loop
	var rampa := int(TAXA * 0.01)
	for i in rampa:
		var f := float(i) / rampa
		saida[i] *= f
		saida[n - 1 - i] *= f
	return saida


func _juntar(partes: Array) -> PackedFloat32Array:
	var saida := PackedFloat32Array()
	for p in partes:
		saida.append_array(p)
	return saida


func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> AudioStreamWAV:
	var n: int = maxi(a.size(), b.size())
	var saida := PackedFloat32Array()
	saida.resize(n)
	for i in n:
		var v := 0.0
		if i < a.size():
			v += a[i]
		if i < b.size():
			v += b[i]
		saida[i] = clampf(v, -1.0, 1.0)
	return _wav(saida)


func _wav(amostras: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(amostras.size() * 2)
	for i in amostras.size():
		bytes.encode_s16(i * 2, int(clampf(amostras[i], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = int(TAXA)
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = amostras.size()
	return s
