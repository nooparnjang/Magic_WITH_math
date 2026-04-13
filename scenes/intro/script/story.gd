extends Control

# =========================
# 🎯 UI REFERENCES
# =========================
@onready var story_text = $allContent/VBoxContainer/story
@onready var click_text = $allContent/VBoxContainer/blinkingText

# =========================
# 🎯 BACKGROUND REFERENCES
# =========================
@onready var story_bg = $bgContainer/bg_1
@onready var gameplay_bg = $bgContainer/bg_2
@onready var blur = $blur

# shader reference
var blur_mat

# =========================
# 🎯 STORY DATA
# =========================
var part1 = "In the year 3030, Mathtria once thrived..."
var part2 = "Darkness begins to consume the city..."

# =========================
# 🎯 CONTROL VARIABLES
# =========================
var typing_speed = 0.02
var is_typing = true
var current_part = 1
var blinking = false
