extends Node2D

@export var ghost_scene: PackedScene
@export var min_speed_for_trail := 10.0
@export var spawn_distance := 80.0

var _last_spawn_position: Vector2
var _color_index := 0

@onready var player := get_parent()
@onready var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")

var neon_colors := [
	Color(1.0, 0.2, 0.8),
	Color(0.2, 1.0, 1.0),
	Color(0.4, 1.0, 0.3),
	Color(1.0, 0.9, 0.2),
	Color(0.7, 0.3, 1.0)
]

func _ready() -> void:
	_last_spawn_position = player.global_position


func _process(delta: float) -> void:
	if player is CharacterBody2D:
		if player.velocity.length() < min_speed_for_trail:
			_last_spawn_position = player.global_position
			return

	var distance_since_last : float = player.global_position.distance_to(_last_spawn_position)

	if distance_since_last >= spawn_distance:
		_spawn_ghost()
		_last_spawn_position = player.global_position


func _spawn_ghost() -> void:
	if ghost_scene == null:
		return

	var ghost = ghost_scene.instantiate()
	get_tree().current_scene.add_child(ghost)

	ghost.global_position = player.global_position
	ghost.global_rotation = player.global_rotation
	ghost.global_scale = player.global_scale

	var ghost_color = neon_colors[_color_index]
	_color_index = (_color_index + 1) % neon_colors.size()

	ghost.setup_from_animated_sprite(sprite, ghost_color)
