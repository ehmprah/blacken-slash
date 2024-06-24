extends Control

var player

onready var main = get_node('/root/Main')
onready var animation = $AnimationPlayer
onready var progress = $Top/H/Center/Progress
onready var warning = $Top/H/Center/Warning
onready var buttons = {
	'move': $Bottom/ButtonsBar/Buttons/ButtonMove,
	'skill1': $Bottom/ButtonsBar/Buttons/ButtonSkill1,
	'skill2': $Bottom/ButtonsBar/Buttons/ButtonSkill2,
	'skill3': $Bottom/ButtonsBar/Buttons/ButtonSkill3,
	'idle': $Bottom/ButtonsBar/Buttons/ButtonIdle,
}
onready var mode_btns = [
	$Bottom/ButtonsBar/Buttons/ButtonMove,
	$Bottom/ButtonsBar/Buttons/ButtonSkill1,
	$Bottom/ButtonsBar/Buttons/ButtonSkill2,
	$Bottom/ButtonsBar/Buttons/ButtonSkill3,
]
onready var skillcost = {
	'skill1': $Bottom/ButtonsBar/Buttons/ButtonSkill1/Cost,
	'skill2': $Bottom/ButtonsBar/Buttons/ButtonSkill2/Cost,
	'skill3': $Bottom/ButtonsBar/Buttons/ButtonSkill3/Cost,
}
onready var ap = [
	$Bottom/ButtonsBar/ActionPoints/AP,
	$Bottom/ButtonsBar/ActionPoints/AP2,
	$Bottom/ButtonsBar/ActionPoints/AP3,
	$Bottom/ButtonsBar/ActionPoints/AP4,
	$Bottom/ButtonsBar/ActionPoints/AP5,
	$Bottom/ButtonsBar/ActionPoints/AP6,
	$Bottom/ButtonsBar/ActionPoints/AP7,
	$Bottom/ButtonsBar/ActionPoints/AP8,
	$Bottom/ButtonsBar/ActionPoints/AP9,
	$Bottom/ButtonsBar/ActionPoints/AP10,
]

func _ready():
	# warning-ignore:return_value_discarded
	State.connect('gear_updated', self, 'update_skill_buttons')
	player = get_node("/root/Main/Game/Entities/Player")
	player.connect('action_points_changed', self, 'update_action_points')
	player.connect('mode_reset', self, 'reset_to_move')
	buttons.move.connect('toggled', player, '_on_ButtonMove_toggled')
	buttons.skill1.connect('toggled', player, '_on_ButtonSkill1_toggled')
	buttons.skill2.connect('toggled', player, '_on_ButtonSkill2_toggled')
	buttons.skill3.connect('toggled', player, '_on_ButtonSkill3_toggled')
	buttons.idle.connect('button_up', player, 'endTurn')


func _unhandled_input(event):
	if event.is_action_released('mode_left'):
		if !player.playing_animation:
			cycle_mode(-1)
	if event.is_action_released('mode_right'):
		if !player.playing_animation:
			cycle_mode(1)


func cycle_mode(direction):
	var end = player.modes.SKILL3
	player.mode += direction
	if player.mode < 0:
		player.mode = end
	if player.mode > end:
		player.mode = 0
	if !mode_btns[player.mode].visible || mode_btns[player.mode].disabled:
		cycle_mode(direction)
	else:
		mode_btns[player.mode].pressed = true
		player.controls.update()


func show():
	visible = true
	main.ui.container.add_child(self)
	animation.play("Enter")
	yield(animation, 'animation_finished')


func hide():
	animation.play_backwards("Enter")
	yield(animation, 'animation_finished')
	main.ui.container.remove_child(self)


func reset_to_move():
	buttons.move.pressed = true


func update_skill_buttons():
	var skills = State.game.skills
	var size = skills.size()
	buttons.skill1.visible = false
	buttons.skill2.visible = false
	buttons.skill3.visible = false
	if (size > 1):
		buttons.skill1.visible = true
		buttons.skill1.icon = skills[1].icon
		buttons.skill1.hint_tooltip = skills[1].name
		update_skill_cost(skillcost.skill1, skills[1].cost)
	if (size > 2):
		buttons.skill2.visible = true
		buttons.skill2.icon = skills[2].icon
		buttons.skill2.hint_tooltip = skills[2].name
		update_skill_cost(skillcost.skill2, skills[2].cost)
	if (size > 3):
		buttons.skill3.visible = true
		buttons.skill3.icon = skills[3].icon
		buttons.skill3.hint_tooltip = skills[3].name
		update_skill_cost(skillcost.skill3, skills[3].cost)


func update_skill_cost(node, cost):
	for index in node.get_child_count():
		node.get_child(index).visible = index < cost


func update_action_points(state):
	var action_points = state.attributes.action_points
	var action_points_max = floor(state.attributes.action_points_max)

	# Allow for having more than the max temporarily
	if action_points > action_points_max:
		action_points_max = action_points

	# Check if we can still afford all skills, otherwise disable
	for index in State.game.skills.size():
		if index > 0:
			buttons['skill' + String(index)].disabled = (
				state.skills[index].cost > action_points || 
				(state.skills[index].has('uses') && state.skills[index].uses == 0) ||
				(state.skills[index].type == Config.SKILL_TELEPORT && main.game.exit != null)
			)

	# Show and modulate children
	var difference = action_points_max - action_points
	for index in 10:
		ap[index].visible = index < action_points_max
		if (index < difference):
			ap[index].get_node('ColorRect').modulate = Color.black
		else:
			ap[index].get_node('ColorRect').modulate = Color.white


func show_menu():
	main.ui.menu.show()


func show_stats():
	main.ui.help.show()


func skip_music():
	Music.next()
