extends Control

@export var row_scene: PackedScene

@onready var list: VBoxContainer = %List

@onready var my_rank: Label = %RankNUm
@onready var my_country: Label = %CountryValue
@onready var my_kill: Label = %killcountValue
@onready var my_blessing: Label = %BlessingValue

@onready var loading_overlay: Control = $loading


func _ready() -> void:
	await get_tree().process_frame

	MusicManager.play_music(
		"res://assets/sound/Fame is a Gun - Addison Rae (Crimewave Remix).mp3"
	)

	await load_leaderboard()


func load_leaderboard() -> void:
	loading_overlay.start_loading()

	# ส่ง score ล่าสุด
	var submit_success := await LeaderboardManager.submit_current_score()

	print(
		"[Leaderboard UI] Submit success: ",
		submit_success
	)

	# โหลด Global leaderboard
	var scores := await LeaderboardManager.load_top_scores(10)

	clear_list()

	print(
		"[Leaderboard UI] Scores received: ",
		scores.size()
	)

	for score: LeadrScore in scores:
		add_score_row(score)

	# Global leaderboard พร้อมแล้ว
	# ปิด Loading ตรงนี้เลย
	loading_overlay.stop_loading()

	# My Rank โหลดต่อภายหลัง
	load_my_rank()


func add_score_row(score: LeadrScore) -> void:
	if row_scene == null:
		push_error(
			"LeaderboardRow scene is not assigned."
		)
		return

	var row := row_scene.instantiate()

	list.add_child(row)

	if row.has_method("setup"):
		row.setup(score)
	else:
		push_error(
			"LeaderboardRow has no setup(score) method."
		)


func clear_list() -> void:
	for child in list.get_children():
		child.queue_free()


func load_my_rank() -> void:
	# แสดง loading เฉพาะช่อง rank เอง
	my_rank.text = "..."
	my_country.text = "..."
	my_kill.text = "..."
	my_blessing.text = "..."

	var score := await LeaderboardManager.get_my_score()

	if score == null:
		my_rank.text = "--"
		my_country.text = "--"
		my_kill.text = "0"
		my_blessing.text = "0"
		return

	if score.rank > 0:
		my_rank.text = "#" + str(score.rank)
	else:
		my_rank.text = "--"

	my_country.text = str(
		score.metadata.get(
			"country",
			"--"
		)
	)

	my_kill.text = str(
		int(score.value)
	)

	my_blessing.text = str(
		int(
			score.metadata.get(
				"blessings",
				0
			)
		)
	)
