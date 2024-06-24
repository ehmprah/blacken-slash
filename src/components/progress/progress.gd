extends VBoxContainer

onready var bar = $Progress
onready var needle = $Progress/Border/Bar/Needle
onready var text = $Text
onready var current = $Text/Number

func update():
	var difficulty = State.game.difficulty.current
	bar.visible = difficulty <= 50
	text.visible = difficulty > 50
	current.text = String(difficulty)
	needle.position = Vector2(difficulty * 8 - 8, 0)
