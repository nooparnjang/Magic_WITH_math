extends Node

signal question_ready(question: Dictionary)
signal quiz_finished(success: bool)

var current_question: Dictionary

func start_single_question() -> void:
	await get_tree().process_frame

	current_question = QuizDatabase.get_question(randi() % QuizDatabase.get_total_questions())

	emit_signal("question_ready", current_question)


func submit_answer(answer_index: int) -> void:
	if current_question.is_empty():
		return

	if answer_index == current_question["answer"]:
		emit_signal("quiz_finished", true)
	else:
		emit_signal("quiz_finished", false)
