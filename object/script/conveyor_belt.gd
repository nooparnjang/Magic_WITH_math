extends StaticBody2D

@export var conveyor_speed: float = 120.0
@export var move_right := true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: CharacterBody2D = null


func _ready():
	sprite.play()


func _physics_process(delta):
	if player == null:
		return

	var direction = 1

	if !move_right:
		direction = -1

	player.global_position.x += direction * conveyor_speed * delta


func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player = body


func _on_area_2d_body_exited(body):
	if body == player:
		player = null
