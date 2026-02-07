extends Node

# Este nodo manejará la música de fondo
var music_player : AudioStreamPlayer
var _music_loop_stream : AudioStream

func _ready() -> void:
	# Configuramos el reproductor de música inicial
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Music" # Opcional: si creas un bus en el Mezclador
	music_player.finished.connect(_on_music_finished)

# 🎵 Función para poner música de fondo (con loop automático)
func play_music(stream: AudioStream, volume := 0.0) -> void:
	if stream == null:
		return
	if not music_player:
		push_error("AudioManager: music_player no inicializado")
		return
	if music_player.stream == stream and music_player.playing:
		return
	_music_loop_stream = stream
	music_player.stream = stream
	_refresh_music_volume_db(volume)
	music_player.play()

func _refresh_music_volume_db(base_db: float = 0.0) -> void:
	if not music_player:
		return
	var mult := 1.0
	if GameManager:
		mult = GameManager.settings.get("master_volume", 1.0) * GameManager.settings.get("music_volume", 0.7)
	music_player.volume_db = base_db + (20.0 * log(mult) / log(10.0) if mult > 0.001 else -80.0)

func refresh_volumes_from_settings() -> void:
	if not music_player:
		return
	var base := -8.0 if music_player.stream == MENU_MUSIC else 0.0
	_refresh_music_volume_db(base)

func _on_music_finished() -> void:
	if music_player and _music_loop_stream != null and music_player.stream == _music_loop_stream:
		music_player.play()

# 🎵 Música del menú principal (Sci-Fi 1 Loop)
const MENU_MUSIC := preload("res://assets/audio/Sci-Fi 1 Loop.wav")

func play_menu_music(volume := -8.0) -> void:
	play_music(MENU_MUSIC, volume)

func stop_music() -> void:
	_music_loop_stream = null
	if music_player:
		music_player.stop()

# 🔊 Función para efectos de sonido (disparos, gemas, etc.)
func play_sfx(stream: AudioStream, volume := 0.0) -> void:
	if stream == null:
		return
	var mult := 1.0
	if GameManager:
		mult = GameManager.settings.get("master_volume", 1.0) * GameManager.settings.get("sfx_volume", 1.0)
	var vol_db := volume + (20.0 * log(mult) / log(10.0) if mult > 0.001 else -80.0)
	var sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	sfx_player.stream = stream
	sfx_player.volume_db = vol_db
	sfx_player.play()
	
	# Cuando el sonido termine, el reproductor se destruye automáticamente
	sfx_player.finished.connect(sfx_player.queue_free)

# =========================
# Sonidos UI mapeados por clave (usa clips cortos; Sci-Fi 1 Loop es solo música)
# =========================
const UI_SOUNDS := {
	"ui_confirm": null  # Añadir preload("res://assets/audio/click.wav") cuando exista el asset
}

# Reproduce un efecto de UI por clave (usa play_sfx internamente)
func play_ui(sound_name: String, volume := 0.0) -> void:
	var stream: AudioStream = UI_SOUNDS.get(sound_name, null)
	if stream == null:
		return
	play_sfx(stream, volume)
