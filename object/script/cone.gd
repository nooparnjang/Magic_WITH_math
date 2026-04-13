extends StaticBody2D

@export var max_hp := 1
var hp := 0

@onready var sprite = $Sprite2D

func _ready() -> void:
	hp = max_hp
	add_to_group("targetable")

func take_damage(amount: int) -> void:
	hp -= amount
	print(name, "โดนดาเมจ", amount, "เหลือ", hp)

	flash_hit()

	if hp <= 0:
		queue_free()

func set_selected(value: bool) -> void:
	if value:
		sprite.modulate = Color(1.3, 1.3, 0.7)
	else:
		sprite.modulate = Color(1, 1, 1)

func flash_hit() -> void:
	sprite.modulate = Color(1.8, 0.7, 0.7)
	await get_tree().create_timer(0.08).timeout
	sprite.modulate = Color(1, 1, 1)
