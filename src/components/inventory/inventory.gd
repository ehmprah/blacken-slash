extends Control

signal health_changed

const Item = preload("res://components/item_interactive/item_interactive.tscn")
const PopLabel = preload("res://components/pop_label/pop_label.tscn")
const MaterialIcon = preload('res://assets/icons/icon_material.svg')
const Confetti = preload("res://components/confetti/confetti.tscn")
const Folder = preload("res://components/folder/folder.tscn")
const FolderSelect = preload("res://components/folder_select/folder_select.tscn")

var processing = false

onready var tab_controls = {
	'loot': $Panel/Container/TabControls/Container/Loot,
	'vault': $Panel/Container/TabControls/Container/Vault,
	'shop': $Panel/Container/TabControls/Container/Shop,
}

onready var tabs = {
	'loot': $Panel/Container/Tabs/Loot,
	'gear': $Panel/Container/Tabs/Gear,
	'shop': $Panel/Container/Tabs/Shop,
	'vault': $Panel/Container/Tabs/Vault,
	'summary': $Panel/Container/Tabs/Summary,
}

onready var containers = {
	'loot': $Panel/Container/Tabs/Loot/Margin/Container/List,
	'gear': $Panel/Container/Tabs/Gear/Margin,
	'vault': $Panel/Container/Tabs/Vault/Margin/List,
}

onready var gear = {
	Config.ITEM_TOOL: [
		$Panel/Container/GearControls/Container/s00,
		$Panel/Container/GearControls/Container/s01,
		$Panel/Container/GearControls/Container/s02,
	],
	Config.ITEM_MODULE: [
		$Panel/Container/GearControls/Container/s10,
		$Panel/Container/GearControls/Container/s11,
		$Panel/Container/GearControls/Container/s12,
		$Panel/Container/GearControls/Container/s13,
		$Panel/Container/GearControls/Container/s14,
		$Panel/Container/GearControls/Container/s15,
	],
}

onready var btns = {
	'regenerate': $Panel/Container/Tabs/Shop/Regenerate,
	'buy_vault_slot': $Panel/Container/Tabs/Shop/BuyKey,
	'gamble': $Panel/Container/Tabs/Shop/Gamble,
}

onready var tabbable = [
	$Panel/Container/GearControls/Container/Summary,
	$Panel/Container/GearControls/Container/s00,
	$Panel/Container/GearControls/Container/s01,
	$Panel/Container/GearControls/Container/s02,
	$Panel/Container/GearControls/Container/s10,
	$Panel/Container/GearControls/Container/s11,
	$Panel/Container/GearControls/Container/s12,
	$Panel/Container/GearControls/Container/s13,
	$Panel/Container/GearControls/Container/s14,
	$Panel/Container/GearControls/Container/s15,
	$Panel/Container/TabControls/Container/Loot,
	$Panel/Container/TabControls/Container/Shop,
	$Panel/Container/TabControls/Container/Vault,
]

# TODO: move other buttons to group var
# TODO: clean up, not all of these are used!
onready var main = get_node('/root/Main')
onready var gear_btns = $Panel/Container/GearControls/Container
onready var gear_percent = $Panel/Container/GearControls/Container/Summary/Percent/Icon
onready var gear_damage = $Panel/Container/GearControls/Container/Summary/GearIcon/Damage
onready var btn_salvage = $Panel/Container/Bottom/Container/Salvage
onready var btn_auto_equip = $Panel/Container/Bottom/Container/AutoEquip
onready var btn_next = $Panel/Container/Bottom/Container/Next
onready var btn_finish = $Panel/Container/Bottom/Container/Finish
onready var btn_ladder = $Panel/Container/Bottom/Container/Ladder
onready var materials = $Panel/Container/Bottom/Container/Materials/Amount
onready var gear_summary_button = $Panel/Container/GearControls/Container/Summary
onready var vault = $Panel/Container/Bottom/Container/Vault
onready var vault_amount = $Panel/Container/Bottom/Container/Vault/Amount
onready var regeneration_price = $Panel/Container/Tabs/Shop/Regenerate/H/Amount
onready var vault_slot_price = $Panel/Container/Tabs/Shop/BuyKey/H/Amount
onready var gambling_price = $Panel/Container/Tabs/Shop/Gamble/H/Amount
onready var beeper = $Panel/Container/Tabs/Shop/Beeper
onready var beeper_label = $Panel/Container/Tabs/Shop/Beeper/Label
onready var loot_amount = $Panel/Container/TabControls/Container/Loot/Amount
onready var focus_btns = [btn_salvage, btn_auto_equip, btn_next, btn_finish]

func _ready():
	for type in gear.keys():
		for button in gear[type]:
			button.hint_tooltip = tr('T_SLOT') + ': ' +  tr(Config.item_types[type].names[0])
	regeneration_price.text = String(Config.globals.regenerate_price)
	gambling_price.text = String(Config.globals.gamble_price)
	vault_slot_price.text = String(Config.globals.vault_slot_price)
	Controls.connect('controls_changed', self, 'ui_focus')
	RNG.connect('item_found', self, '_on_loot_found')


func ui_focus(needs_focus):
	if visible && needs_focus:
		for btn in focus_btns:
			if btn.visible:
				return btn.grab_focus()


func _input(_event):
	if processing:
		accept_event()


func _unhandled_input(event):
	if event.is_action_released('mode_right'):
		cycle_tabs(1)
	elif event.is_action_released('mode_left'):
		cycle_tabs(-1)


func cycle_tabs(direction):
	var end = tabbable.size() - 1
	var index
	for i in tabbable.size():
		if tabbable[i].is_pressed():
			index = i
			break
	while true:
		index = Util.cycle_index(index, direction, end)
		if tabbable[index].disabled == false:
			tabbable[index].grab_focus()
			tabbable[index].pressed = true
			break


func _physics_process(_delta):
	if visible:
		var scroll = Input.get_axis("ui_page_up", "ui_page_down")
		if scroll != 0:
			if tabs.loot.visible:
				tabs.loot.scroll_vertical += scroll * 20
			if tabs.gear.visible:
				tabs.gear.scroll_vertical += scroll * 20
			if tabs.vault.visible:
				tabs.vault.scroll_vertical += scroll * 20
			if tabs.summary.visible:
				tabs.summary.scroll_vertical += scroll * 20


func reset():
	for container in containers:
		Util.delete_children(containers[container])


func show():
	btn_ladder.visible = State.game.type == Config.GAME_LADDER
	tab_controls.vault.visible = State.game.difficulty.record >= Config.sector_size
	tab_controls.loot.visible = State.game.phase != Config.PHASE_FROM_VAULT
	tab_controls.shop.visible = State.game.phase != Config.PHASE_FROM_VAULT
	tab_controls.shop.disabled = State.game.difficulty.record < Config.sector_size * 2
	tab_controls.shop.text = 'T_OFFLINE' if State.game.difficulty.record < Config.sector_size * 2 else 'T_SHOP'
	update_damage()
	update_currencies()
	gear_damage.visible = State.game.phase == Config.PHASE_LOOT
	match State.game.phase:
		Config.PHASE_FROM_VAULT:
			tab_controls.vault.pressed = true
		Config.PHASE_LOOT:
			order_loot()
			if containers.loot.get_child_count() > 0:
				tab_controls.loot.pressed = true
			else:
				gear_summary_button.pressed = true
		Config.PHASE_TO_VAULT:
			# As a default we show the loot tab
			tab_controls.loot.pressed = true
			# Othwerise show the first equipped piece of gear if any
			for index in range(2, gear_btns.get_child_count()):
				var btn = gear_btns.get_child(index)
				if btn.disabled == false:
					btn.pressed = true
					break
	$AnimationPlayer.play("Enter")
	visible = true
	SFX.play_variant('swoosh', 0.2)
	yield($AnimationPlayer, "animation_finished")
	btn_next.grab_focus()
	ui_focus(Controls.needs_focus())


func update_damage():
	var new_height = State.game.damage * 46
	gear_damage.rect_size.y = new_height
	gear_damage.rect_position.y = 53 - new_height
	emit_signal('health_changed')
	$Panel/Container/Tabs/Summary/Margin/GearSummary.update()


func hide():
	$AnimationPlayer.play_backwards("Enter")
	yield($AnimationPlayer, "animation_finished")
	visible = false


func hydrate():
	for key in ['loot', 'gear']:
		for data in State.game[key]:
			add_item(key, data)
	hydrate_archive()
	update()


func hydrate_archive():
	# Get all available folders
	var folders = {}
	for item in State.profile.vault:
		if item.has('folder') && !folders.has(item.folder):
			folders[item.folder] = null
	# Create folder nods
	for folder in folders:
		var f = Folder.instance()
		f.label = folder
		folders[folder] = f
		containers.vault.add_child(f)
	# Add children
	for data in State.profile.vault:
		if !data.has('folder'):
			add_item('vault', data)
		else:
			var item = Item.instance()
			item.data = data
			item.container = 'vault'
			folders[data.folder].add_item(item)
			item.connect("action", self, "execute_action")
			item.connect("attribute_action", self, "update")


func refresh_archive():
	Util.delete_children(containers.vault)
	hydrate_archive()


func add_item(container, data):
	var item = Item.instance()
	item.data = data
	item.container = container
	if container == 'loot':
		item.expanded = true
	containers[container].add_child(item)
	item.connect("action", self, "execute_action")
	item.connect("attribute_action", self, "update_currencies")
	item.connect("attribute_action", self, "update_items")


func order_loot():
	var pos = 0
	for rarity in range(Config.RARITY_SET, Config.RARITY_COMMON, -1):
		for item in containers.loot.get_children():
			if item.data.rarity == rarity:
				containers.loot.move_child(item, pos)
				pos += 1


func update():
	update_currencies()
	btn_next.visible = true
	btn_finish.visible = false
	var loot_count = containers.loot.get_child_count()
	loot_amount.text = String(loot_count)
	loot_amount.visible = loot_count > 0
	# If we have no more loot, disable the loot tab and switch to summary
	tab_controls.loot.disabled = loot_count == 0
	if loot_count == 0 && tabs.loot.visible:
		gear_summary_button.pressed = true
		gear_summary_button.grab_focus()
	match State.game.phase:
		Config.PHASE_FROM_VAULT:
			btn_next.text = 'T_START_RUN'
			btn_salvage.visible = false
			btn_auto_equip.visible = false
		Config.PHASE_LOOT, Config.PHASE_BONUS, Config.PHASE_DIFFICULTY:
			btn_next.text = '%s %d' % [tr('T_LEVEL'), State.game.difficulty.beaten + 1]
			btn_auto_equip.visible = false
			if loot_count > 0:
				for item in containers.loot.get_children():
					if State.game.slots[item.data.type] > 0:
						btn_auto_equip.visible = true
			btn_salvage.visible = loot_count > 0 && State.game.difficulty.record >= 2
			btn_next.visible = loot_count == 0
		Config.PHASE_TO_VAULT:
			btn_next.visible = false
			btn_finish.visible = true
			tab_controls.vault.visible = true
			btn_salvage.visible = false

	update_items()


func update_currencies():
	materials.text = Util.format_k(State.game.materials)
	vault_amount.text = String(State.game.vaultable)
	vault.visible = State.game.vaultable > 0
	update_shop_buttons()


func update_shop_buttons():
	btns.regenerate.disabled = State.game.materials < Config.globals.regenerate_price || State.game.damage == 0
	btns.buy_vault_slot.disabled = State.game.materials < Config.globals.vault_slot_price
	btns.gamble.disabled = State.game.materials < Config.globals.gamble_price


func update_items():
	for container in containers:
		for item in containers[container].get_children():
			item.update()
	# TODO: only call this where actually needed, not on every update!
	update_gear_controls()


# TODO: rewrite this to use slot numbers, maybe even on the items themselves
func update_gear_controls():
	for type in gear.keys():
		for button in gear[type]:
			button.disabled = true
			button.focus_mode = FOCUS_NONE
			button.modulate = Config.colors.blue
	var slots = {
		Config.ITEM_TOOL: 0,
		Config.ITEM_MODULE: 0,
	}
	for item in State.game.gear:
		var button = gear[item.type][slots[item.type]]
		button.disabled = false
		button.focus_mode = FOCUS_ALL
		button.modulate = Config.rarity_colors[item.rarity]
		slots[item.type] += 1


func execute_action(action, item):
	match action:
		'vault':
			var gear_updated = item.container == 'gear'
			move_item(item, 'vault')
			if gear_updated:
				after_gear_change(item)
			if item.data.has('folder'):
				refresh_archive()
			State.game.vaultable -= 1
			update()
			State.update_achievement('T_LEGACY', 1)
		'compare':
			main.ui.compare.hydrate(item)
			main.ui.compare.show()
		'equip':
			var from_vault = item.container == 'vault'
			var from_folder = from_vault && item.data.has('folder')
			State.game.slots[item.data.type] -= 1
			move_item(item, 'gear')
			State.calculate_gear_effects()
			set_siblings_dirty(item)
			update()
			if from_folder:
				refresh_archive()
			elif from_vault:
				main.ui.notification.show('T_DIFFICULTY', '+1')
			# Save the game so we're not losing progress here if we don't continue
			if State.game.phase == Config.PHASE_FROM_VAULT:
				State.save_game()
		'salvage':
			var from_folder = item.container == 'vault' && item.data.has('folder')
			var gear_updated = item.container == 'gear'
			salvage(item)
			if gear_updated:
				after_gear_change(item)
			if from_folder:
				refresh_archive()
		'folder':
			var popup = FolderSelect.instance()
			popup.data = item.data
			get_parent().add_child(popup)
		'folder_remove':
			item.data.erase('folder')
			State.save_profile()
			refresh_archive()
	if action != 'folder':
		ui_focus(Controls.needs_focus())


func after_gear_change(item):
	State.game.slots[item.data.type] += 1
	State.calculate_gear_effects()
	set_siblings_dirty(item)
	tab_controls.loot.pressed = true


func salvage(item, animate = true):
	State.update_achievement('T_PILE_OF_CRAP', 1)
	SFX.play(SFX.sounds.SALVAGE)
	# add materials
	var gained = RNG.roll_salvage_materials(item.data)
	State.add_materials(gained)
	materials.text = Util.format_k(State.game.materials)
	update_actions()
	# Update state
	if item.container != 'vault':
		State.game[item.container].erase(item.data)
	else:
		State.profile.vault.erase(item.data)
	# add pop label
	var drop = PopLabel.instance()
	drop.position = materials.rect_global_position + Vector2(30, -30)
	drop.icon = MaterialIcon
	drop.text = String(gained)
	drop.duration = 0.5
	drop.modulate = Config.colors.yellow
	main.ui.container.add_child(drop)
	if animate:
		# animate removal
		$Tween.interpolate_property(item, "rect_position", item.rect_position, item.rect_position - Vector2(768, 0), 0.25)
		$Tween.interpolate_property(item, "modulate", item.modulate, Color(0, 0, 0, 0), 0.25)
		$Tween.start()
		yield($Tween, "tween_all_completed")
		$Tween.remove_all()
		$Tween.stop_all()
	# remove node
	item.get_parent().remove_child(item)
	item.queue_free()
	update()


func move_item(item, container):
	# Move item node
	item.get_parent().remove_child(item)
	containers[container].add_child(item)
	if item.container == 'gear':
		item.visible = true
	if item.container == 'loot':
		update()
	# Update state
	var new_data = item.data.duplicate(true)
	if container == 'vault':
		item.expanded = false
		new_data.expanded = false
	new_data.container = container
	# Delete old state
	if item.container == 'vault':
		State.game.difficulty.upgrades += 1
		State.profile.vault.erase(item.data)
		State.save_profile()
	else:
		State.game[item.container].erase(item.data)
	if container == 'vault':
		State.profile.vault.append(new_data)
		State.save_profile()
	else:
		State.game[container].append(new_data)
	# Hydrate the item accordingly
	item.data = new_data
	item.container = container
	item.dirty = true


func set_siblings_dirty(item):
	if item.data.has('set'):
		for child in containers.gear.get_children():
			if child.data.has('set') && child.data.set == item.data.set:
				child.dirty = true


func update_actions():
	for container in ['gear', 'loot']:
		for item in containers[container].get_children():
			item.update_actions()


func _on_Compare_replace(replacement, old):
	for item in containers.gear.get_children():
		if item.data == old:
			State.game.slots[item.data.type] += 1
			move_item(item, 'loot')
	execute_action('equip', replacement)


func _on_ButtonMenu_button_down():
	main.ui.menu.show()


func _on_Replay_button_down():
	yield(hide(), 'completed')
	main.inventory_next()


func _on_Finish_button_down():
	yield(hide(), 'completed')
	main.end_game()


func show_tab(new):
	for tab in tabs.values():
		tab.visible = false
		tab.set_process_input(false)
	new.visible = true
	new.set_process_input(true)


func show_gear(button_pressed, type, index):
	get_node('Panel/Container/GearControls/Container/s' + String(type) + String(index) + '/Triangle').visible = button_pressed
	if button_pressed:
		show_tab(tabs.gear)
		var slots = {
			Config.ITEM_TOOL: 0,
			Config.ITEM_MODULE: 0,
		}
		for item in containers.gear.get_children():
			item.visible = item.data.type == type && slots[type] == index
			slots[item.data.type] += 1


func _on_Loot_toggled(button_pressed):
	$Panel/Container/TabControls/Container/Loot/Triangle.visible = button_pressed
	if button_pressed:
		show_tab(tabs.loot)


func _on_Vault_toggled(button_pressed):
	$Panel/Container/TabControls/Container/Vault/Triangle.visible = button_pressed
	if button_pressed:
		show_tab(tabs.vault)


func _on_Summary_toggled(button_pressed):
	if button_pressed:
		show_tab(tabs.summary)
		gear_percent.modulate = Color.white
	else: 
		gear_percent.modulate = Color(0.4, 0.4, 0.4)


func _on_Summary_mouse_entered():
	if !gear_summary_button.is_pressed():
		gear_percent.modulate = Color(0.7, 0.7, 0.7)


func _on_Summary_mouse_exited():
	if !gear_summary_button.is_pressed():
		gear_percent.modulate = Color(0.4, 0.4, 0.4)


func _on_Ladder_button_down():
	main.ui.ladder.show()


func auto_equip():
	processing = true
	btn_auto_equip.disabled = true
	for rarity in range(Config.RARITY_SET, -1, -1):
		for item in containers.loot.get_children():
			if item.data.rarity == rarity && State.game.slots[item.data.type] > 0:
				SFX.play(SFX.sounds.ITEM_DROP)
				execute_action('equip', item)
				yield(get_tree().create_timer(0.5), "timeout")
	processing = false
	btn_auto_equip.disabled = false
	ui_focus(Controls.needs_focus())


func press_loot_button():
	tab_controls.loot.pressed = true


func salvage_all():
	tab_controls.loot.pressed = true
	processing = true
	var index = containers.loot.get_child_count() - 1
	while index > -1:
		var child = containers.loot.get_child(index)
		index -= 1
		if !child is Button:
			yield(salvage(child), 'completed')
	processing = false
	ui_focus(Controls.needs_focus())

func next():
	yield(hide(), 'completed')
	main.inventory_next()


func _on_Shop_toggled(button_pressed):
	$Panel/Container/TabControls/Container/Shop/Triangle.visible = button_pressed
	if button_pressed:
			show_tab(tabs.shop)
			beeper_label.text = Config.beeper_thoughts[randi() % Config.beeper_thoughts.size()]
			beeper.show()


func _on_Gamble_button_down():
	State.game.materials -= Config.globals.gamble_price
	var loot = RNG.roll_loot({ 'items': { 'chance': 1, 'max': 1 }, 'materials': { 'chance': 0, 'max': 0 }})
	for item in loot.items:
		SFX.play(SFX.sounds.ITEM_DROP_UNIQUE if item.rarity > Config.RARITY_RARE else SFX.sounds.ITEM_DROP)
		var drop = PopLabel.instance()
		drop.position = btns.gamble.rect_global_position + btns.gamble.rect_size / 2
		drop.text = Config.item_types[item.type].names[0]
		drop.icon = Config.item_types[item.type].icon
		drop.duration = 1
		drop.modulate = Config.rarity_colors[item.rarity]
		add_child(drop)
		if item.rarity > Config.RARITY_RARE:
			var particles = Confetti.instance()
			particles.position = btns.gamble.rect_global_position + btns.gamble.rect_size / 2
			particles.modulate = Config.rarity_colors[item.rarity]
			add_child(particles)
	update()


func _on_Regenerate_button_down():
	State.game.materials -= Config.globals.regenerate_price
	State.game.damage = 0
	get_node('/root/Main/Game/Entities/Player').hydrate(null)
	update_damage()
	update()


func _on_BuySlot_button_down():
	State.game.materials -= Config.globals.vault_slot_price
	State.game.vaultable += 1
	update()


func _on_Tabs_focus_entered():
	for tab in tabs:
		if tabs[tab].visible:
			tabs[tab].find_next_valid_focus().grab_focus()
			if tabs[tab] is ScrollContainer:
				tabs[tab].scroll_vertical = 0


func _on_loot_found(item):
	add_item('loot', item)
