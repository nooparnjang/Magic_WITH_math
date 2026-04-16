extends StaticBody2D

@export var next_scene: String = "res://scenes/gameplay/darkalleyafter.tscn"
@export var required_item: String = "engine_part"

var player_in_range := false

@onready var area: Area2D = $Area2D

func _ready() -> void:
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)

	if not area.body_exited.is_connected(_on_body_exited):
		area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("ui_talk"):
		try_change_scene()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func try_change_scene() -> void:
	# ❌ ไม่มีของ → ไม่ให้ไป
	if not BlessingManager.has_item(required_item):
		on_missing_item()
		return

	# ✅ มีของ → ไปได้
	change_scene()

func change_scene() -> void:
	if next_scene == "":
		push_warning("next_scene is empty!")
		return

	get_tree().change_scene_to_file(next_scene)

func on_missing_item() -> void:
	print("You need the engine part first.")
