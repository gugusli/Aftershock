extends Node2D
## Evento ARTILLERY_RAIN: 5-8 artilleros fijos, barraje constante. Duración ~45s.

signal event_ended

func activate(_arena: Node2D, _player: Node2D, _wave_manager: Node) -> void:
	push_warning("ArtilleryRainEvent: Lluvia de artillería activada")
