extends Node2D

# Límites del mundo (en píxeles). El jugador se restringe a este rectángulo.
@export var world_limit_min := Vector2(-1800, -1000)
@export var world_limit_max := Vector2(1800, 1000)

# Si true, se rellena el suelo con tiles de assets/map al iniciar (amplía el fondo).
@export var fill_floor_on_ready := true

@onready var player = $Player
@onready var hud = $HUD

func _ready() -> void:
	hud.connect_player(player)
	add_to_group("world_border")
	if fill_floor_on_ready:
		_fill_floor_with_map_tiles()# Rellena el TileMapLayer con tiles del tileset de assets/map para el fondo.
# Usa varios atlas_coords del tileset para dar variedad al suelo.
func _fill_floor_with_map_tiles() -> void:
	var layer = get_node_or_null("TileMapLayer")
	if not layer or not layer.tile_set:
		return
	if layer.tile_set.get_source_count() == 0:
		return
	var source_id: int = layer.tile_set.get_source_id(0)
	# Variación de suelo: tiles del atlas (0,0), (1,0), (0,1), (2,0), (1,1)
	var atlas_variants: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 0), Vector2i(1, 1)
	]
	# Área: ±100 en X y ±60 en Y (aprox. 3200×1920 px con tiles 16×16)
	for tx in range(-100, 100):
		for ty in range(-60, 60):
			var idx: int = (tx + ty) % atlas_variants.size()
			if idx < 0:
				idx += atlas_variants.size()
			var atlas: Vector2i = atlas_variants[idx]
			layer.set_cell(Vector2i(tx, ty), source_id, atlas, 0)
