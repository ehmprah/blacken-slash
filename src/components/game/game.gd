extends Node2D

const Enemy = preload("res://components/entity_enemy/entity_enemy.tscn")
const Exit = preload("res://components/exit/exit.tscn")
const Treasure = preload("res://components/treasure/treasure.tscn")
const Lightning = preload("res://components/special_lightning/special_lightning.tscn")
const Spawner = preload("res://components/special_spawner/special_spawner.tscn")
const Mine = preload("res://components/mine/mine.tscn")
const PopLabel = preload("res://components/pop_label/pop_label.tscn")
const MaterialIcon = preload('res://assets/icons/icon_material.svg')
const Confetti = preload("res://components/confetti/confetti.tscn")

var tile
var grid
var live_enemies = 0
var level_weather = 0
var exit = null
var elite_bonus = false
var boss_total = -1
var level
var level_type
var stage_finished = false

onready var main = get_parent()
onready var animation = $AnimationPlayer
onready var chromatic_abberation = $ChromaticAbberation/AnimationPlayer
onready var entities = $Entities
onready var player = $Entities/Player

func show():
	stage_finished = false
	elite_bonus = false
	main.ui.hud.warning.visible = false
	level_weather = 0
	exit = null
	main.ui.hud.progress.update()
	live_enemies = 0
	boss_total = -1
	Util.delete_children($Level)
	for entity in entities.get_children():
		if is_instance_valid(entity) && !entity.is_in_group('player'):
			entities.remove_child(entity)
			entity.queue_free()

	# Count up and reset stats
	State.game.stats_run.moves += State.game.stats_level.moves
	State.game.stats_run.damage_skills += State.game.stats_level.damage_skills
	State.game.stats_run.hits_taken += State.game.stats_level.hits_taken
	for key in State.game.stats_level:
		State.game.stats_level[key] = 0

	# Instance the level
	if Config.debug.has('roll_level') && Config.debug.roll_level.length() > 0:
		State.game.level.next = Config.debug.roll_level
	elif State.game.difficulty.current == 50:
		State.game.level.next = RNG.array_random([
			'50A.tscn',
			'50B.tscn',
			'50C.tscn',
		])
		boss_total = 0
		elite_bonus = RNG.array_random(Config.elite_bonuses)
	elif State.game.difficulty.current == 100:
		State.game.level.next = '100.tscn'
	level = Levels.data[State.game.level.next].scene.instance()
	level_type = Levels.data[State.game.level.next].type
	$Level.add_child(level)
	grid = level.get_floor_cells()
	Pathfinding.reset(grid);

	# Spawn entities
	for position in level.get_entities_by_id(level.tile.enemy_random):
		spawn_enemy(position)

	for type in Config.enemies.keys():
		for position in level.get_entities_by_id(level.tile[type]):
			spawn_enemy(position, type)

	if elite_bonus:
		add_elite_bonus()

	for position in level.get_entities_by_id(level.tile.exit):
		spawn_exit(position)

	for position in level.get_entities_by_id(level.tile.spawner):
		spawn_special(position, Spawner)

	# Prepare player
	player.position = level.get_entities_by_id(level.tile.player)[0]
	player.playing_animation = true
	player.prepare_combat()

	# Trigger specials
	match level_type:
		Config.level_types.GATE:
			main.ui.hud.warning.show_limit(level.turn_limit)
		Config.level_types.SURVIVAL:
			main.ui.hud.warning.show_survive(level.survive_turns)
		Config.level_types.BLOCK_EXIT:
			main.ui.hud.warning.show_exit()
		Config.level_types.FRICTION:
			main.ui.hud.warning.show_friction()
		Config.level_types.KEEP_MOVING:
			main.ui.hud.warning.show_keep_moving()
			spawn_weather(true)
		Config.level_types.WEATHER:
			main.ui.hud.warning.show_weather()
			level_weather = clamp(floor(grid.size() * 0.2), 1, 8)
			if level_weather > 0:
				spawn_weather()

	# Show the game board
	animation.play("Enter")
	main.ui.hud.show()
	yield(animation, "animation_finished")

	# Spawn treasures
	for position in level.get_entities_by_id(level.tile.treasure):
		yield(spawn_treasure(position), 'completed')

	# Handle spawners
	yield(handle_special('spawner'), 'completed')

	yield(player.landing_execute(), 'completed')
	player.playing_animation = false
	if player.mode == 0:
		player.controls.update()
	else:
		player.emit_signal('mode_reset')
	if (
		player.state.attributes.regeneration > 0 && 
		player.state.attributes.flag_bitshift == 0
	):
		yield(player.regenerate(player.state.attributes.regeneration), 'completed')
	if player.state.attributes.flag_secureboot > 0:
		player.state.shields = 1
		yield(player.regenerate_shields(true), 'completed')
	else:
		yield(player.regenerate_shields(), 'completed')

	# Show level related story here, "under" the normal story coming after
	main.show_story(level_type)


func hide():
	main.ui.hud.hide()
	animation.play_backwards('Enter')
	yield(animation, "animation_finished")


func add_elite_bonus():
	for entity in entities.get_children():
		if entity.is_in_group('enemy'):
			entity.state.attributes[elite_bonus.attribute] += elite_bonus.value
			entity.set_shields()
			main.ui.hud.warning.show_elite(
				Config.attributes[elite_bonus.attribute].name, 
				Util.format_value(
					elite_bonus.value,
					Config.attributes[elite_bonus.attribute].format
				)
			)


func remove_elite_bonus():
	main.ui.hud.warning.hide()
	for entity in entities.get_children():
		if entity.is_in_group('enemy'):
			entity.state.attributes[elite_bonus.attribute] -= elite_bonus.value
			entity.set_shields()
	elite_bonus = false


func spawn_weather(on_player = false):
	if on_player:
		spawn_special(player.position, Lightning)
	else:
		var positions = RNG.array_random_n(grid, level_weather)
		for position in positions:
			spawn_special(position, Lightning)


func spawn_special(position, type):
	var special = type.instance()
	special.position = position
	entities.add_child(special)
	# Move it to the beginning so it appears below characters
	entities.move_child(special, 0)


func spawn_enemy(position, type = null):
	if type == null:
		type = RNG.array_random(level.types)
	live_enemies += 1
	if boss_total > -1:
		boss_total += 1
	var enemy = Enemy.instance()
	enemy.hydrate(Config.enemies[type])
	enemy.connect("death", self, "_on_Enemy_death")
	enemy.position += position
	Pathfinding.disable_tile(enemy.position, true)
	entities.add_child(enemy)
	if type == 'elite':
		elite_bonus = RNG.array_random(Config.elite_bonuses)
		enemy.connect("death", self, "remove_elite_bonus")
	return enemy


func spawn_treasure(position):
	var treasure = Treasure.instance()
	treasure.position += position
	Pathfinding.disable_tile(treasure.position, true)
	treasure.lifetime = round(RNG.roll_range(1, 5))
	treasure.drops = { 'items': { 'chance': 0.25, 'max': 1 }, 'materials': { 'chance': 1, 'max': 100 }}
	entities.add_child(treasure)
	yield(treasure.enter(), 'completed')


func spawn_exit(position):
	exit = Exit.instance()
	exit.position += position
	Pathfinding.disable_tile(exit.position, true)
	entities.add_child(exit)
	# Move it to the beginning so it appears below characters
	entities.move_child(exit, 0)
	exit.countdown(level.turn_limit)


func spawn_mine(position):
	if grid.has(position) && get_entity_at_position(position, 'mine') == null:
		var mine = Mine.instance()
		mine.position += position
		entities.add_child(mine)
		# Move it to the beginning so it appears below the player
		entities.move_child(mine, 0)
		return mine
	return null


func handle_special(type):
	for entity in entities.get_children():
		if is_instance_valid(entity) && entity.is_in_group(type):
			entity.handle()
			yield(entity, 'animations_all_finished')
	yield(get_tree(), "idle_frame")


func handleEnemyTurn():
	State.game.stats_level.turns_taken += 1
	var previous_hits = State.game.stats_level.hits_taken
	# Check the turn limit
	if level.turn_limit == 0:
		stage_finished = true
		return _on_Player_death()
	if level.turn_limit > 0:
		level.turn_limit -= 1
		main.ui.hud.warning.show_limit(level.turn_limit)
		exit.countdown(level.turn_limit)
	# Check survival limit
	if level.survive_turns > 0:
		level.survive_turns -= 1
		main.ui.hud.warning.show_survive(level.survive_turns)
	# Handle specials
	yield(handle_special('weather'), 'completed')
	if !player.alive || stage_finished: 
		return
	# Handle the actual enemy turn
	var enemies = []
	for entity in entities.get_children():
		if entity.is_in_group('enemy') && entity.alive:
			entity.distance_to_player = Pathfinding.distance_to(entity.position, player.position)
			if (
				!entity.state.attributes.flag_immobile || 
				entity.distance_to_player == 2 ||
				# Make sure that enemies that recharge their shields get a turn
				entity.state.attributes.shields
			):
				enemies.append(entity)
			else:
				entity.show_pop_label('T_IDLE')
		if entity.is_in_group('treasure'):
			entity.update()
	if enemies.size() > 0:
		yield(main.ui.notification.show('T_ENEMY', 'T_TURN'), 'completed')
		enemies.sort_custom(Util, 'sort_enemies')
		for entity in enemies:
			if entity.alive:
				entity.reset_action_points()
				yield(entity.regenerate_shields(), 'completed')
				while entity.state.attributes.action_points > 0 && entity.alive:
					yield(entity.take_action(player), 'completed')
					if !player.alive: return
	# Now let's clean up all dead entities
	for entity in entities.get_children():
		if !entity.alive:
			entity.queue_free()
	# Check for live enemies just in case
	# if (
	# 	level_type != Config.level_types.GATE && 
	# 	level_type != Config.level_types.SURVIVAL &&
	# 	!has_live_enemy()
	# ):
	# 	return finish_level()
	# We end survival levels immediately after the last survived enemy turn
	if level.survive_turns == 0:
		return finish_level()
	if level_weather > 0:
		spawn_weather()
	if level_type == Config.level_types.KEEP_MOVING:
		spawn_weather(true)
	# Handle spawners
	yield(handle_special('spawner'), 'completed')
	if State.game.stats_level.hits_taken - previous_hits >= 10:
		State.update_achievement('T_TANKY', 1)
	yield(main.ui.notification.show('T_YOUR', 'T_TURN'), 'completed')


func has_live_enemy():
	for entity in entities.get_children():
		if entity.alive && entity.is_in_group('enemy'):
			return true
	return false


func get_entity_at_position(position, group = false):
	for entity in entities.get_children():
		if (
			entity.position == position && 
			entity.alive &&
			(!group || entity.is_in_group(group))
		):
			return entity
	return null


func get_all_at_position(position):
	var found = []
	for entity in entities.get_children():
		if (
			entity.position == position && 
			entity.alive
		):
			found.append(entity)
	return found


func get_random_adjacent_entity(position, group):
	var candidates = []
	for entity in entities.get_children():
		if entity.alive && entity.is_in_group(group):
			for key in Config.cardinal:
				if entity.position == position + Config.direction[key]:
					candidates.append(entity)
	if candidates.size() > 0:
		return RNG.array_random(candidates)
	return null


func get_random_entity(group):
	var candidates = []
	for entity in entities.get_children():
		if entity.alive && entity.is_in_group(group):
			candidates.append(entity)
	if candidates.size() > 0:
		return RNG.array_random(candidates)
	return null


func get_positions(group):
	var positions = []
	for entity in entities.get_children():
		if entity.is_in_group(group) && entity.alive:
			positions.append(entity.position)
	return positions


func _on_Player_death():
	yield(hide(), 'completed')
	get_parent().game_over()
	State.update_achievement('T_DEATH', 1)


func _on_Enemy_death():
	live_enemies -= 1
	State.game.stats_run.kills += 1
	if player.state.attributes.flag_life_steal > 0:
		player.regenerate(0.2)
	if boss_total > -1:
		$Level.get_child(0).update_boss_damage(
			1 - float(live_enemies) / float(boss_total)
		)
	if live_enemies == 0 && level.turn_limit == -1 && level.survive_turns == -1:
		finish_level()


func finish_level():
	player.controls.preview.clear()
	stage_finished = true
	yield(player.reverse_landing(), 'completed')
	yield(hide(), 'completed')
	get_parent().level_clear()


func _on_player_damage_taken(amount):
	SFX.play(SFX.sounds.PLAYER_DAMAGE)
	State.game.damage = player.state.damage
	State.game.stats_level.hits_taken += 1
	chromatic_abberation.play("Glitch")
	if player.state.attributes.flag_life_link > 0:
		for entity in entities.get_children():
			if entity.is_in_group('enemy') && entity.alive:
				entity.lose_health(amount)
	if State.game.meta.type == Config.meta.HIT:
		player.meta_bonus()


func roll_loot(pos, drops):
	if State.game.stats_level.loot > 15:
		return
	var loot = RNG.roll_loot(drops)
	for item in loot.items:
		State.game.stats_level.loot += 1
		SFX.play(SFX.sounds.ITEM_DROP_UNIQUE if item.rarity > Config.RARITY_RARE else SFX.sounds.ITEM_DROP)
		var drop = PopLabel.instance()
		drop.position = pos
		drop.text = Config.item_types[item.type].names[0]
		drop.icon = Config.item_types[item.type].icon
		drop.duration = 1
		drop.modulate = Config.rarity_colors[item.rarity]
		add_child(drop)
		if item.rarity > Config.RARITY_RARE:
			var particles = Confetti.instance()
			particles.position = pos
			particles.modulate = Config.rarity_colors[item.rarity]
			add_child(particles)
		yield(get_tree().create_timer(0.75), "timeout")
	if loot.materials:
		State.game.stats_level.loot += 1
		State.add_materials(loot.materials)
		SFX.play(SFX.sounds.BUZZ)
		var drop = PopLabel.instance()
		drop.position = pos
		drop.icon = MaterialIcon
		drop.text = String(loot.materials)
		drop.duration = 0.5
		add_child(drop)
