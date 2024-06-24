extends PanelContainer

signal choose

var upgrade

onready var label = $Container/Attribute/Label
onready var value = $Container/Attribute/Value
onready var who = $Container/Difficulty/Who
onready var modifier = $Container/Difficulty/Modifier

func hydrate():
	who.text = 'T_ENEMY' if upgrade.enemy else 'T_PLAYER'

	modifier.text = "+%d%%" % [upgrade.score * 100]

	var attribute = Config.attributes[upgrade.attribute]
	label.text = attribute.name
	if attribute.format == Config.FORMAT_FLAG:
		value.text = ''
	else:
		value.text = Util.format_value(upgrade.value, attribute.format)


func _gui_input(event):
	if event.is_action_released('ui_accept'):
		SFX.play(SFX.sounds.CLICK)
		emit_signal("choose", upgrade)


func _on_focus_entered():
	self_modulate = Color.white


func _on_focus_exited():
	self_modulate = Color.black


func _on_mouse_entered():
	grab_focus()
