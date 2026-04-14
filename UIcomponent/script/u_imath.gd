extends Control

@export var world_offset := Vector2(0, -80)

@onready var problem_label: Label = $VBoxContainer/Problem
@onready var answer_input: LineEdit = $VBoxContainer/LineEdit

var correct_answer: int = 0
var current_target: Node2D = null
var player_ref: Node = null

enum QuestionPattern {
	THREE_DIGITS_WITH_ONE_DIGIT,
	TWO_DIGITS_WITH_ONE_DIGIT,
	ONE_DIGIT_WITH_ONE_DIGIT
}

func _ready() -> void:
	hide()
	answer_input.text_submitted.connect(_on_answer_submitted)

func _process(_delta: float) -> void:
	if not visible:
		return

	if current_target == null or not is_instance_valid(current_target):
		var player := player_ref
		close_ui_silent()

		if player != null and is_instance_valid(player):
			player.finish_answering()

		return

	var screen_pos: Vector2 = current_target.get_global_transform_with_canvas().origin + world_offset
	position = screen_pos - size * 0.5

func open_question(target: Node2D, player: Node) -> void:
	current_target = target
	player_ref = player

	var question_data := generate_question_for_target(target)
	problem_label.text = question_data["text"]
	correct_answer = question_data["answer"]

	answer_input.text = ""
	show()

	await get_tree().process_frame
	answer_input.grab_focus()

func generate_question_for_target(target: Node2D) -> Dictionary:
	var pattern: int = QuestionPattern.ONE_DIGIT_WITH_ONE_DIGIT
	var operators: Array[String] = ["+"]

	if "question_pattern" in target:
		pattern = target.question_pattern

	if "allowed_operators" in target and target.allowed_operators.size() > 0:
		operators = target.allowed_operators

	var op: String = operators[randi() % operators.size()]
	return generate_question(pattern, op)

func generate_question(pattern: int, op: String) -> Dictionary:
	match pattern:
		QuestionPattern.THREE_DIGITS_WITH_ONE_DIGIT:
			return build_question_by_digits(100, 999, 1, 9, op)

		QuestionPattern.TWO_DIGITS_WITH_ONE_DIGIT:
			return build_question_by_digits(10, 99, 1, 9, op)

		QuestionPattern.ONE_DIGIT_WITH_ONE_DIGIT:
			return build_question_by_digits(1, 9, 1, 9, op)

	return build_question_by_digits(1, 9, 1, 9, "+")

func build_question_by_digits(a_min: int, a_max: int, b_min: int, b_max: int, op: String) -> Dictionary:
	var a := 0
	var b := 0
	var answer := 0

	match op:
		"+":
			a = randi_range(a_min, a_max)
			b = randi_range(b_min, b_max)
			answer = a + b

		"-":
			a = randi_range(a_min, a_max)
			b = randi_range(b_min, b_max)

			# กันคำตอบติดลบ
			if a < b:
				var temp := a
				a = b
				b = temp

			answer = a - b

		"*":
			a = randi_range(a_min, a_max)
			b = randi_range(b_min, b_max)
			answer = a * b

		"/":
			# ต้องหารลงตัว และ b ห้ามเป็น 0
			b = randi_range(max(1, b_min), max(1, b_max))

			var quotient_min := maxi(1, int(ceil(float(a_min) / float(b))))
			var quotient_max := maxi(quotient_min, int(floor(float(a_max) / float(b))))

			answer = randi_range(quotient_min, quotient_max)
			a = b * answer

	return {
		"text": str(a) + " " + op + " " + str(b),
		"answer": answer
	}

func _on_answer_submitted(text: String) -> void:
	if current_target == null or not is_instance_valid(current_target):
		var missing_player := player_ref
		close_ui_silent()

		if missing_player != null and is_instance_valid(missing_player):
			missing_player.finish_answering()

		return

	var cleaned := text.strip_edges()
	var player := player_ref
	var is_correct := cleaned.is_valid_int() and int(cleaned) == correct_answer

	if is_correct:
		if current_target.has_method("take_damage"):
			current_target.take_damage(1)
			print("Correct")

		close_ui_silent()

		if player != null and is_instance_valid(player):
			if player.has_method("start_cast_release"):
				player.start_cast_release()
			else:
				player.finish_answering()
	else:
		print("Wrong")
		close_ui_silent()

		if player != null and is_instance_valid(player):
			player.finish_answering()

func close_ui() -> void:
	hide()
	answer_input.text = ""
	current_target = null
	player_ref = null

func close_ui_silent() -> void:
	hide()
	answer_input.text = ""
	current_target = null
	player_ref = null
