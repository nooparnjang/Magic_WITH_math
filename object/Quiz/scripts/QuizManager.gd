extends Node

signal question_ready(question: Dictionary)
signal quiz_finished(success: bool)

var current_question: Dictionary = {}


func start_single_question() -> void:
	await get_tree().process_frame

	var total :int= QuizDatabase.get_total_questions()

	if total <= 0:
		push_error("QuizManager: No questions available")
		return

	current_question = QuizDatabase.get_question(randi() % total)

	if current_question.is_empty():
		push_error("QuizManager: Question is empty")
		return

	question_ready.emit(current_question)


func submit_answer(answer_index: int) -> void:
	if current_question.is_empty():
		return

	var correct_answer := int(current_question.get("answer", -1))

	if answer_index == correct_answer:
		quiz_finished.emit(true)
	else:
		quiz_finished.emit(false)
