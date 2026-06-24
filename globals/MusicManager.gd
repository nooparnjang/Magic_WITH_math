extends Node

@export var allowed_scene_folders: Array[String] = [
	"res://scenes/mainmenu/"
]

@export var auto_stop_outside_allowed_scene: bool = true

var player: AudioStreamPlayer
var current_music_path: String = ""
var target_volume_db: float = -8.0
var fade_tween: Tween

var last_scene_path: String = ""


func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)

	# ถ้ายังไม่มี Bus ชื่อ Music ให้เปลี่ยนเป็น "Master"
	player.bus = "Music"
	player.volume_db = target_volume_db

	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func _process(_delta: float) -> void:
	if not auto_stop_outside_allowed_scene:
		return

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return

	var scene_path := current_scene.scene_file_path

	# กันไม่ให้เช็คซ้ำทุกเฟรมแบบเปลือง ๆ
	if scene_path == last_scene_path:
		return

	last_scene_path = scene_path



	if not is_scene_path_allowed(scene_path):
		if player.playing:
			print("[MusicManager] outside allowed folder, stop music")
			stop_music_now()


func play_music(music_path: String, restart_if_same: bool = false) -> void:
	if not is_current_scene_allowed():
	
		return

	if music_path.is_empty():
		push_warning("Music path is empty")
		return

	if not ResourceLoader.exists(music_path):
		push_error("ไม่เจอไฟล์เพลง: " + music_path)
		return

	if current_music_path == music_path and player.playing and not restart_if_same:
		return

	var stream := load(music_path) as AudioStream
	if stream == null:
		push_error("โหลดเพลงไม่ได้: " + music_path)
		return

	current_music_path = music_path
	player.stream = stream
	player.volume_db = target_volume_db
	player.play()

	


func stop_music_now() -> void:
	if fade_tween != null:
		fade_tween.kill()

	if player != null:
		player.stop()

	current_music_path = ""

	if player != null:
		player.volume_db = target_volume_db

	


func is_current_scene_allowed() -> bool:
	var current_scene := get_tree().current_scene

	if current_scene == null:
		push_warning("MusicManager: current_scene is null")
		return false

	return is_scene_path_allowed(current_scene.scene_file_path)


func is_scene_path_allowed(scene_path: String) -> bool:
	for folder in allowed_scene_folders:
		if scene_path.begins_with(folder):
			return true

	return false
