extends StaticBody2D

var player_near = false

@export var next_scene = "res://object/textcomwendy.tscn"


func _ready():
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)


func _process(_delta):
	if player_near and Input.is_action_just_pressed("interact"):
		get_tree().change_scene_to_file(next_scene)


func _on_body_entered(body):
	if body.is_in_group("player"):
		player_near = true
		print("กด E เพื่อใช้งานคอม")


func _on_body_exited(body):
	if body.is_in_group("player"):
		player_near = false
