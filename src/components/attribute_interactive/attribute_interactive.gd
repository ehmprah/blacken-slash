extends "res://components/attribute_base/attribute_base.gd"

signal augment
signal reroll

onready var reroll = $Container/Top/Reroll
onready var reroll_cost = $Container/Top/Reroll/Cost
onready var augment = $Container/Top/Augment
onready var augment_cost = $Container/Top/Augment/Cost
onready var progress = $Container/Top/Progress

func update_actions(item, container):
	var conf = Config.attributes[data.key]
	if conf.format == Config.FORMAT_FLAG:
		progress.visible = false
		reroll.visible = false
		augment.visible = false
		return
	elif conf.has('augment_max'):
		progress.value = (data.value - conf._roll_value.min) / (data.augment_max - conf._roll_value.min)
	reroll.visible = container != 'vault' && container != 'loot' && State.game.difficulty.record >= Config.sector_size * 3
	augment.visible = container != 'vault' && container != 'loot' && State.game.difficulty.record >= Config.sector_size * 4
	var materials = State.game.materials
	if item.has('augments'):
		var price = ceil(Config.globals.augment_price * pow(Config.globals.augment_modifier, item.augments))
		augment_cost.text = String(price)
		augment.disabled = materials < price
	if item.has('rerolls'):
		var price = ceil(Config.globals.reroll_price * pow(Config.globals.reroll_modifier, item.rerolls))
		reroll_cost.text = String(price)
		reroll.disabled = materials < price
	if data.has('augmented') && data.augmented:
		reroll.visible = false
	if !data.has('augment_max') || data.value >= data.augment_max:
		augment.visible = false


func _on_Reroll_button_down():
	emit_signal("reroll", data)


func _on_Augment_button_down():
	emit_signal("augment", data)
