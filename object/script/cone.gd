extends StaticBody2D

@export var max_hp := 1
var hp := 0

@onready var sprite = $Sprite2D
@export var hit_effect_scene: PackedScene

func _ready() -> void:
	hp = max_hp
	add_to_group("targetable")

func take_damage(amount: int) -> void:
	hp -= amount
	print(name, "โดนดาเมจ", amount, "เหลือ", hp)

	flash_hit()

	if hp <= 0:
		spawn_effect()
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
	
func spawn_effect() -> void:
	if hit_effect_scene == null:
		return
	
	var effect = hit_effect_scene.instantiate()
	get_tree().current_scene.add_child(effect)
	
	effect.global_position = global_position
	effect.z_index = 100
	
	var effect_sprite = effect.get_node_or_null("AnimatedSprite2D")
	if effect_sprite == null:
		push_error("Effect ไม่มี AnimatedSprite2D")
		return
	
	var anim_name = "default"
	
	if not effect_sprite.sprite_frames.has_animation(anim_name):
		push_error("ไม่มี animation: " + anim_name)
		return
	
	# 🔥 ปิด loop
	effect_sprite.sprite_frames.set_animation_loop(anim_name, false)
	
	# 🔥 เล่น animation
	effect_sprite.play(anim_name)
