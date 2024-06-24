extends HBoxContainer

onready var main = get_node('/root/Main')
onready var animation = $AnimationPlayer
onready var title = $V/Top/Control/Title
onready var left = $V/Modifiers/AmountLeft
onready var options = [
	$V/Modifiers/M1,
	$V/Modifiers/M2,
	$V/Modifiers/M3,
]

func show():
	# Update the headline in case the language was switched in the meantime
	title.bbcode_text = "[center][wave amp=10 freq=5]%s[/wave][/center]" % tr('T_CHOOSE_DIFFICULTY').to_upper()
	roll_options()
	update_counter()
	# Animate display
	main.ui.overlays.add_child(self)
	options[0].grab_focus()
	animation.play("Enter")
	yield(animation, 'animation_finished')


func update_counter():
	var remaining = State.game.difficulty.upgrades - 1
	left.visible = remaining > 0
	left.text = "+%d" % remaining


func roll_options():
	var candidates = Config.gate_difficulty.duplicate()
	for i in range(candidates.size()-1, -1, -1):
		var upgrade = candidates[i]
		var target = 'enemy' if upgrade.enemy else 'player'
		if (
			upgrade.attribute.begins_with('flag_') &&
			State.game.modifiers[target].has(upgrade.attribute)
		):
			candidates.remove(i)
	var roll = RNG.array_random_n(candidates, 3)
	for n in 3:
		options[n].visible = false
		options[n].upgrade = roll[n]
		options[n].hydrate()
		options[n].visible = true


func _on_choose(upgrade):
	var target = 'enemy' if upgrade.enemy else 'player'
	if !State.game.modifiers[target].has(upgrade.attribute):
		State.game.modifiers[target][upgrade.attribute] = 0
	State.game.modifiers[target][upgrade.attribute] += upgrade.value
	if upgrade.enemy == false:
		State.calculate_gear_effects()
	State.game.score_modifier += upgrade.score
	SFX.play(SFX.sounds.DEBUFF)
	State.game.difficulty.upgrades -= 1
	if State.game.difficulty.upgrades > 0:
		update_counter()
		roll_options()
		options[0].grab_focus()
	else:
		Music.fade(Music.OFF, true)
		State.game.phase = Config.PHASE_LOOT
		State.save_game()
		animation.play_backwards("Enter")
		yield(animation, "animation_finished")
		main.ui.overlays.remove_child(self)
		main.show_screen()
	
