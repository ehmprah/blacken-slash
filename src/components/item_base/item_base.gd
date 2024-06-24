extends PanelContainer

const Attribute = preload('res://components/attribute_base/attribute_base.tscn')
const SetSummary = preload('res://components/item_base/set_summary.tscn')
const SkillFX = preload('res://components/skill_fx/skill_fx.tscn')

var data = null
var expanded = false
var expandable = true
var dirty = true
var mask_name = false
var show_salvage_overlay = false
var show_help_icon = true

onready var details = $Container/Details
onready var label = $Container/Top/Container/Labels/Name
onready var label_rarity = $Container/Top/Container/Labels/Info/Rarity
onready var label_slot = $Container/Top/Container/Labels/Info/Slot
onready var icon = $Container/Top/Container/Icon
onready var skill_icon = $Container/Top/Container/Skill
onready var expand_icon = $Container/Top/Container/Expand/TextureRect
onready var expand_btn = $Container/Top/Container/Expand
onready var attributes = $Container/Details/Attributes
onready var salvage_overlay = $SalvageOverlay
onready var set_number = $Container/Top/Container/Icon/SetNumber

func _ready():
	update()
	# warning-ignore:return_value_discarded
	Settings.connect('language_changed', self, 'update_labels')


func update_labels():
	dirty = true
	update()


func update():
	if !dirty:
		return
	Util.delete_children(attributes)
	details.visible = expanded
	expand_icon.flip_v = expanded
	build_name()
	label_rarity.text = Config.rarity_labels[data.rarity]
	label_slot.text = Config.item_types[data.type].names[0]
	icon.texture = Config.item_types[data.type].icon
	modulate = Config.rarity_colors[data.rarity]
	expand_btn.visible = expandable
	salvage_overlay.visible = show_salvage_overlay

	if data.has('skill') && data.skill != null:
		var skill = Config.skills[data.skill]
		skill_icon.visible = expandable && !expanded
		skill_icon.hydrate(skill)
		var fx = SkillFX.instance()
		fx.skill = skill
		fx.show_help_icon = show_help_icon
		attributes.add_child(fx)

	add_attributes()
	
	if data.has('_roll_skill'):
		var attribute = Attribute.instance()
		attribute.data = { 'name': 'T_RANDOM_SCRIPT' }
		attributes.add_child(attribute)
		attribute.get_node('Container/Top/Text/Value').text = '+%d' % data._roll_skill

	if data.has('_add_attributes'):
		for key in data._add_attributes:
			var attribute = Attribute.instance()
			attribute.data = Config.attributes[key]
			attributes.add_child(attribute)

	if data.has('_roll_attributes'):
		var attribute = Attribute.instance()
		attribute.data = { 'name': 'T_RANDOM_VARIABLES' }
		attributes.add_child(attribute)
		attribute.get_node('Container/Top/Text/Value').text = '+%d' % data._roll_attributes

	if data.has('set'):
		add_set_bonuses()

	dirty = false


func add_attributes():
	for attribute_data in data.attributes:
		var attribute = Attribute.instance()
		attribute.data = attribute_data
		attribute.show_help_icon = show_help_icon
		attributes.add_child(attribute)


func _on_Expand_button_down():
	expanded = !expanded
	expand_icon.flip_v = expanded
	details.visible = expanded
	skill_icon.visible = data.has('skill') && !expanded


func add_set_bonuses():
	# Add set number
	var num = 0
	for item in Config.items:
		if item.has('set') && item.set == data.set:
			num += 1
			if item.name == data.name:
				break
	set_number.text = String(num)
	set_number.visible = true
	# Add set summary
	var summary = SetSummary.instance()
	summary.data = data
	attributes.add_child(summary)
	# Add set bonuses
	var amount = 0
	var total = Config.sets[data.set].keys().max()
	if State.game != null && State.game.sets.has(data.set):
		amount = State.game.sets[data.set].size()
	for threshold in Config.sets[data.set].keys():
		var unlocked = amount >= threshold
		for key in Config.sets[data.set][threshold].keys():
			var attribute = Attribute.instance()
			attribute.data = { 
				'name': Config.attributes[key].name, 
				'value': Config.sets[data.set][threshold][key], 
				'format': Config.attributes[key].format
			}
			attribute.headline = '%s %d/%d' % [tr('T_SET_BONUS'), threshold, total]
			attribute.modulate = Color.white if unlocked else Color(0.3, 0.3, 0.3)
			attributes.add_child(attribute)


func build_name():
	var name = ''
	var prefix = Config.locales[Settings.user.general.language].prefix
	if prefix:
		if data.prefix.length():
			name = tr(data.prefix) + ' '
		name += tr(data.name)
		if data.suffix.length():
			name += ' ' + tr(data.suffix)
	else:
		name += tr(data.name)
		if data.prefix.length():
			name += ' ' + tr(data.prefix)
		if data.suffix.length():
			name += ' ' + tr(data.suffix)
	label.text = name
	if mask_name:
		label.text = Util.mask_string(label.text)




func _on_Item_focus_entered():
	print('enter focus!')
	expand_btn.grab_focus()
	
