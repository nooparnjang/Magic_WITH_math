extends StaticBody2D

@export var next_scene: String = "res://scenes/gameplay/boss_level.tscn"

var player_in_range := false

@onready var area: Area2D = $Area2D

func _ready() -> void:
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)

	if not area.body_exited.is_connected(_on_body_exited):
		area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("ui_talk"):
		change_scene()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func change_scene() -> void:
	if next_scene == "":
		push_warning("next_scene is empty!")
		return

	get_tree().change_scene_to_file(next_scene)


func _on_area_2d_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
