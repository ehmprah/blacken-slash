extends "res://components/title_base/title_base.gd"

signal clear_continue

const PopLabel = preload("res://components/pop_label/pop_label.tscn")
const Confetti = preload("res://components/confetti/confetti.tscn")
const Unlock = preload("res://components/unlock/unlock.tscn")
const IconLevel = preload('res://assets/icons/icon_level.svg')
const IconMaterial = preload('res://assets/icons/icon_material.svg')

var unlockIndex

onready var main = get_node('/root/Main')
onready var ui = $UI
onready var tween = $Tween
onready var materials = $UI/Materials
onready var material_amount = $UI/Materials/Amount
onready var unlocks = $UI/Unlocks
onready var unlocks_container = $UI/Unlocks/Items
onready var unlocks_button = $UI/Unlocks/Continue
onready var unlocks_label = $UI/Unlocks/Controls/Amount
onready var left_button = $UI/Unlocks/Controls/Left
onready var right_button = $UI/Unlocks/Controls/Right

func show_notifications(flags):
	Util.delete_children(unlocks_container)
	materials.visible = false
	unlocks.visible = false
	main.ui.container.add_child(self)
	yield(show(), 'completed')

	# Level progression
	if flags.unlocked:
		show_label('T_LEVEL_RECORD', IconLevel, Config.colors.magenta)
		SFX.play(SFX.sounds.OPEN_TREASURE)
		yield(get_tree().create_timer(0.75), "timeout")
	elif flags.beaten:
		show_label('T_LEVEL_BEATEN', IconLevel, Config.colors.magenta)
		SFX.play(SFX.sounds.OPEN_TREASURE)
		yield(get_tree().create_timer(0.75), "timeout")

	# Material bonuses
	var bonus = 0
	materials.visible = flags.pacifist || flags.first_strike || flags.elusive
	material_amount.text = '0'
	if flags.pacifist:
		show_label('T_PACIFIST', IconMaterial, Config.colors.yellow)
		SFX.play(SFX.sounds.OPEN_TREASURE)
		tween.interpolate_method(self, 'update_materials', bonus, bonus + 25, 0.5)
		tween.start()
		bonus += 25
		yield(get_tree().create_timer(0.75), "timeout")
	if flags.first_strike:
		show_label('T_FIRST_STRIKE', IconMaterial, Config.colors.yellow)
		SFX.play(SFX.sounds.OPEN_TREASURE)
		tween.interpolate_method(self, 'update_materials', bonus, bonus + 50, 0.5)
		tween.start()
		bonus += 50
		yield(get_tree().create_timer(0.75), "timeout")
	if flags.elusive:
		show_label('T_ELUSIVE', IconMaterial, Config.colors.yellow)
		SFX.play(SFX.sounds.OPEN_TREASURE)
		tween.interpolate_method(self, 'update_materials', bonus, bonus + 25, 0.5)
		tween.start()
		bonus += 25
		yield(get_tree().create_timer(0.75), "timeout")

	# Handle unlocks
	var unlock_amount = 0
	for item in State.game.loot:
		var rarity_key = 'rarity_' + String(item.rarity)
		if State.profile.decrypted[rarity_key] == false:
			State.profile.decrypted[rarity_key] = true
			add_unlock({ 'type': 'rarity', 'key': item.rarity })
			unlock_amount += 1
		var type_key = 'type_' + String(item.type)
		if State.profile.decrypted[type_key] == false:
			State.profile.decrypted[type_key] = true
			add_unlock({ 'type': 'item_type', 'key': item.type })
			unlock_amount += 1
		if item.has('skill') && State.profile.decrypted[item.skill] == false:
			State.profile.decrypted[item.skill] = true
			add_unlock({ 'type': 'skill', 'key': item.skill })
			unlock_amount += 1
		for attribute in item.attributes:
			if (
				attribute.has('key') && 
				!attribute.key.begins_with('flag') && 
				State.profile.decrypted[attribute.key] == false
			):
				State.profile.decrypted[attribute.key] = true
				add_unlock({ 'type': 'attribute', 'key': attribute.key })
				unlock_amount += 1
	
	if unlock_amount > 0:
		materials.visible = false
		unlockIndex = 0
		unlocks_label.text = '1 / ' + String(unlock_amount)
		left_button.visible = unlock_amount > 1
		right_button.visible = unlock_amount > 1
		unlocks.visible = true
		unlocks_container.get_child(0).show()
		SFX.play(SFX.sounds.TREASURE_DROP)
		if Controls.needs_focus():
			unlocks_button.grab_focus()
	else:
		yield(_on_Continue_button_down(), 'completed')


func add_unlock(data):
	var unlock = Unlock.instance()
	unlock.data = data
	unlock.visible = false
	unlocks_container.add_child(unlock)


func cycle_unlocks(direction):
	var end = unlocks_container.get_child_count() - 1
	unlocks_container.get_child(unlockIndex).visible = false
	unlockIndex += direction
	if unlockIndex < 0:
		unlockIndex = end
	if unlockIndex > end:
		unlockIndex = 0
	unlocks_label.text = String(unlockIndex + 1) + ' / ' + String(end + 1)
	unlocks_container.get_child(unlockIndex).show()


func show_label(text, icon, color = Color.white):
	var center = ui.rect_global_position + ui.rect_size / 2
	var particles = Confetti.instance()
	particles.position = center
	particles.modulate = color
	add_child(particles)
	var drop = PopLabel.instance()
	drop.position = center
	drop.icon = icon
	drop.text = text
	drop.duration = 0.5
	drop.modulate = color
	add_child(drop)


func update_materials(amount):
	material_amount.text = String(floor(amount))


func _on_Continue_button_down():
	yield(hide(), 'completed')
	emit_signal('clear_continue')
	main.ui.container.remove_child(self)
