extends Node2D
## Evento KING_OF_HILL: Zona circular en centro, jugador debe permanecer 30s. Recompensa: 3 mejoras raras.

signal event_ended

func activate(_arena: Node2D, _player: Node2D, _wave_manager: Node) -> void:
	push_warning("KingOfHillEvent: Rey de la colina activado, mantente en la zona 30s")
