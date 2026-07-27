extends Node

const BOARD_SLUG := "leaderboard"
const SAVE_PATH := "user://leaderboard_stats.json"

var kills: int = 0

var _board_id: String = ""
var _last_submitted_score: LeadrScore = null


func _ready() -> void:
	load_stats()


# ============================================================
# KILL COUNT
# ============================================================

func add_kill(amount: int = 1) -> void:
	if amount <= 0:
		return

	kills += amount
	save_stats()

	print("[Leaderboard] Total kills: ", kills)


func get_kills() -> int:
	return kills


func set_kills(value: int) -> void:
	kills = max(value, 0)
	save_stats()


# ============================================================
# LOCAL SAVE / LOAD
# ============================================================

func save_stats() -> void:
	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if file == null:
		push_error("[Leaderboard] Could not save stats.")
		return

	var data := {
		"kills": kills
	}

	file.store_string(
		JSON.stringify(data, "\t")
	)


func load_stats() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		kills = 0
		return

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error("[Leaderboard] Could not load stats.")
		kills = 0
		return

	var parsed = JSON.parse_string(
		file.get_as_text()
	)

	if not parsed is Dictionary:
		push_error("[Leaderboard] Invalid stats save.")
		kills = 0
		return

	kills = max(
		int(parsed.get("kills", 0)),
		0
	)

	print("[Leaderboard] Loaded kills: ", kills)


# ============================================================
# LEADR CLIENT
# ============================================================

func get_leadr() -> LeadrClient:
	var leadr := get_node_or_null(
		"/root/Leadr"
	) as LeadrClient

	if leadr == null:
		push_error(
			"[Leaderboard] LEADR autoload not found."
		)

	return leadr


# ============================================================
# BOARD
# ============================================================

func resolve_board_id() -> String:
	if not _board_id.is_empty():
		return _board_id

	var leadr := get_leadr()

	if leadr == null:
		return ""

	if not leadr.is_initialized():
		push_error(
			"[Leaderboard] LEADR is not initialized."
		)
		return ""

	print(
		"[Leaderboard] Resolving board slug: ",
		BOARD_SLUG
	)

	var result := await leadr.get_board(
		BOARD_SLUG
	)

	if not result.is_success:
		push_error(
			"[Leaderboard] Board lookup failed: "
			+ result.error.message
		)
		return ""

	if result.data == null:
		push_error(
			"[Leaderboard] Board result is null."
		)
		return ""

	_board_id = result.data.id

	print(
		"[Leaderboard] Board ID: ",
		_board_id
	)

	return _board_id


# ============================================================
# SUBMIT CURRENT SCORE
# ============================================================

func submit_current_score() -> bool:
	var leadr := get_leadr()

	if leadr == null:
		return false

	var board_id := await resolve_board_id()

	if board_id.is_empty():
		return false

	var player_name := PlayerProfile.player_name.strip_edges()

	if player_name.is_empty():
		push_error(
			"[Leaderboard] Player name is empty."
		)
		return false

	# ดึง blessing ปัจจุบันทุกครั้ง
	var current_blessings := BlessingManager.get_blessings()

	var metadata := {
		"country": PlayerProfile.country_code,
		"blessings": current_blessings
	}

	print("========== LEADR SUBMIT ==========")
	print("Name: ", player_name)
	print("Kills: ", kills)
	print("Country: ", PlayerProfile.country_code)
	print("Blessings: ", current_blessings)
	print("==================================")

	var result := await leadr.submit_score(
		board_id,
		float(kills),
		player_name,
		"",
		metadata
	)

	if not result.is_success:
		push_error(
			"[Leaderboard] Submit failed: "
			+ result.error.message
		)
		return false

	if result.data == null:
		push_error(
			"[Leaderboard] Submit returned no data."
		)
		return false

	_last_submitted_score = result.data

	print("======= LEADR SUBMIT SUCCESS =======")
	print("Score ID: ", _last_submitted_score.id)
	print("Rank from submit: #", _last_submitted_score.rank)
	print("Kills: ", int(_last_submitted_score.value))
	print("Metadata: ", _last_submitted_score.metadata)
	print("====================================")

	return true


# ============================================================
# GLOBAL TOP SCORES
# ============================================================

func load_top_scores(limit: int = 10) -> Array[LeadrScore]:
	var scores: Array[LeadrScore] = []

	var leadr := get_leadr()

	if leadr == null:
		return scores

	var board_id := await resolve_board_id()

	if board_id.is_empty():
		return scores

	print(
		"[Leaderboard] Loading Top ",
		limit,
		" from ",
		board_id
	)

	var result := await leadr.get_scores(
		board_id,
		limit
	)

	if not result.is_success:
		push_error(
			"[Leaderboard] Load scores failed: "
			+ result.error.message
		)
		return scores

	if result.data == null:
		push_warning(
			"[Leaderboard] Scores request returned null data."
		)
		return scores

	for item in result.data.items:
		if item is LeadrScore:
			scores.append(item)

	print(
		"[Leaderboard] Loaded scores: ",
		scores.size()
	)

	return scores


# ============================================================
# MY SCORE / MY RANK
# ============================================================

func get_my_score() -> LeadrScore:
	if _last_submitted_score == null:
		return null

	var leadr := get_leadr()

	if leadr == null:
		return _last_submitted_score

	var board_id := await resolve_board_id()

	if board_id.is_empty():
		return _last_submitted_score

	# ใช้ around_score_id เพื่อให้ LEADR คืน score ที่มี rank จริง
	var result := await leadr.get_scores(
		board_id,
		10,
		"",
		_last_submitted_score.id
	)

	if not result.is_success:
		push_warning(
			"[Leaderboard] Could not resolve my rank: "
			+ result.error.message
		)

		return _last_submitted_score

	if result.data == null:
		return _last_submitted_score

	# หา score เดียวกับที่เพิ่ง submit
	for score: LeadrScore in result.data.items:
		if score.id == _last_submitted_score.id:
			_last_submitted_score = score
			return score

	# fallback: หา identity เดียวกัน
	for score: LeadrScore in result.data.items:
		if (
			not _last_submitted_score.identity_id.is_empty()
			and score.identity_id
			== _last_submitted_score.identity_id
		):
			_last_submitted_score = score
			return score

	return _last_submitted_score
