extends TextureButton

@onready var label = $Label

var normal_color = Color("#0c0a3a")
var hover_color = Color("#ffffff")

func _process(_delta):
	if is_hovered():
		label.add_theme_color_override("font_color", hover_color)
	else:
		label.add_theme_color_override("font_color", normal_color)
