extends "res://components/entity_base/entity_base.gd"

const Explosion = preload("res://components/explosion/explosion.tscn")

var drops
var distance_to_player

# We don't use the onready vars here because they're hydrated before ready
# TODO: check if we can maybe change that?
func hydrate(data):
	.hydrate(data)
	state.drops = data.drops
	$Sprite.texture = data.sprite.texture
	$Sprite.material.set_shader_param("offset", randf())
	$Sprite/Damage.texture = data.sprite.texture
	$Sprite/Shields.texture = data.sprite.texture
	$Trail.texture = data.sprite.texture
	$Sprite.self_modulate = data.color
	$Trail.modulate = data.color
	$Stomp.modulate = data.color
	sprite_height = data.sprite.height
	sprite_y_offset = data.sprite.y_offset
	# Add boss modifiers
	for key in State.game.modifiers.enemy:
		state.attributes[key] += State.game.modifiers.enemy[key]
	# Add shields
	set_shields()


func set_shields():
	state.shields = state.attributes.shields
	if state.attributes.flag_secureboot > 0:
		state.shields = 1
	$Sprite/Shields.region_rect = Rect2(0, 0, 128, state.shields * sprite_height + sprite_y_offset)


func on_leaving_position():
	Pathfinding.disable_tile(position, false)
	yield(get_tree(), "idle_frame")


func on_new_position():
	Pathfinding.disable_tile(position, true)
	if game.level_type == Config.level_types.BLOCK_EXIT:
		if game.get_entity_at_position(position, 'exit'):
			game._on_Player_death()
			yield(get_tree(), "idle_frame")
	var mine = game.get_entity_at_position(position, 'mine')
	if mine:
		yield(mine.explode(self), 'completed')
	else:
		yield(get_tree(), "idle_frame")


func handle_death():
	Pathfinding.disable_tile(position, false)
	var explosion = Explosion.instance()
	explosion.position = position
	game.add_child(explosion)
	animation.stop(true)
	animation.play("Death")
	game.roll_loot(position, state.drops)
	yield(animation, "animation_finished")
	.handle_death()


func landing_execute():
	$AnimationPlayer.playback_speed = 1.5
	$AnimationPlayer.play("EnterStomp")
	yield($AnimationPlayer, 'animation_finished')
	$Stomp.emitting = true
	SFX.play(SFX.sounds.TREASURE_DROP)


func take_action(player):
	# check for other skills than move
	if state.skills.size() > 1:
		var skill = state.skills[1]
		if skill.cost <= state.attributes.action_points:
			match skill.type:
				Config.PROJECTILE_BALLISTIC:
					for key in Config.cardinal:
						var direction = Config.direction[key]
						for n in skill.range:
							var pos = position + direction * (n + 1)
							if (
								pos == player.position && 
								(!skill.has('range_min') || n >= skill.range_min)
							):
								return action(player.position - position, skill)
				Config.SKILL_TELEPORT:
					if distance_to_player > 3 || distance_to_player == 0:
						for key in Config.cardinal:
							var target = player.position + Config.direction[key]
							if game.grid.has(target) && game.get_entity_at_position(target) == null:
								return action(target - position, skill)
				Config.SKILL_DASH:
					var vector = player.position - position
					for key in Config.cardinal:
						var direction = Config.direction[key]
						if vector.angle() == direction.angle():
							var enemies = game.get_positions('enemy')
							for n in skill.range:
								var pos = position + direction * (n + 1)
								if skill.has('blocking') && enemies.has(pos):
									break
								if skill.has('range_min') && n < skill.range_min:
									continue
								if pos == player.position:
									# Don't dash where there's no floor
									if !game.grid.has(position + direction * n):
										break
									# Don't dash onto treasures
									if game.get_entity_at_position(position + direction * n, 'treasure') != null:
										break
									return action(player.position - position, skill)

	# If we're in attack range, attack!
	for key in Config.cardinal:
		var vector = Config.direction[key]
		if player.position == position + vector:
			return action(vector, state.skills[0])

	# Otherwise try and move
	var target = player.position
	if game.level_type == Config.level_types.BLOCK_EXIT:
		target = game.exit.position
	var path = Pathfinding.calculate_path(position, target)
	# if there's no direct path, we at least try to get closer
	if !state.attributes.flag_immobile && path.size() == 0:
		var free = Pathfinding.calculate_path(position, target, true)
		if free.size() >= 2 && !Pathfinding.is_tile_disabled(free[1]):
			path = [position, free[1]]

	if path.size() == 0 || state.attributes.flag_immobile && path.size() != 2:
		state.attributes.action_points = 0
		show_pop_label('T_IDLE')
		yield(get_tree(), "idle_frame")
	else:
		SFX.play(SFX.sounds.MOVE_ENEMY)
		yield(move(path[1] - position), 'completed')


func counter(vec):
	show_pop_label('T_COUNTER')
	var projectile = Projectile.instance()
	projectile.params = {
		'position': position, 
		'vector': vec, 
		'skill': {
			'range': 1,
			'type': Config.PROJECTILE_BEAM,
			'family': Config.MELEE,
			'effects': [Config.damage.enemy_default],
		},
		'source': self,
		'is_counter': true,
	}
	game.add_child(projectile)
	yield(projectile, 'animations_all_finished')
