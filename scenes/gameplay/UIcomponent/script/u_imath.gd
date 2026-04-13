extends Control

@export var world_offset := Vector2(0, -80)

@onready var problem_label: Label = $VBoxContainer/Problem
@onready var answer_input: LineEdit = $VBoxContainer/LineEdit

var correct_answer: int = 0
var current_target: Node2D = null
var player_ref: Node = null

func _ready() -> void:
	hide()
	answer_input.text_submitted.connect(_on_answer_submitted)

func _process(_delta: float) -> void:
	if not visible:
		return

	if current_target == null or not is_instance_valid(current_target):
		hide()
		return

	var screen_pos: Vector2 = current_target.get_global_transform_with_canvas().origin + world_offset
	position = screen_pos - size * 0.5

func open_question(target: Node2D, player: Node) -> void:
	current_target = target
	player_ref = player

	var question_data := generate_question()
	problem_label.text = question_data["text"]
	correct_answer = question_data["answer"]

	answer_input.text = ""
	show()

	await get_tree().process_frame
	answer_input.grab_focus()

func generate_question() -> Dictionary:
	var a := randi_range(1, 9)
	var b := randi_range(1, 9)

	return {
		"text": str(a) + " + " + str(b),
		"answer": a + b
	}

func _on_answer_submitted(text: String) -> void:
	if current_target == null or not is_instance_valid(current_target):
		close_ui()
		return

	var cleaned := text.strip_edges()

	if cleaned.is_valid_int() and int(cleaned) == correct_answer:
		if current_target.has_method("take_damage"):
			current_target.take_damage(1)
			print("Correct")
	else:
		print("Wrong")

	close_ui()

func close_ui() -> void:
	hide()
	answer_input.text = ""
	current_target = null

	if player_ref != null and is_instance_valid(player_ref):
		player_ref.finish_answering()
