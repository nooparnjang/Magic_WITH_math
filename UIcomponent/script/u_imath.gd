extends Control

@export var world_offset := Vector2(0, -80)

@export var wrong_flash_color := Color(1.0, 0.15, 0.15)
@export var wrong_flash_time := 0.25

@onready var problem_label: Label = $VBoxContainer/Problem
@onready var answer_input: LineEdit = $VBoxContainer/LineEdit
@onready var wrong_sound: AudioStreamPlayer = $wrongsong
@onready var correct_sound: AudioStreamPlayer = $correctsound

var correct_answer: int = 0
var current_target: Node2D = null
var player_ref: Node = null

var is_flashing_wrong := false

enum QuestionPattern {
	THREE_DIGITS_WITH_ONE_DIGIT,
	TWO_DIGITS_WITH_ONE_DIGIT,
	ONE_DIGIT_WITH_ONE_DIGIT
}


func _ready() -> void:
	hide()

	if not answer_input.text_submitted.is_connected(_on_answer_submitted):
		answer_input.text_submitted.connect(_on_answer_submitted)


func _process(_delta: float) -> void:
	if not visible:
		return

	if current_target == null or not is_instance_valid(current_target):
		var player := player_ref
		close_ui_silent()

		if player != null and is_instance_valid(player):
			if player.has_method("finish_answering"):
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

	clear_wrong_feedback()
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
			b = randi_range(max(1, b_min), max(1, b_max))

			var quotient_min := maxi(1, int(ceil(float(a_min) / float(b))))
			var quotient_max := maxi(quotient_min, int(floor(float(a_max) / float(b))))

			answer = randi_range(quotient_min, quotient_max)
			a = b * answer

		_:
			a = randi_range(a_min, a_max)
			b = randi_range(b_min, b_max)
			answer = a + b
			op = "+"

	return {
		"text": str(a) + " " + op + " " + str(b),
		"answer": answer
	}


func _on_answer_submitted(text: String) -> void:
	if is_flashing_wrong:
		return

	if current_target == null or not is_instance_valid(current_target):
		var missing_player := player_ref
		close_ui_silent()

		if missing_player != null and is_instance_valid(missing_player):
			if missing_player.has_method("finish_answering"):
				missing_player.finish_answering()

		return

	var cleaned := text.strip_edges()
	var player := player_ref
	var target := current_target
	var is_correct := cleaned.is_valid_int() and int(cleaned) == correct_answer

	if is_correct:
		print("Correct")
		play_correct_sound()
		close_ui_silent()

		if player != null and is_instance_valid(player):
			if player.has_method("start_cast_release"):
				player.start_cast_release(target, 1)
			else:
				if target != null and is_instance_valid(target) and target.has_method("take_damage"):
					target.take_damage(1)

				if player.has_method("finish_answering"):
					player.finish_answering()
	else:
		print("Wrong")

		await flash_wrong_feedback()

		close_ui_silent()

		if player != null and is_instance_valid(player):
			if player.has_method("finish_answering"):
				player.finish_answering()


func flash_wrong_feedback() -> void:
	if is_flashing_wrong:
		return

	is_flashing_wrong = true

	if wrong_sound != null:
		wrong_sound.stop()
		wrong_sound.play()

	problem_label.add_theme_color_override("font_color", wrong_flash_color)
	answer_input.add_theme_color_override("font_color", wrong_flash_color)
	answer_input.add_theme_color_override("caret_color", wrong_flash_color)
	answer_input.add_theme_color_override("font_placeholder_color", wrong_flash_color)

	var normal_stylebox := answer_input.get_theme_stylebox("normal")
	if normal_stylebox != null:
		var copied_stylebox := normal_stylebox.duplicate()

		if copied_stylebox is StyleBoxFlat:
			copied_stylebox.border_color = wrong_flash_color
			copied_stylebox.border_width_left = 2
			copied_stylebox.border_width_top = 2
			copied_stylebox.border_width_right = 2
			copied_stylebox.border_width_bottom = 2

		answer_input.add_theme_stylebox_override("normal", copied_stylebox)

	await get_tree().create_timer(wrong_flash_time).timeout

	clear_wrong_feedback()

	is_flashing_wrong = false


func clear_wrong_feedback() -> void:
	problem_label.remove_theme_color_override("font_color")

	answer_input.remove_theme_color_override("font_color")
	answer_input.remove_theme_color_override("caret_color")
	answer_input.remove_theme_color_override("font_placeholder_color")

	answer_input.remove_theme_stylebox_override("normal")


func close_ui() -> void:
	clear_wrong_feedback()

	hide()
	answer_input.text = ""
	current_target = null
	player_ref = null
	is_flashing_wrong = false


func close_ui_silent() -> void:
	clear_wrong_feedback()

	hide()
	answer_input.text = ""
	current_target = null
	player_ref = null
	is_flashing_wrong = false
	
func play_correct_sound() -> void:
	if correct_sound != null:
		correct_sound.stop()
		correct_sound.play()
