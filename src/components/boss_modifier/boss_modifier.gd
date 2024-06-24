extends PanelContainer

signal choose

const icon_regen = preload('res://assets/skills/icon_regenerate.svg')
const icon_key = preload('res://assets/icons/icon_vault.svg')
const icon_kernel = preload('res://assets/icons/icon_material.svg')

onready var icon = $H/Icon
onready var label = $H/Label
onready var value = $H/Value
onready var tween = $Tween

var reward

func _ready():
	match reward.type:
		'regen':
			icon.texture = icon_regen
			label.text = 'T_REGENERATE'
			value.text = Util.format_percent(reward.amount)
			modulate = Config.colors.blue
		'kernels':
			icon.texture = icon_kernel
			label.text = 'T_MATERIALS'
			value.text = String(reward.amount)
			modulate = Config.colors.yellow
		'key':
			icon.texture = icon_key
			label.text = 'T_ARCHIVE_KEY'
			value.text = String(reward.amount)
			modulate = Config.colors.magenta
		'item':
			icon.texture = Config.item_types[reward.item].icon
			label.text = "%s (%s)" % [
				tr(Config.item_types[reward.item].names[0]),
				tr(Config.rarity_labels[reward.rarity]),
			]
			modulate = Config.rarity_colors[reward.rarity]


func _gui_input(event):
	if event.is_action_released('ui_accept'):
		SFX.play(SFX.sounds.CLICK)
		emit_signal("choose", reward)


func _on_focus_entered():
	self_modulate = Color.white


func _on_focus_exited():
	self_modulate = Color.black


func _on_mouse_entered():
	grab_focus()
