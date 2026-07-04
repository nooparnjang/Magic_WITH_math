extends Node2D

var player: Node = null
var player_in_range := false
var quiz_active := false

@onready var area: Area2D = $Area2D


func _ready() -> void:
	# IMPORTANT: avoid duplicate connections
	if not area.body_entered.is_connected(_on_area_2d_body_entered):
		area.body_entered.connect(_on_area_2d_body_entered)

	if not area.body_exited.is_connected(_on_area_2d_body_exited):
		area.body_exited.connect(_on_area_2d_body_exited)


# -----------------------------
# INPUT (PRESS E)
# -----------------------------
func _process(_delta):
	if quiz_active:
		return

	if not player_in_range:
		return

	if Input.is_action_just_pressed("interact"):
		start_quiz()


# -----------------------------
# START QUIZ
# -----------------------------
func start_quiz():
	if quiz_active:
		return

	var quiz_ui = QuizUI  # AUTOLOAD

	if quiz_ui == null:
		push_error("QuizUI AutoLoad missing!")
		return

	if player:
		player.begin_interaction()

	quiz_active = true

	quiz_ui.show()
	QuizManager.start_single_question()


# -----------------------------
# AREA ENTER
# -----------------------------
func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player = body
		player_in_range = true


# -----------------------------
# AREA EXIT
# -----------------------------
func _on_area_2d_body_exited(body):
	if body == player:
		player = null
		player_in_range = false


# -----------------------------
# CALLED BY QUIZUI WHEN DONE
# -----------------------------
func on_quiz_closed():
	quiz_active = false

	if player:
		player.end_interaction()
