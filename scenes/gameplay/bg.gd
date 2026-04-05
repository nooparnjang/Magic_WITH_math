extends Node2D

@export var back_ratio: float = 0.2
@export var middle_ratio: float = 0.5
@export var foremost_ratio: float = 1.0

@onready var mc = $"../maincharacter"

@onready var back_1: TextureRect = $Back/TextureRect
@onready var back_2: TextureRect = $Back/TextureRect2

@onready var middle_1: TextureRect = $middle/TextureRect
@onready var middle_2: TextureRect = $middle/TextureRect2

@onready var foremost_1: TextureRect = $foremost/TextureRect
@onready var foremost_2: TextureRect = $foremost/TextureRect2

var back_width: float
var middle_width: float
var foremost_width: float


func _ready():
	back_width = back_1.size.x
	middle_width = middle_1.size.x
	foremost_width = foremost_1.size.x

	setup_pair(back_1, back_2, back_width)
	setup_pair(middle_1, middle_2, middle_width)
	setup_pair(foremost_1, foremost_2, foremost_width)


func _process(delta):
	var move_x := 0.0

	# ใช้ความเร็วของตัวละคร ถ้า mc เป็น CharacterBody2D
	if mc.has_method("get_velocity"):
		move_x = mc.velocity.x
	else:
		move_x = mc.velocity.x

	# ถ้าไม่เดิน ฉากไม่เลื่อน
	if abs(move_x) < 0.1:
		return

	# ฉากเลื่อนสวนทางกับตัวละคร
	scroll_pair(back_1, back_2, back_width, move_x * back_ratio, delta)
	scroll_pair(middle_1, middle_2, middle_width, move_x * middle_ratio, delta)
	scroll_pair(foremost_1, foremost_2, foremost_width, move_x * foremost_ratio, delta)


func setup_pair(bg1: TextureRect, bg2: TextureRect, section_width: float) -> void:
	bg1.position.x = 0
	bg2.position.x = section_width
	bg2.position.y = bg1.position.y


func scroll_pair(bg1: TextureRect, bg2: TextureRect, section_width: float, move_speed: float, delta: float) -> void:
	# ตัวละครเดินขวา ฉากควรไปซ้าย
	bg1.position.x -= move_speed * delta
	bg2.position.x -= move_speed * delta

	if bg1.position.x <= -section_width:
		bg1.position.x = bg2.position.x + section_width

	if bg2.position.x <= -section_width:
		bg2.position.x = bg1.position.x + section_width

	if bg1.position.x >= section_width:
		bg1.position.x = bg2.position.x - section_width

	if bg2.position.x >= section_width:
		bg2.position.x = bg1.position.x - section_width
