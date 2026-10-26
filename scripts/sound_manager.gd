class_name SoundManager
extends Node

## Generador procedural de efectos de sonido retro (8/16 bits) usando AudioStreamWAV en memoria.

static var instance: SoundManager

var _pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0
const POOL_SIZE := 8

var sfx_eye_collected: AudioStreamWAV
var sfx_hurt: AudioStreamWAV
var sfx_radar: AudioStreamWAV
var sfx_game_over: AudioStreamWAV
var sfx_victory: AudioStreamWAV
var sfx_whisper: AudioStreamWAV

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_pool.append(player)
		
	_generate_all_sfx()

func _generate_all_sfx() -> void:
	sfx_eye_collected = _create_arpeggio([523.25, 659.25, 783.99, 987.77, 1046.50, 1318.51], 0.07, 0.45)
	sfx_hurt = _create_hit_sound(0.3)
	sfx_radar = _create_sine_pulse(180.0, 0.12)
	sfx_game_over = _create_arpeggio([440.0, 392.0, 349.23, 293.66, 261.63], 0.16, 0.5)
	sfx_victory = _create_victory_fanfare()
	sfx_whisper = _create_ghost_whisper(0.4)

func play_sfx(stream: AudioStreamWAV, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if stream == null or _pool.is_empty():
		return
	var player := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

func play_eye() -> void:
	play_sfx(sfx_eye_collected, 2.0, 1.0)

func play_damage() -> void:
	play_sfx(sfx_hurt, 3.0, randf_range(0.9, 1.1))

func play_radar(distance_factor: float = 1.0) -> void:
	# distance_factor entre 0 (muy cerca) y 1 (lejos)
	var pitch := lerpf(1.6, 0.9, clampf(distance_factor, 0.0, 1.0))
	play_sfx(sfx_radar, -3.0, pitch)

func play_win() -> void:
	play_sfx(sfx_victory, 3.0, 1.0)

func play_defeat() -> void:
	play_sfx(sfx_game_over, 2.0, 1.0)

func play_ghost() -> void:
	play_sfx(sfx_whisper, -4.0, randf_range(0.85, 1.15))

# --- Sintetizadores Procedurales ---

func _create_arpeggio(freqs: Array, note_duration: float, max_amplitude: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var total_duration: float = note_duration * float(freqs.size())
	var total_samples: int = int(total_duration * float(mix_rate))
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	var sample_idx: int = 0
	for note_idx in range(freqs.size()):
		var freq: float = freqs[note_idx]
		var note_samples: int = int(note_duration * float(mix_rate))
		for i in range(note_samples):
			if sample_idx >= total_samples:
				break
			var t: float = float(i) / float(mix_rate)
			var progress: float = float(i) / float(note_samples)
			
			# Onda cuadrada suave / pulse wave retro
			var phase: float = fmod(t * freq, 1.0)
			var wave: float = 0.7 if phase < 0.45 else -0.7
			
			# Envolvente decaimiento exponencial
			var env: float = pow(1.0 - progress, 1.6) * max_amplitude
			var sample_val: int = int(clampf(wave * env, -1.0, 1.0) * 32767.0)
			
			byte_array.encode_s16(sample_idx * 2, sample_val)
			sample_idx += 1
			
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = byte_array
	return wav

func _create_hit_sound(duration: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var total_samples: int = int(duration * float(mix_rate))
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var progress: float = float(i) / float(total_samples)
		var t: float = float(i) / float(mix_rate)
		
		# Ruido blanco + caída de frecuencia baja
		var noise: float = randf_range(-1.0, 1.0)
		var bass_freq: float = lerpf(120.0, 40.0, progress)
		var bass: float = sin(t * bass_freq * TAU)
		
		var mixed: float = (noise * 0.6 + bass * 0.4)
		var env: float = pow(1.0 - progress, 2.2) * 0.75
		var sample_val: int = int(clampf(mixed * env, -1.0, 1.0) * 32767.0)
		
		byte_array.encode_s16(i * 2, sample_val)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = byte_array
	return wav

func _create_sine_pulse(base_freq: float, duration: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var total_samples: int = int(duration * float(mix_rate))
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var progress: float = float(i) / float(total_samples)
		var t: float = float(i) / float(mix_rate)
		var freq: float = lerpf(base_freq * 1.5, base_freq, progress)
		var wave: float = sin(t * freq * TAU)
		
		# Atenuación percusiva
		var env: float = sin(progress * PI) * pow(1.0 - progress, 1.2) * 0.6
		var sample_val: int = int(clampf(wave * env, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, sample_val)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = byte_array
	return wav

func _create_victory_fanfare() -> AudioStreamWAV:
	var notes := [523.25, 659.25, 783.99, 1046.50, 783.99, 1046.50, 1318.51]
	var durations := [0.12, 0.12, 0.12, 0.22, 0.1, 0.15, 0.45]
	var mix_rate: int = 22050
	
	var total_dur: float = 0.0
	for d in durations:
		total_dur += float(d)
	var total_samples: int = int(total_dur * float(mix_rate))
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	var sample_idx: int = 0
	for idx in range(notes.size()):
		var freq: float = notes[idx]
		var dur: float = durations[idx]
		var note_samples: int = int(dur * float(mix_rate))
		
		for i in range(note_samples):
			if sample_idx >= total_samples:
				break
			var t: float = float(i) / float(mix_rate)
			var progress: float = float(i) / float(note_samples)
			
			var phase: float = fmod(t * freq, 1.0)
			# Mezcla de onda triangular y cuadrada retro
			var tri: float = 2.0 * absf(2.0 * phase - 1.0) - 1.0
			var sqr: float = 0.6 if phase < 0.5 else -0.6
			var wave: float = tri * 0.7 + sqr * 0.3
			
			var env: float = (1.0 - progress * 0.5) * 0.65
			var sample_val: int = int(clampf(wave * env, -1.0, 1.0) * 32767.0)
			byte_array.encode_s16(sample_idx * 2, sample_val)
			sample_idx += 1
			
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = byte_array
	return wav

func _create_ghost_whisper(duration: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var total_samples: int = int(duration * float(mix_rate))
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	var filter_val: float = 0.0
	for i in range(total_samples):
		var progress: float = float(i) / float(total_samples)
		var raw_noise: float = randf_range(-1.0, 1.0)
		# Filtro pasa-bajos simple
		filter_val += (raw_noise - filter_val) * 0.12
		
		var env: float = sin(progress * PI) * 0.4
		var sample_val: int = int(clampf(filter_val * env, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, sample_val)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = byte_array
	return wav
