extends StaticBody2D

@export var max_hp := 1
@export var blessing_reward: int = 10

@export var hit_effect_scene: PackedScene = preload("res://effect/PoofEffect.tscn")
@export var floating_text_scene: PackedScene = preload("res://UIcomponent/FloatingBlessingText.tscn")

@export_enum("3 digits with 1 digit", "2 digits with 1 digit", "1 digit with 1 digit")
var question_pattern := 2

@export var allowed_operators: Array[String] = ["+"]

@export_enum("none", "blessings", "item", "both")
var drop_type := 1

@export var item_drop_scene: PackedScene
@export var item_drop_count: int = 1

@export var randomize_drop := false
@export_range(0.0, 1.0, 0.01) var blessing_drop_chance := 1.0
@export_range(0.0, 1.0, 0.01) var item_drop_chance := 1.0

# ข้อมูลไอเทมที่ดรอป
@export var item_drop_id: String = "coin"
@export var item_drop_amount: int = 1
@export var item_drop_texture: Texture2D

var hp := 0
var is_dead := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var body_collision: CollisionShape2D = get_node_or_null("CollisionShape2D")


func _ready() -> void:
	randomize()
	hp = max_hp
	add_to_group("targetable")


func take_damage(amount: int) -> void:
	if is_dead:
		return

	hp -= amount
	print(name, "โดนดาเมจ", amount, "เหลือ", hp)

	flash_hit()

	if hp <= 0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	remove_from_group("targetable")

	if body_collision != null:
		body_collision.disabled = true

	handle_drops()
	spawn_effect()
	queue_free()


func handle_drops() -> void:
	match drop_type:
		0:
			pass
		1:
			try_drop_blessing()
		2:
			try_drop_item()
		3:
			try_drop_blessing()
			try_drop_item()


func try_drop_blessing() -> void:
	if randomize_drop and randf() > blessing_drop_chance:
		return

	if blessing_reward <= 0:
		return

	give_blessing()
	show_blessing_popup()


func try_drop_item() -> void:
	if item_drop_scene == null:
		push_warning(name + " ยังไม่ได้ใส่ item_drop_scene")
		return

	if item_drop_id.is_empty():
		push_warning(name + " ยังไม่ได้ใส่ item_drop_id")
		return

	if item_drop_count <= 0:
		return

	if randomize_drop and randf() > item_drop_chance:
		return

	for i in range(item_drop_count):
		var item = item_drop_scene.instantiate()
		get_tree().current_scene.add_child(item)

		if item is Node2D:
			item.global_position = global_position + Vector2(
				randf_range(-12.0, 12.0),
				randf_range(-8.0, 8.0)
			)
			item.z_index = 999

		if item.has_method("setup_item"):
			item.setup_item(item_drop_id, item_drop_amount, item_drop_texture)

		if item.has_method("initialize_spawn"):
			item.initialize_spawn()


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
	if sprite == null or is_dead:
		return

	if value:
		sprite.modulate = Color(1.3, 1.3, 0.7)
	else:
		sprite.modulate = Color(1, 1, 1)


func flash_hit() -> void:
	if sprite == null or is_dead:
		return

	sprite.modulate = Color(1.8, 0.7, 0.7)
	await get_tree().create_timer(0.08).timeout

	if not is_dead and sprite != null:
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

	var anim_name := "default"

	if not effect_sprite.sprite_frames.has_animation(anim_name):
		push_error("ไม่มี animation: " + anim_name)
		return

	effect_sprite.sprite_frames.set_animation_loop(anim_name, false)
	effect_sprite.play(anim_name)
