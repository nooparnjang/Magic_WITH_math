extends CanvasLayer

signal quiz_closed()
signal answer_selected(index: int)

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
	hide()

	# connect quiz system
	QuizManager.question_ready.connect(_on_question_ready)
	QuizManager.quiz_finished.connect(_on_quiz_finished)

	# connect buttons safely
	#for i in range(buttons.size()):
		#var b := buttons[i]
		#if b:
			#b.pressed.connect(func(i=i):
				#_on_choice_pressed(i)
			#)

	print("QuizUI READY")

# -----------------------------
# SHOW QUESTION
# -----------------------------
func _on_question_ready(q: Dictionary) -> void:
	show()

	question_label.text = q.get("question", "No question")

	var choices = q.get("choices", [])

	for i in range(button_labels.size()):
		if i < choices.size():
			button_labels[i].text = str(choices[i])
			buttons[i].disabled = false
		else:
			button_labels[i].text = ""
			buttons[i].disabled = true

# -----------------------------
# PLAYER ANSWER
# -----------------------------
func _on_choice_pressed(index: int) -> void:
	print("ANSWER CLICKED:", index)
	answer_selected.emit(index)
	QuizManager.submit_answer(index)

# -----------------------------
# RESULT
# -----------------------------
func _on_quiz_finished(success: bool) -> void:
	var player = get_tree().get_first_node_in_group("player")

	if success:
		print("Correct → Blessing")

		if player and player.has_method("restore_stamina"):
			player.restore_stamina(20)
	else:
		print("Wrong → Death")

		if player and player.has_method("take_damage"):
			player.take_damage(999)

	_close()

# -----------------------------
# EXIT BUTTON
# -----------------------------
func _on_exit_pressed() -> void:
	print("Quiz closed by player")
	_close()

func _close() -> void:
	hide()

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.end_interaction()

	quiz_closed.emit()
