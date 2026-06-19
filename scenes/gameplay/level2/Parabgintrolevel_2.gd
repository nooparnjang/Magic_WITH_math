extends Node2D

@export var auto_scroll_enabled: bool = true
@export var scroll_speed: Vector2 = Vector2(-30.0, 0.0)
@export var use_layer_scroll_scale: bool = true

# =========================
# Auto Animation
# =========================

# ลาก AnimatedSprite2D ที่ต้องการมาใส่เองใน Inspector
@export var target_animated_sprite: AnimatedSprite2D

# ชื่อ animation ที่จะให้เล่นเอง
@export var auto_animation_name: StringName = "default"

# ให้เล่นตอนเริ่มซีนไหม
@export var auto_play_animation: bool = true


func _ready() -> void:
	if auto_play_animation:
		play_assigned_animation()


func _process(delta: float) -> void:
	if not auto_scroll_enabled:
		return

	for child in get_children():
		if child is Parallax2D:
			var layer := child as Parallax2D

			var speed := scroll_speed

			if use_layer_scroll_scale:
				speed = Vector2(
					scroll_speed.x * layer.scroll_scale.x,
					scroll_speed.y * layer.scroll_scale.y
				)

			layer.scroll_offset += speed * delta


func play_assigned_animation() -> void:
	if target_animated_sprite == null:
		push_warning("ยังไม่ได้ assign target_animated_sprite")
		return

	if target_animated_sprite.sprite_frames == null:
		push_warning(target_animated_sprite.name + " ไม่มี SpriteFrames")
		return

	if not target_animated_sprite.sprite_frames.has_animation(auto_animation_name):
		push_warning(target_animated_sprite.name + " ไม่มี animation ชื่อ " + str(auto_animation_name))
		return

	target_animated_sprite.play(auto_animation_name)
