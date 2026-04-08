extends CharacterBody2D

@export var speed := 300.0
@export var jump_velocity := -750.0
@export var gravity := 1200.0

@onready var sprite = $AnimatedSprite2D

func _physics_process(delta):
	var direction = Input.get_axis("ui_left", "ui_right")

	# เดินซ้ายขวา
	velocity.x = direction * speed

	# ใส่แรงโน้มถ่วงตอนลอยอยู่
	if not is_on_floor():
		velocity.y += gravity * delta

	# กระโดด
	if Input.is_action_just_pressed("ui_accept")  and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	# animation
	if not is_on_floor():
		sprite.play("jump")
	elif direction == 0:
		sprite.play("idle")
	else:
		sprite.play("walk")
		sprite.flip_h = direction < 0
