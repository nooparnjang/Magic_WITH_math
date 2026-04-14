extends Control

# =========================
# 🎯 UI REFERENCES
# =========================
@onready var story_text = $allContent/MarginContainer/VBoxContainer/story
@onready var click_text = $blinkingText

# =========================
# 🎯 BACKGROUND
# =========================
@onready var story_bg = $bgContainer/bg_1
@onready var gameplay_bg = $bgContainer/bg_2
@onready var blur = $blur

var blur_mat
var blink_tween

# =========================
# 📖 STORY DATA
# =========================
var part1_lines = [
	"In the year 3030, Mathtria",
	"a cyber city filled with a past of great glory",
	"powered by intelligent calculation systems",
	"is now shrouded in a dark ominous fog",
	"by the demon king VOXTRON",
	"and an army of autonomous machines that despise numbers",
	" ",
	"one night, an ancient satellite burst into light from the sky",
	"its fragments scattering across the distant horizon"
]

var part2_lines = [
	"matching an ancient prophecy from the year 2026 that foretold",
	"a genius child born from the light of the heavens",
	"with the magic of mathematics to begin a world without automation",
	" ",
	"that child is the princess of the kingdom of Mathtria",
	"in her youth, she trained to wield equations as weapons",
	"piercing demonic systems with computational magic in her blood",
	" ",
	"and her personal artificial intelligence companion",
	"is \"you\", the one who controls the fate of this cyber realm"
]

# =========================
# 🎮 STATE
# =========================
var current_part = 1
var current_line = 0

var typing_speed = 0.02
var part_finished = false
var typing_id = 0

# =========================
# 🚀 READY
# =========================
func _ready():
	# =========================
	# 🎨 BLUR & VISUALS
	# =========================
	blur_mat = blur.material
	if blur_mat:
		blur_mat.set_shader_parameter("blur_amount", 1.2)

	gameplay_bg.modulate.a = 0.0
	
	click_text.text = "Click anywhere to continue"
	click_text.visible = false

	show_line()

# =========================
# 📖 GET LINES
# =========================
func get_lines():
	return part1_lines if current_part == 1 else part2_lines

# =========================
# 📝 SHOW LINE
# =========================
func show_line():
	var lines = get_lines()
	var text = lines[current_line]

	story_text.text += ("" if story_text.text == "" else "\n") + text
	story_text.visible_characters = story_text.text.length() - text.length()

	part_finished = false
	click_text.visible = false
	stop_blinking()

	typing_id += 1
	type_line(text, typing_id)

# =========================
# ✨ TYPE LINE
# =========================
func type_line(text, id):
	for i in text.length():

		if id != typing_id:
			return

		story_text.visible_characters += 1
		await get_tree().create_timer(typing_speed).timeout

	if id != typing_id:
		return

	await get_tree().create_timer(0.3).timeout
	next_line()

# =========================
# ➡ NEXT LINE
# =========================
func next_line():
	current_line += 1
	var lines = get_lines()

	if current_line < lines.size():
		show_line()
	else:
		enable_continue_state()

# =========================
# ⚡ SHOW ALL REMAINING
# =========================
func show_all_remaining():
	typing_id += 1

	var lines = get_lines()
	current_line += 1

	while current_line < lines.size():
		story_text.text += "\n" + lines[current_line]
		current_line += 1

	story_text.visible_characters = -1 

	enable_continue_state()

# =========================
# 🎯 CONTINUE STATE
# =========================
func enable_continue_state():
	part_finished = true

	click_text.visible = true
	start_blinking()

# =========================
# 🎬 TRANSITION
# =========================
func switch_to_part2():
	var t = create_tween()

	t.tween_property(gameplay_bg, "modulate:a", 1.0, 1.0)
	t.parallel().tween_property(story_bg, "modulate:a", 0.0, 1.0)

# =========================
# 🖱 INPUT
# =========================
func _input(event):
	if event is InputEventMouseButton and event.pressed:

		if !part_finished:
			show_all_remaining()
			return

		if current_part == 1:
			current_part = 2
			current_line = 0

			story_text.text = ""
			click_text.visible = false
			stop_blinking()

			switch_to_part2()

			await get_tree().create_timer(1.0).timeout
			show_line()
			return

		get_tree().change_scene_to_file("res://scenes/gameplay/NormalWave.tscn")

# =========================
# ✨ BLINKING SYSTEM
# =========================
func start_blinking():
	if blink_tween:
		blink_tween.kill()

	click_text.modulate.a = 1.0

	blink_tween = create_tween()
	blink_tween.set_loops()

	blink_tween.tween_property(click_text, "modulate:a", 0.2, 0.5)
	blink_tween.tween_property(click_text, "modulate:a", 1.0, 0.5)

func stop_blinking():
	if blink_tween:
		blink_tween.kill()

	click_text.modulate.a = 0.0
