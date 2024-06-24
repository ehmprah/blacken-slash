extends "res://components/item_base/item_base.gd"

signal action
signal attribute_action

const AttrInteractive = preload('res://components/attribute_interactive/attribute_interactive.tscn')

var container = ''

func update():
	# TODO: fix all these stupid string checks that are called on 
	# EVERY inventory update for ALL items!!!
	expandable = true
	if container == 'gear' || container == 'compare' || container == 'tutorial':
		expanded = true
		expandable = false
	.update()

	# Which was the reason we don't use onready here again?
	var actions = $Container/Details/Actions
	var btn_equip = $Container/Details/Actions/Buttons/Container/Equip
	var btn_salvage = $Container/Details/Actions/Buttons/Container/Salvage
	var btn_vault = $Container/Details/Actions/Buttons/Container/Vault
	var btn_compare = $Container/Details/Actions/Buttons/Container/Compare
	var btn_folder = $Container/Details/Actions/Buttons/Container/Folder
	var btn_folder_remove = $Container/Details/Actions/Buttons/Container/FolderRemove
	
	if container == 'tutorial':
		actions.visible = false
		return
	btn_vault.visible = State.game.difficulty.record >= Config.sector_size && container != 'vault' && State.game.vaultable > 0
	btn_salvage.visible = State.game.difficulty.record >= 2 && State.game.phase != Config.PHASE_TO_VAULT
	btn_equip.visible = State.game.slots[data.type] > 0 && State.game.phase != Config.PHASE_TO_VAULT && container != 'gear'
	btn_compare.visible = State.game.slots[data.type] == 0 && State.game.phase != Config.PHASE_TO_VAULT && container != 'gear'
	btn_folder.visible = container == 'vault' && !data.has('folder')
	btn_folder_remove.visible = container == 'vault' && data.has('folder')
	
	if State.game.phase != Config.PHASE_FROM_VAULT && container == 'vault':
		btn_equip.visible = false
		btn_compare.visible = false

	actions.visible = container != 'compare'
	if State.game.phase == Config.PHASE_TO_VAULT && State.game.vaultable == 0:
		actions.visible = false
	elif (
		btn_equip.visible == false && 
		btn_salvage.visible == false && 
		btn_vault.visible == false && 
		btn_compare.visible == false
	):
		actions.visible = false

	update_actions()


func add_attributes():
	for attribute_data in data.attributes:
		if Config.attributes.has(attribute_data.key):
			var attribute = AttrInteractive.instance()
			attribute.data = attribute_data
			attribute.connect("augment", self, "_handle_augment")
			attribute.connect("reroll", self, "_handle_reroll")
			attributes.add_child(attribute)


func update_actions():
	for attribute in attributes.get_children():
		attribute.update_actions(data, container)


func _on_Equip_button_down():
	emit_signal('action', 'equip', self)


func _on_Compare_button_down():
	emit_signal('action', 'compare', self)


func _on_Salvage_button_down():
	emit_signal('action', 'salvage', self)


func _on_Vault_button_down():
	emit_signal('action', 'vault', self)


func _on_Folder_button_up():
	emit_signal('action', 'folder', self)


func _on_FolderRemove_button_up():
	emit_signal('action', 'folder_remove', self)


func _handle_augment(attribute):
	var price = ceil(Config.globals.augment_price * pow(Config.globals.augment_modifier, data.augments))
	State.game.materials -= price
	for attr in data.attributes:
		if attr.key == attribute.key:
			attr.value += attr.augment_step
			attr.augmented = true
			data.augments += 1
			if attr.value >= attr.augment_max:
				attr.value = attr.augment_max
				State.update_achievement('T_MAXED', 1)
	# Check if the item is now perfect
	var perfected = true
	for attr in data.attributes:
		if attr.has('augment_max') && attr.value < attr.augment_max:
			perfected = false
			break
	if perfected:
		State.update_achievement('T_PERFECTIONIST', 1)
	State.update_achievement('T_ARTISAN', 1)
	State.calculate_gear_effects()
	dirty = true
	update()
	emit_signal("attribute_action")
	refocus(attribute.key)


func _handle_reroll(attribute):
	var price = ceil(Config.globals.reroll_price * pow(Config.globals.reroll_modifier, data.rerolls))
	State.game.materials -= price
	for index in data.attributes.size():
		if data.attributes[index].key == attribute.key:
			RNG.roll_attributes(data, 1, index)
			data.rerolls += 1
			if data.rerolls == 25:
				State.update_achievement('T_SWITCHEROO', 1)
	State.calculate_gear_effects()
	dirty = true
	update()
	emit_signal("attribute_action")
	refocus(attribute.key)


func refocus(key):
	if Controls.needs_focus():
		for attribute in attributes.get_children():
			if (
				'data' in attribute && 
				attribute.data.has('key') && 
				attribute.data.key == key
			):
				attribute.find_next_valid_focus().grab_focus()
