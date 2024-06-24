extends PanelContainer

var data
var unlocked = false

onready var icon = $Container/Top/Icon
onready var title = $Container/Top/Text/Name
onready var desc = $Container/Top/Text/Description
onready var progress = $Container/Progress

func _ready():
	update()

func update():
	if (
		State.profile != null && 
		State.profile.achievements.has(data.name)
	):
		if State.profile.achievements[data.name] == 1:
			unlocked = true
		elif State.profile.achievements[data.name] > 0:
			progress.visible = true
			progress.value = State.profile.achievements[data.name]
	icon.texture = data.icon[unlocked]
	title.text = data.name
	desc.text = data.desc
	if unlocked:
		title.modulate = Config.colors.magenta
		desc.modulate = Config.colors.yellow
