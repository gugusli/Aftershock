extends Node2D
## Evento STAMPEDE: 30-40 enemigos rápidos desde bordes, velocidad +50%

signal event_ended

func activate(_arena: Node2D, _player: Node2D, _wave_manager: Node) -> void:
	push_warning("StampedeEvent: Estampida inminente, spawning corredores desde bordes")
