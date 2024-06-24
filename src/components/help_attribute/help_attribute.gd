extends PanelContainer

var data

onready var label = $V/Name/Label
onready var desc = $V/Description/Label
onready var roll_value = $V/Row1/H/RollValue/Value
onready var augment_cap = $V/Row2/H/AugmentCap/Value
onready var augment_step = $V/Row2/H/AugmentStep/Value
onready var item_tool = $V/Row1/H/ItemTypes/Tool
onready var item_module = $V/Row1/H/ItemTypes/Module

func _ready():
	label.text = data.name
	desc.text = data.desc
	if data.has('_roll_value'):
		roll_value.text = Util.format_percent_range(data._roll_value.min, data._roll_value.max)
	else:
		roll_value.text = String(data.value)
	if data.has('augment_max'):
		augment_step.text = Util.format_percent(data.augment_step)
		augment_cap.text = Util.format_percent(data.augment_max)
	item_tool.visible = data._item_types.has(Config.ITEM_TOOL)
	item_module.visible = data._item_types.has(Config.ITEM_MODULE)
