extends Node2D
## Evento CHAOS_DUPLICATION: Cada enemigo al morir spawns 2 clones (30% HP). Implementado en WaveManager._on_enemy_died

signal event_ended

func activate(_arena: Node2D, _player: Node2D, _wave_manager: Node) -> void:
	push_warning("ChaosEvent: Duplicación caótica activada")
