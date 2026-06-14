extends Area2D

@export var item_id: String = "coin"
@export var amount: int = 1
@export var sprite_texture: Texture2D

@export var pickup_sound: AudioStream = preload("res://assets/sound/pick-up-sfx-38516.mp3")
@export var pickup_volume_db: float = 0.0

@export var float_enabled := true
@export var float_height := 5.0
@export var float_speed := 3.0

@export var drop_pop_enabled := true
@export var drop_pop_height := 10.0
@export var drop_pop_duration := 0.18

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var collected := false
var base_position: Vector2
var float_time := 0.0


func _ready() -> void:
	if sprite != null and sprite_texture != null:
		sprite.texture = sprite_texture

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if collected:
		return

	if float_enabled:
		float_time += delta
		global_position.y = base_position.y + sin(float_time * float_speed) * float_height


func setup_item(new_item_id: String, new_amount: int, new_texture: Texture2D = null) -> void:
	item_id = new_item_id
	amount = new_amount
	sprite_texture = new_texture

	if sprite != null and sprite_texture != null:
		sprite.texture = sprite_texture


func initialize_spawn() -> void:
	base_position = global_position
	float_time = 0.0

	if drop_pop_enabled:
		play_drop_pop()


func _on_body_entered(body: Node) -> void:
	if collected:
		return

	if body.is_in_group("player"):
		if body.has_method("can_collect_items") and not body.can_collect_items():
			return

		collect()


func collect() -> void:
	if collected:
		return

	collected = true

	BlessingManager.add_item(item_id, amount)

	play_pickup_sound()

	# ปิดภาพกับชนก่อน เพื่อกันเก็บซ้ำ
	if sprite != null:
		sprite.visible = false

	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	# ปิดการตรวจจับ Area2D
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	queue_free()


func play_pickup_sound() -> void:
	if pickup_sound == null:
		return

	var audio_player := AudioStreamPlayer.new()
	audio_player.stream = pickup_sound
	audio_player.volume_db = pickup_volume_db

	# ใส่ไว้ใน scene หลัก ไม่ใส่เป็นลูกของ item
	# เพราะ item จะ queue_free ทันที เสียงจะได้ไม่โดนลบตาม
	get_tree().current_scene.add_child(audio_player)

	audio_player.play()

	audio_player.finished.connect(func():
		audio_player.queue_free()
	)


func play_drop_pop() -> void:
	var start_pos := global_position
	var peak_pos := start_pos + Vector2(0, -drop_pop_height)

	var tween := create_tween()
	tween.tween_property(self, "global_position", peak_pos, drop_pop_duration * 0.5)
	tween.tween_property(self, "global_position", start_pos, drop_pop_duration * 0.5)

	await tween.finished
	base_position = global_position
