extends HBoxContainer

const Modifier = preload("res://components/boss_modifier/boss_modifier.tscn")

onready var main = get_node('/root/Main')
onready var animation = $AnimationPlayer
onready var options = $V/Modifiers
onready var title = $V/Top/Control/Title
onready var desc = $V/Top/Description

var selected

func show():
	Util.delete_children(options)
	title.bbcode_text = "[center][wave amp=10 freq=5]%s[/wave][/center]" % tr('T_QUANTUM_GATE').to_upper()
	
	var candidates = Config.gate_rewards.duplicate()
	for n in 3:
		var mod = Modifier.instance()
		var index = RNG.array_random_index(candidates)
		mod.reward = RNG.array_random(candidates[index])
		mod.connect("choose", self, "_on_choose")
		options.add_child(mod)
		candidates.remove(index)
	visible = true
	main.ui.container.add_child(self)
	if Controls.needs_focus():
		options.get_child(0).grab_focus()
	animation.play("Enter")
	yield(animation, 'animation_finished')


func _on_choose(reward):
	match reward.type:
		'regen':
				State.game.damage -= reward.amount
				if State.game.damage < 0:
					State.game.damage = 0
				main.ui.inventory.update_damage()
				main.game.player.hydrate(null)
				SFX.play(SFX.sounds.BUFF)
		'kernels':
			State.game.materials += reward.amount
			main.ui.inventory.update_currencies()
		'key':
			State.game.vaultable += reward.amount
			SFX.play(SFX.sounds.ITEM_DROP_UNIQUE)
			main.ui.inventory.update()
		'item':
			var item = RNG.roll_item(reward.item, reward.rarity)
			main.ui.inventory.add_item('loot', item)
			State.game.loot.append(item)
			SFX.play(SFX.sounds.ITEM_DROP_UNIQUE)
			main.ui.inventory.update()
	next()


func next():
	State.game.phase = Config.PHASE_DIFFICULTY
	State.game.difficulty.upgrades = 1
	if main.game.player.state.attributes.flag_double_difficulty > 0:
		State.game.difficulty.upgrades = 2
	State.save_game()
	animation.play_backwards("Enter")
	yield(animation, "animation_finished")
	main.ui.container.remove_child(self)
	main.show_screen()
