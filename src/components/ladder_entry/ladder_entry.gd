extends PanelContainer

const Item = preload("res://components/item_base/item_base.tscn")
const IconDead = preload('res://assets/icons/icon_dead.svg')

var data
var expanded = false

onready var number = $Container/Top/Container/Who/Position/Number
onready var player = $Container/Top/Container/Who/Name
onready var difficulty = $Container/Top/Container/Difficulty/Amount
onready var score = $Container/Top/Container/Score/Amount
onready var status = $Container/Top/Container/Who/Position/Icon
onready var gear = $Container/Gear
onready var items = $Container/Gear/List
onready var expand_icon = $Container/Top/Container/Expand/TextureRect

func _ready():
	number.text = '#' + String(data.number)
	player.text = data.name.http_unescape()
	difficulty.text = String(data.difficulty)
	score.text = String(data.score)
	if data.dead:
		status.texture = IconDead
	# sort items
	var order = {}
	for type in Config.slots.keys():
		order[type] = []
	for item in data.gear:
		order[item.type].append(item)
	# and add them
	for type in order.keys():
		for item_data in order[type]:
			var item = Item.instance()
			item.data = item_data
			items.add_child(item)


func _on_Expand_button_down():
	expanded = !expanded
	expand_icon.flip_v = expanded
	gear.visible = expanded

