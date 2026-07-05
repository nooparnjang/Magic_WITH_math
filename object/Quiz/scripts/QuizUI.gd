extends CanvasLayer

signal quiz_closed()
signal answer_selected(index: int)

@onready var background: Control = $Background
@onready var content: Control = $Background/Content
@onready var question_label: Label = $Background/Content/QuestionLabel

@onready var buttons: Array[TextureButton] = [
	$Background/Content/Choice1,
	$Background/Content/Choice2,
	$Background/Content/Choice3,
	$Background/Content/Choice4
]

@onready var button_labels: Array[Label] = [
	$Background/Content/Choice1/Text,
	$Background/Content/Choice2/Text,
	$Background/Content/Choice3/Text,
	$Background/Content/Choice4/Text
]


func _ready() -> void:
	# ให้ UI นี้อยู่หน้าสุด ๆ
	layer = 100

	# ถ้าเกม pause อยู่ UI ยังทำงานได้
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Background รับเมาส์ไว้ ไม่ให้คลิกทะลุไปข้างหลัง
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	content.mouse_filter = Control.MOUSE_FILTER_PASS

	# สำคัญมาก: Label ที่อยู่บนปุ่มต้องไม่กินเมาส์
	for label in button_labels:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ปุ่มต้องรับเมาส์
	for i in range(buttons.size()):
		var b := buttons[i]
		if b == null:
			continue

		b.mouse_filter = Control.MOUSE_FILTER_STOP
		b.disabled = false

		var callable := Callable(self, "_on_choice_pressed").bind(i)
		if not b.pressed.is_connected(callable):
			b.pressed.connect(callable)

	hide()

	if not QuizManager.question_ready.is_connected(_on_question_ready):
		QuizManager.question_ready.connect(_on_question_ready)

	if not QuizManager.quiz_finished.is_connected(_on_quiz_finished):
		QuizManager.quiz_finished.connect(_on_quiz_finished)

	print("QuizUI READY")


func _on_question_ready(q: Dictionary) -> void:
	show()

	question_label.text = q.get("question", "No question")

	var choices: Array = q.get("choices", [])

	for i in range(button_labels.size()):
		if i < choices.size():
			button_labels[i].text = str(choices[i])
			buttons[i].disabled = false
			buttons[i].visible = true
		else:
			button_labels[i].text = ""
			buttons[i].disabled = true
			buttons[i].visible = false


func _on_choice_pressed(index: int) -> void:
	print("ANSWER CLICKED:", index)
	answer_selected.emit(index)
	QuizManager.submit_answer(index)


func _on_quiz_finished(success: bool) -> void:
	var player = get_tree().get_first_node_in_group("player")

	if success:
		print("Correct → Blessing")

		if BlessingManager != null:
			if BlessingManager.has_method("add_blessings"):
				BlessingManager.add_blessings(20)
			else:
				push_error("BlessingManager has no add_blessing() method")
		else:
			push_error("BlessingManager AutoLoad missing")

		_close()
		return

	print("Wrong → Death")

	hide()

	if player == null:
		push_error("QuizUI: Player not found in group 'player'")
		quiz_closed.emit()
		return

	if player.has_method("end_interaction"):
		player.end_interaction()

	if "hp" in player:
		player.hp = 0.0

	if "can_take_damage" in player:
		player.can_take_damage = true

	if "time_since_last_damage" in player:
		player.time_since_last_damage = 0.0

	if player.has_method("die"):
		player.die()
	elif player.has_method("take_damage"):
		player.take_damage(999)
	else:
		push_error("QuizUI: Player has no die() or take_damage()")

	quiz_closed.emit()


func _on_exit_pressed() -> void:
	print("Quiz closed by player")
	_close()


func _close() -> void:
	hide()

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("end_interaction"):
		player.end_interaction()

	quiz_closed.emit()
