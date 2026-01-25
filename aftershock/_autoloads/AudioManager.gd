extends Node

# Este nodo manejará la música de fondo
var music_player : AudioStreamPlayer

func _ready() -> void:
	# Configuramos el reproductor de música inicial
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Music" # Opcional: si creas un bus en el Mezclador

# 🎵 Función para poner música de fondo
func play_music(stream: AudioStream, volume := 0.0) -> void:
	if music_player.stream == stream:
		return # No reiniciar si ya está sonando la misma canción
	
	music_player.stream = stream
	music_player.volume_db = volume
	music_player.play()

# 🔊 Función para efectos de sonido (disparos, gemas, etc.)
func play_sfx(stream: AudioStream, volume := 0.0) -> void:
	if stream == null: return
	
	# Creamos un reproductor temporal para que los sonidos puedan solaparse
	var sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	sfx_player.stream = stream
	sfx_player.volume_db = volume
	sfx_player.play()
	
	# Cuando el sonido termine, el reproductor se destruye automáticamente
	sfx_player.finished.connect(sfx_player.queue_free)
