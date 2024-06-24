extends "res://components/entity_base/entity_base.gd"

const MetaBonus = preload("res://components/meta_bonus/meta_bonus.tscn")

signal mode_reset

enum modes { MOVING, SKILL1, SKILL2, SKILL3 }

var mode = modes.MOVING
var playing_animation = false
var moves = 0

onready var controls = $Controls
onready var camera = $Controls/Camera2D
onready var fog = $FogOfWar
onready var action_icon = $ActionIcon

func _ready():
	# We call an intermediary function to assert execution order
	State.connect('gear_updated', self, '_on_gear_update')


func _on_gear_update():
	hydrate(null)
	reset_action_points()


func hydrate(data):
	data = State.game
	.hydrate(data)
	state.damage = data.damage
	var new_height = state.damage * sprite_height
	damage.offset = Vector2(-64, -64 + sprite_y_offset + sprite_height - new_height)
	damage.region_rect = Rect2(0, sprite_y_offset + sprite_height - new_height, 128, new_height)


func reset():
	alive = true
	mode = modes.MOVING
	$Sprite.rotation = 0
	damage.offset = Vector2(-64, 64)
	damage.region_rect = Rect2(0, 128, 128, 0)
	$Sprite.position = Vector2.ZERO


func prepare_combat():
	state.status = {}
	# Prepare landing
	$Sprite.position = Vector2(0, -700)
	fog.visible = state.attributes.flag_fog_of_war > 0
	# Recharge single use skills
	for skill in state.skills:
		if skill.has('uses_per_combat'):
			skill.uses = skill.uses_per_combat
	# Reset action points
	reset_action_points()
	if state.attributes.flag_fastboot > 0:
		state.attributes.action_points += 3
	emit_signal('action_points_changed', state)


func landing_execute():
	animation.play("EnterStomp")
	yield(animation, 'animation_finished')
	$Stomp.emitting = true
	SFX.play(SFX.sounds.TREASURE_DROP)


func reverse_landing():
	$Stomp.emitting = true
	SFX.play(SFX.sounds.DASH)
	animation.play_backwards("EnterStomp")
	yield(animation, 'animation_finished')


func regenerate(amount):
	yield(.regenerate(amount), 'completed')
	State.game.damage = state.damage
	emit_signal('health_changed')


func _input(_event):
	if playing_animation:
		get_tree().set_input_as_handled()


func action(vector, skill):
	# Check for damage skill usage for the bonus
	for effect in skill.effects:
		if effect.type == 'damage':
			State.game.stats_level.damage_skills += 1
		if State.game.meta.type == Config.meta.PUSH && effect.type == 'push':
			meta_bonus()
	if skill.has('followup'):
		for effect in Config.skills[skill.followup].effects:
			if effect.type == 'damage':
				State.game.stats_level.damage_skills += 1
				if State.game.meta.type == Config.meta.MOVE:
					meta_bonus()
	if State.game.meta.type == Config.meta.AP && skill.cost >= 2:
		meta_bonus()
	yield(.action(vector, skill), 'completed')


func take_action(vector):
	playing_animation = true
	controls.reset()
	
	if (mode == modes.MOVING):
		var target = position + vector
		var path = Pathfinding.calculate_path(position, target)
		var vectors = []
		for n in path.size() - 1:
			vectors.append(path[n+1] - path[n])

		while(vectors.size() > 1):
			SFX.play(SFX.sounds.MOVE_PLAYER)
			yield(move(vectors.pop_front()), 'completed')
			# Since moving can clear the level, abort on win
			if game.stage_finished:
				playing_animation = false
				return

		if game.get_entity_at_position(target, 'enemy') != null:
			yield(action(vectors[0], state.skills[0]), 'completed')
		else:
			SFX.play(SFX.sounds.MOVE_PLAYER)
			yield(move(vectors[0]), 'completed')
	else:
		yield(action(vector, state.skills[mode]), 'completed')
	playing_animation = false
	if !game.stage_finished:
		if (
			state.skills[mode].cost > state.attributes.action_points ||
			state.skills[mode].has('uses') && state.skills[mode].uses == 0 || 
			state.skills[mode].has('reset_to_move') && state.skills[mode].reset_to_move
		):
			emit_signal('mode_reset')
		if state.attributes.action_points == 0:
			endTurn()
		else:
			if !game.stage_finished:
				controls.update()


func on_leaving_position():
	State.game.stats_level.stationary = 0
	State.game.stats_level.moves += 1
	moves += 1
	if state.status.has(Config.status.MINELAYER):
		game.spawn_mine(position)


func on_new_position():
	var friction = 0
	if state.attributes.flag_friction > 0:
		friction += 0.01
	if game.level_type == Config.level_types.FRICTION:
		friction += 0.01
	if friction > 0:
		lose_health(friction)

	var treasure = game.get_entity_at_position(position, 'treasure')
	if treasure:
		SFX.play(SFX.sounds.OPEN_TREASURE)
		game.roll_loot(treasure.position, treasure.drops)
		treasure.loot()

	var exit = game.get_entity_at_position(position, 'exit')
	if exit && game.level_type != Config.level_types.BLOCK_EXIT:
		playing_animation = false
		game.finish_level()
	elif state.attributes.momentum_bonus > 0:
		State.game.stats_level.momentum += state.attributes.momentum_bonus
		show_pop_label(tr('T_MOMENTUM') + ' +' + 
			("%d%%" % (State.game.stats_level.momentum * 100)), Color.white, 0.5)

	if state.attributes.flag_drive_by > 0:
		var enemy = game.get_random_adjacent_entity(position, 'enemy')
		if enemy:
			if State.game.meta.type == Config.meta.MOVE:
				meta_bonus()
			var projectile = Projectile.instance()
			projectile.params = {
				'position': position, 
				'vector': enemy.position - position, 
				'skill': {
					'range': 1,
					'type': Config.PROJECTILE_BEAM,
					'family': Config.MELEE,
					'effects': [Config.damage.default],
				},
				'source': self,
			}
			game.add_child(projectile)
			yield(projectile, "animations_all_finished")
		elif state.attributes.flag_drive_by_ranged > 0:
			enemy = game.get_random_entity('enemy')
			if enemy:
				if State.game.meta.type == Config.meta.MOVE:
					meta_bonus()
				var projectile = Projectile.instance()
				projectile.params = {
					'position': position, 
					'vector': enemy.position - position, 
					'skill': {
						'type': Config.PROJECTILE_BALLISTIC,
						'family': Config.RANGED,
						'effects': [Config.damage.default],
					},
					'source': self,
				}
				game.add_child(projectile)
				yield(projectile, "animations_all_finished")
	yield(get_tree(), "idle_frame")


func endTurn():
	if State.game == null || State.game.phase != Config.PHASE_LEVEL_PLAY:
		return
	if (
		state.attributes.stationary_bonus && 
		moves == 0 &&
		State.game.stats_level.stationary < state.attributes.stationary_bonus * 3
	):
		State.game.stats_level.stationary += state.attributes.stationary_bonus
		show_pop_label(tr('T_STATIONARY') + ' +' + 
			("%d%%" % (State.game.stats_level.stationary * 100)), Color.white, 0.5)
	# Reset moves
	moves = 0
	State.game.stats_level.momentum = 0
	on_turn_end()
	if game.stage_finished == false:
		controls.preview.clear()
		playing_animation = true
		yield(game.handleEnemyTurn(), 'completed')
		playing_animation = false
		# only continue if the game's still not over yet
		if alive && game.stage_finished == false:
			reset_action_points()
			emit_signal('mode_reset')
			yield(regenerate_shields(), 'completed')
			controls.update()


func evade(vector):
	if State.game.meta.type == Config.meta.EVADE:
		meta_bonus()
	yield(.evade(vector), 'completed')
	if state.attributes.flag_powerdodge > 0:
		var projectile = Projectile.instance()
		projectile.params = {
			'position': position, 
			'vector': Vector2.ZERO, 
			'skill': Config.skills.roundhouse_1,
			'source': self,
			'is_counter': true,
		}
		game.add_child(projectile)
		yield(projectile, "animations_all_finished")


func counter(vec):
	if State.game.meta.type == Config.meta.COUNTER:
		meta_bonus()
	yield(.counter(vec), 'completed')


func reset_action_points():
	.reset_action_points()
	emit_signal("action_points_changed", state)


func _on_ButtonMove_toggled(button_pressed):
	if !playing_animation:
		if button_pressed:
			if mode != modes.MOVING:
				mode = modes.MOVING
				controls.update()


func _on_ButtonSkill1_toggled(button_pressed):
	if !playing_animation:
		if button_pressed:
			if mode != modes.SKILL1:
				mode = modes.SKILL1
				controls.update()


func _on_ButtonSkill2_toggled(button_pressed):
	if !playing_animation:
		if button_pressed:
			if mode != modes.SKILL2:
				mode = modes.SKILL2
				controls.update()


func _on_ButtonSkill3_toggled(button_pressed):
	if !playing_animation:
		if button_pressed:
			if mode != modes.SKILL3:
				mode = modes.SKILL3
				controls.update()


func meta_bonus():
	if (
		State.game.meta.rewarded < Config.globals.meta_bonus_times &&
		State.game.stats_level.meta <= 10
	):
		State.meta_bonus()
		State.game.stats_level.meta += 1
		var drop = MetaBonus.instance()
		drop.position = Vector2(0, 100)
		add_child(drop)
