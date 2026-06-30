extends Area2D

@export var next_scene: String = "res://scenes/gameplay/level4/level_4_realmain.tscn"

var player_in_range := false


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:

	# Robot touches teleport
	if body.is_in_group("robot_hai"):

		var tween = create_tween()

		tween.tween_property(body, "modulate:a", 0.0, 0.25)

		tween.tween_callback(body.queue_free)

		return


	# Player enters teleport
	if body.is_in_group("player"):
		player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false


func _process(_delta):

	if player_in_range and Input.is_action_just_pressed("ui_talk"):
		change_scene()


func change_scene():

	if next_scene == "":
		push_warning("next_scene is empty!")
		return

	get_tree().change_scene_to_file(next_scene)
