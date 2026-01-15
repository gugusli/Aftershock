extends Node2D

@onready var player = $Player
@onready var hud = $HUD

func _ready():
	hud.connect_player(player)
