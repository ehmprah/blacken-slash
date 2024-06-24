extends MarginContainer

const icons = {
	0: preload('res://assets/icons/icon_tool.svg'),
	1: preload('res://assets/icons/icon_module.svg'),
	'vault': preload('res://assets/icons/icon_vault.svg'),
	'salvage': preload('res://assets/icons/icon_material.svg'),
	'augment': preload('res://assets/icons/icon_augment.svg'),
	'reroll': preload('res://assets/icons/icon_reroll.svg'),
	'shop': preload('res://assets/icons/icon_shop.svg'),
	'ladder': preload('res://assets/icons/icon_ladder.svg'),
	'weather_warning': preload('res://assets/icons/icon_warning.svg'),
	'attribute_summary': preload('res://assets/icons/icon_percent.svg'),
}

var data

onready var panel = $Panel
onready var type = $Panel/V/PanelContainer/H/V/Type
onready var icon = $Panel/V/PanelContainer/H/Icon
onready var skill_icon = $Panel/V/PanelContainer/H/SkillIcon
onready var title = $Panel/V/PanelContainer/H/V/Title
onready var description = $Panel/V/PanelContainer/H/V/Description
onready var tween = $Tween

func _ready():
	match data.type:
		'feature':
			icon.visible = true
			icon.texture = icons[data.key]
			type.text = 'T_UNLOCKED_FEATURE'
			title.text = 'T_' + data.key.to_upper()
			description.text = 'T_' + data.key.to_upper() + '_DESCRIPTION'
		'item_type':
			icon.visible = true
			icon.texture = icons[data.key]
			type.text = 'T_UNLOCKED_ITEM_TYPE'
			if data.key == Config.ITEM_TOOL:
				title.text = 'T_TRANSMITTER'
				description.text = 'T_TRANSMITTER_DESCRIPTION'
			else:
				title.text = 'T_CIRCUIT'
				description.text = 'T_CIRCUIT_DESCRIPTION'
		'attribute':
			var attribute = Config.attributes[data.key]
			type.text = 'T_UNLOCKED_VARIABLE'
			title.text = attribute.name
			description.text = attribute.desc
		'rarity':
			type.text = 'T_UNLOCKED_RARITY'
			title.text = Config.rarity_labels[data.key]
			description.text = tr(Config.rarity_labels[data.key] + '_DESCRIPTION')
			title.modulate = Config.rarity_colors[data.key]
			description.modulate = Config.rarity_colors[data.key]
		'skill':
			var skill = Config.skills[data.key]
			type.text = 'T_UNLOCKED_SCRIPT'
			title.text = skill.name
			description.text = skill.desc
			skill_icon.visible = true
			skill_icon.hydrate(skill)


func show():
	visible = true
	rect_pivot_offset = rect_size / 2
	tween.interpolate_property(self, "rect_scale", Vector2(1, 1), Vector2(1.05, 1.05),
			0.075, Tween.TRANS_CUBIC, Tween.EASE_IN)
	tween.interpolate_property(self, "rect_scale", Vector2(1.05, 1.05), Vector2(1, 1),
			0.075, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.075)
	tween.start()
