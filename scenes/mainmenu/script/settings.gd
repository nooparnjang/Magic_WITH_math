extends Control

# =========================
# 🎯 UI REFERENCES
# =========================
@onready var sfx_row = $backset/VBoxContainer/SFX_row
@onready var music_row = $backset/VBoxContainer/Music_row

@onready var sfx_text = $backset/VBoxContainer/SFX_row/HBoxContainer/sfx_status
@onready var music_text = $backset/VBoxContainer/Music_row/HBoxContainer2/music_status

# =========================
# 🎮 STATE
# =========================
var sfx_on = false
var music_on = false

# =========================
# 🚀 READY
# =========================
func _ready():
	sfx_row.pressed.connect(_on_sfx_pressed)
	music_row.pressed.connect(_on_music_pressed)

	update_ui()

# =========================
# 🔊 TOGGLE
# =========================
func _on_sfx_pressed():
	sfx_on = !sfx_on
	update_ui()

func _on_music_pressed():
	music_on = !music_on
	update_ui()

# =========================
# 🎨 UPDATE UI
# =========================
func update_ui():
	sfx_text.text = "ON" if sfx_on else "OFF"
	music_text.text = "ON" if music_on else "OFF"
