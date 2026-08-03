extends HBoxContainer

@onready var rank_label: Label = $Rank/RANK
@onready var name_label: Label = $Rank2/RANK2
@onready var country_label: Label = $country2/country
@onready var kill_label: Label = $kill/KillLabel
@onready var blessing_label: Label = $Score/ScoreLabel


func setup(score: LeadrScore) -> void:
	rank_label.text = "#" + str(score.rank)

	name_label.text = score.player_name

	country_label.text = str(
		score.metadata.get(
			"country",
			"--"
		)
	)

	kill_label.text = str(
		int(score.value)
	)

	blessing_label.text = str(
		int(
			score.metadata.get(
				"blessings",
				0
			)
		)
	)
