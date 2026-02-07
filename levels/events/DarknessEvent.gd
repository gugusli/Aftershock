extends Node2D
## Evento TOTAL_DARKNESS: Visibilidad 50%, enemigos invisibles hasta cerca. Duración 40s.

signal event_ended

func activate(_arena: Node2D, _player: Node2D, _wave_manager: Node) -> void:
	push_warning("DarknessEvent: Oscuridad total activada, visibilidad reducida")
