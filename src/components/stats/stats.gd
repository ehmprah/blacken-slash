extends ScrollContainer

onready var labels = {
	Config.GAME_NORMAL: {
		'games': $Margin/Container/Normal/Games/Amount,
		'level': $Margin/Container/Normal/Level/Amount,
		'score': $Margin/Container/Normal/Score/Amount,
		'kills': $Margin/Container/Normal/Kills/Amount,
		'kernels': $Margin/Container/Normal/Kernels/Amount,
		'legendaries': $Margin/Container/Normal/Legendaries/Amount,
		'epics': $Margin/Container/Normal/Epics/Amount,
	},
	Config.GAME_LADDER: {
		'games': $Margin/Container/Ladder/Games/Amount,
		'level': $Margin/Container/Ladder/Level/Amount,
		'score': $Margin/Container/Ladder/Score/Amount,
		'kills': $Margin/Container/Ladder/Kills/Amount,
		'kernels': $Margin/Container/Ladder/Kernels/Amount,
		'legendaries': $Margin/Container/Ladder/Legendaries/Amount,
		'epics': $Margin/Container/Ladder/Epics/Amount,
	}
}

func update():
	for type in State.profile.statistics:
		var stats = State.profile.statistics[type]
		for key in stats:
			labels[type][key].text = String(stats[key])


func _physics_process(_delta):
	if visible:
		var scroll = Input.get_axis("ui_page_up", "ui_page_down")
		if scroll != 0:
			scroll_vertical += scroll * 20
