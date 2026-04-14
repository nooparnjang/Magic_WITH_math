extends StaticBody2D

@export var max_hp := 1
@export var blessing_reward: int = 10
@export var hit_effect_scene: PackedScene
@export var floating_text_scene: PackedScene

var hp := 0
var is_dead := false

@onready var sprite = $Sprite2D

func _ready() -> void:
	hp = max_hp
	add_to_group("targetable")

func take_damage(amount: int) -> void:
	if is_dead:
		return

	hp -= amount
	print(name, "โดนดาเมจ", amount, "เหลือ", hp)

	flash_hit()

	if hp <= 0:
		is_dead = true
		give_blessing()
		show_blessing_popup()
		spawn_effect()
		queue_free()

func give_blessing() -> void:
	BlessingManager.add_blessings(blessing_reward)

func show_blessing_popup() -> void:
	if floating_text_scene == null:
		return

	var popup = floating_text_scene.instantiate()
	get_tree().current_scene.add_child(popup)

	if popup.has_method("show_at"):
		popup.show_at(global_position + Vector2(-40, -98), blessing_reward)

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

	effect_sprite.sprite_frames.set_animation_loop(anim_name, false)
	effect_sprite.play(anim_name)
