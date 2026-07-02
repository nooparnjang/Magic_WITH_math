extends Node2D

@export var laser_on_time: float = 2.0
@export var laser_off_time: float = 1.0

# Name of the animation inside AnimatedSprite2D
@export var animation_name: StringName = "default"

var laser_enabled := true

@onready var beam: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D
@onready var timer: Timer = $Timer


func _ready():
	timer.timeout.connect(_on_timer_timeout)
	turn_laser_on()


func _on_timer_timeout():
	if laser_enabled:
		turn_laser_off()
	else:
		turn_laser_on()


func turn_laser_on():
	laser_enabled = true

	beam.visible = true
	beam.play(animation_name) # Play animation

	collision.disabled = false

	timer.wait_time = laser_on_time
	timer.start()


func turn_laser_off():
	laser_enabled = false

	beam.stop()
	beam.visible = false

	collision.disabled = true

	timer.wait_time = laser_off_time
	timer.start()


func _on_area_2d_body_entered(body):
	if !laser_enabled:
		return

	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(999)
