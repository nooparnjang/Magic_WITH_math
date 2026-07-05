extends Node2D

var player: Node = null
var player_in_range := false
var quiz_active := false

@onready var area: Area2D = $Area2D


func _ready() -> void:
	if not area.body_entered.is_connected(_on_area_2d_body_entered):
		area.body_entered.connect(_on_area_2d_body_entered)

	if not area.body_exited.is_connected(_on_area_2d_body_exited):
		area.body_exited.connect(_on_area_2d_body_exited)

	if QuizUI != null:
		if not QuizUI.quiz_closed.is_connected(on_quiz_closed):
			QuizUI.quiz_closed.connect(on_quiz_closed)


func _process(_delta: float) -> void:
	if quiz_active:
		return

	if not player_in_range:
		return

	if Input.is_action_just_pressed("interact"):
		start_quiz()


func start_quiz() -> void:
	if quiz_active:
		return

	if QuizUI == null:
		push_error("QuizUI AutoLoad missing!")
		return

	if QuizManager == null:
		push_error("QuizManager AutoLoad missing!")
		return

	if QuizDatabase.get_total_questions() <= 0:
		push_error("No quiz questions loaded!")
		return

	if player and player.has_method("begin_interaction"):
		player.begin_interaction()

	quiz_active = true

	# ไม่ต้อง QuizUI.show() ตรงนี้ก็ได้
	# เพราะ _on_question_ready จะ show เอง
	QuizManager.start_single_question()


func _on_area_2d_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body
		player_in_range = true


func _on_area_2d_body_exited(body: Node) -> void:
	if body == player:
		player = null
		player_in_range = false


func on_quiz_closed() -> void:
	quiz_active = false

	if player and player.has_method("end_interaction"):
		player.end_interaction()
