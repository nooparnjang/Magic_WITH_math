extends Node2D

@export var lifetime: float = 0.7

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _age: float = 0.0
var _start_alpha: float = 0.7

func setup_from_animated_sprite(source: AnimatedSprite2D, ghost_color: Color) -> void:
	sprite.sprite_frames = source.sprite_frames
	sprite.animation = source.animation
	sprite.frame = source.frame
	sprite.flip_h = source.flip_h
	sprite.flip_v = source.flip_v
	sprite.scale = source.scale
	sprite.rotation = source.rotation

	modulate = ghost_color
	modulate.a = _start_alpha


func _process(delta: float) -> void:
	_age += delta
	var t: float = clamp(_age / lifetime, 0.0, 1.0)
	modulate.a = lerp(_start_alpha, 0.0, t)

	if _age >= lifetime:
		queue_free()
