extends PanelContainer

var data
onready var label = $Container/Top/Text/Labels/Name
onready var icons = [
	$Container/Top/Text/TextureRect,
	$Container/Top/Text/TextureRect2,
	$Container/Top/Text/TextureRect3,
	$Container/Top/Text/TextureRect4,
	$Container/Top/Text/TextureRect5,
	$Container/Top/Text/TextureRect6,
	$Container/Top/Text/TextureRect7,
]

func _ready():
	label.text = data.set
	var index = 0
	for item in Config.items:
		if item.has('set') && item.set == data.set:
			icons[index].texture = Config.item_types[item.type].icon
			icons[index].modulate = Color(0.5, 0.5, 0.5)
			icons[index].visible = true
			if (
				State.game && 
				State.game.sets.has(item.set) && 
				State.game.sets[item.set].has(item.name)
			):
				icons[index].modulate = Color.white
			index += 1


func update_actions(_item, _container):
	pass
