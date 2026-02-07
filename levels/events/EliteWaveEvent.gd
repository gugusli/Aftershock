extends Node2D
## Evento ELITE_WAVE: Solo 3-5 enemigos, todos élites (3x HP, 1.5x daño). Drop garantizado.

signal event_ended

func activate(_arena: Node2D, _player: Node2D, _wave_manager: Node) -> void:
	push_warning("EliteWaveEvent: Oleada de élite activada")
