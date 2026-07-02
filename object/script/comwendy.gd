extends StaticBody2D

var player_near := false
var computer_ui = null

@export var computer_scene: PackedScene


func _ready():
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)


func _process(_delta):
	if player_near \
	and Input.is_action_just_pressed("ui_talk") \
	and computer_ui == null:

		computer_ui = computer_scene.instantiate()

		# เมื่อ UI ถูกปิด ให้ตัวแปรกลับเป็น null
		computer_ui.tree_exited.connect(_on_computer_ui_closed)

		get_tree().current_scene.add_child(computer_ui)

		# หยุดเกม
		get_tree().paused = true


func _on_body_entered(body):
	if body.is_in_group("player"):
		player_near = true


func _on_body_exited(body):
	if body.is_in_group("player"):
		player_near = false


func _on_computer_ui_closed():
	computer_ui = null
