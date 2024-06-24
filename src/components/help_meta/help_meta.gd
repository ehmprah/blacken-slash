extends PanelContainer

onready var meta_name = $Container/Labels/Name
onready var meta_desc = $Container/Labels/Description

func _ready():
	var labels = Config.meta_labels[State.game.meta.type]
	meta_name.text = labels.name
	meta_desc.text = labels.desc
