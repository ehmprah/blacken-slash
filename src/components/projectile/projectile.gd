extends Node2D

signal animations_all_finished

const VFX_BEAM = preload("res://components/vfx_beam/vfx_beam.tscn")
const VFX_PUSH = preload("res://components/vfx_push/vfx_push.tscn")
const VFX_BALLISTIC = preload("res://components/vfx_ballistic/vfx_ballistic.tscn")
const VFX_LIGHTNING = preload("res://components/vfx_lightning/vfx_lightning.tscn")

var params
var target
var colors = []
var entities = []
var spawned_mines = []
var animations_left = 0
var one_shots = 0

onready var vfx = $VFX
onready var game = get_parent()

func _ready():
	colors = Util.get_projectile_colors()
	get_targets_and_vfx()
	
	if params.skill.type == Config.PROJECTILE_BALLISTIC:
		yield(vfx.get_child(0).animate_fire(), 'completed')
		if params.skill.aoe_type == Config.PROJECTILE_PUSH:
			add_mine(target)

	if params.skill.type != Config.PROJECTILE_LIGHTNING:
		for effect in vfx.get_children():
			effect.animate()
	
	yield(apply_effects(), 'completed')
	
	if one_shots == 1 && State.game.difficulty.current >= 50:
		State.update_achievement('T_ONE_HIT_WONDER', 1)
	if one_shots == 3 && State.game.difficulty.current >= 50:
		State.update_achievement('T_HAT_TRICK', 1)
	if entities.size() >= 7:
		State.update_achievement('T_SEVEN_AT_ONE_BLOW', 1)


func get_targets_and_vfx():
	var target_group = 'player' if params.source.is_in_group('enemy') else 'enemy'
	
	if params.skill.type == Config.PROJECTILE_AOE_ONLY:
		target = params.position
		if params.skill.aoe_type == Config.PROJECTILE_BEAM:
			SFX.play(SFX.sounds.BEAM)
		if params.skill.aoe_type == Config.PROJECTILE_PUSH:
			SFX.play(SFX.sounds.PUSH_FIRE)

	if params.skill.type == Config.PROJECTILE_BALLISTIC:
		target = params.position + params.vector
		add_hit(game.get_entity_at_position(target, target_group))
		add_vfx(VFX_BALLISTIC, params.position, params.vector)

	if params.skill.type == Config.PROJECTILE_PUSH:
		target = params.position + params.vector
		add_hit(game.get_entity_at_position(target, target_group))
		add_vfx(VFX_PUSH, params.position, params.vector)
		add_mine(target)

	if params.skill.type == Config.PROJECTILE_BEAM:
		# Regardless of input vector, the beam does max range
		var direction = Util.get_direction_vector(params.vector)
		target = params.position + direction * params.skill.range
		var beam = add_vfx(VFX_BEAM, params.position, direction * params.skill.range)
		for n in params.skill.range:
			var vector = direction * (n + 1)
			var entity = game.get_entity_at_position(params.position + vector, target_group)
			if entity: 
				add_hit(entity)
				beam.add_hit(vector)

	if params.skill.type == Config.PROJECTILE_LIGHTNING:
		target = params.position + params.vector
		var entity = game.get_entity_at_position(target, target_group)
		if entity:
			add_hit(entity)
		add_vfx(VFX_LIGHTNING, params.position, params.vector, entity)
		SFX.play(SFX.sounds.LIGHTNING_SHOT)
		# Handle chain jumps
		# TODO: add legendary flag that allows all around jumps
		# TODO: add legendary flag that doubles jumps
		var next = target
		var chain = params.skill.chain
		while chain > 0:
			entity = null
			var vectors = []
			for direction in Config.cardinal:
				vectors.append(Config.direction[direction])
			vectors.shuffle()
			for vec in vectors:
				entity = game.get_entity_at_position(next + vec, target_group)
				if entity:
					add_hit(entity)
					add_vfx(VFX_LIGHTNING, next, vec, entity)
					next += vec
					chain -= 1
					break
			if entity == null:
				break


	if params.skill.has('aoe'):
		for hit_vector in params.skill.aoe:
			if params.skill.aoe_type == Config.PROJECTILE_BEAM:
				var beam = add_vfx(VFX_BEAM, target, hit_vector)
				beam.is_child = true
				var entity = game.get_entity_at_position(target + hit_vector, target_group)
				if entity:
					add_hit(entity)
					beam.add_hit(hit_vector)
			if params.skill.aoe_type == Config.PROJECTILE_PUSH:
				add_vfx(VFX_PUSH, target, hit_vector)
				add_hit(game.get_entity_at_position(target + hit_vector, target_group))
				add_mine(target + hit_vector)


func add_mine(vec):
	if params.source && params.source.state.attributes.flag_push_mine > 0:
		var mine = game.spawn_mine(vec)
		if mine:
			spawned_mines.append(vec)


func add_hit(entity):
	if entity:
		entities.append(entity)
		if !entity.is_connected('animation_finished', self, '_on_animation_finished'):
			entity.connect("animation_finished", self, "_on_animation_finished")
		animations_left += 1


func add_vfx(type, from, to, entity = null):
	var effect = type.instance()
	effect.position = from
	effect.target = to
	if type != VFX_PUSH:
		effect.colors = colors
	if type == VFX_LIGHTNING:
		effect.entity = entity
	effect.connect("animation_finished", self, "_on_animation_finished")
	animations_left += 1
	vfx.add_child(effect)
	return effect


func apply_effects():
	if params.skill.type == Config.PROJECTILE_LIGHTNING:
		for v in vfx.get_children():
			v.animate()
			if v.entity != null:
				# TODO: can we rework this so we find and process targets in sequence?!
				if v.entity.alive:
					apply_entity_effects(v.entity)
				else:
					_on_animation_finished()
			yield(v, 'animation_finished')
	else:
		for entity in entities:
			apply_entity_effects(entity)
		yield(get_tree(), "idle_frame")


func apply_entity_effects(entity):
	for effect in params.skill.effects:
		if effect.type == 'damage':
			damage(entity, effect)
		if effect.type == 'push':
			push(entity)


func push(entity):
	var blocked = entity.state.attributes.flag_immobile > 0 || entity.state.attributes.flag_unpushable > 0
	var vector = entity.position - target
	if target == entity.position:
		vector = Util.get_direction_vector(params.vector)
	# Handle evasion
	if entity.roll_evasion(params.source):
		yield(entity.evade(vector), 'completed')
		entity.emit_signal("animation_finished")
		return 
	# Handle push cascade
	var cascade = []
	cascade.append(entity)
	var next = entity.position + vector
	if !blocked:
		var collider = game.get_entity_at_position(next, 'blocking')
		while collider:
			if collider.is_in_group('treasure'):
				collider.destroy()
				break
			if (
				collider.is_in_group('exit') ||
				collider.is_in_group('mine') ||
				collider.is_in_group('weather') ||
				collider.is_in_group('spawner')
			):
				break
			cascade.append(collider)
			if (
				collider.state.attributes.flag_immobile > 0 || 
				collider.state.attributes.flag_unpushable > 0
			):
				blocked = true
				break
			collider.connect("animation_finished", self, "_on_animation_finished")
			animations_left += 1
			next += vector
			collider = game.get_entity_at_position(next, 'blocking')
	# Execute pushes
	for index in cascade.size():
		if index > 0:
			yield(get_tree().create_timer(0.15), "timeout")
			SFX.play_variant('collide')
		if blocked:
			cascade[index].push_blocked()
		else:
			cascade[index].push(vector)


func damage(entity, effect):
	var amount
	if effect.has('amount'):
		amount = { 'damage': effect.amount, 'crit': false }
	else:
		amount = RNG.roll_damage(effect, params.source.state.attributes)
		# Handle crit meta bonus
		if (
			amount.crit && 
			State.game.meta.type == Config.meta.CRIT && 
			params.source.is_in_group('player')
		):
			params.source.meta_bonus()
	# Handle damage bonuses
	var base_damage = amount.damage
	# Overall damage bonus
	amount.damage += base_damage * params.source.state.attributes.damage_bonus
	# Skill family bonuses
	if params.skill.family == Config.MELEE:
		amount.damage += base_damage * params.source.state.attributes.melee_bonus
	if params.skill.family == Config.RANGED:
		amount.damage += base_damage * params.source.state.attributes.ranged_bonus
	# Movement bonuses
	if entity.is_in_group('enemy'):
		amount.damage += base_damage * State.game.stats_level.stationary
		amount.damage += base_damage * State.game.stats_level.momentum
	# Handle resistance
	amount.damage = dmg_after_res(
		amount.damage, 
		entity.state.attributes.resistance - params.source.state.attributes.resistance_reduction
	)
	var full_health = entity.state.damage == 0
	entity.deal_damage(
		target - entity.position, 
		amount, 
		params.source,
		params.has('is_counter') && params.is_counter == true
	)
	if full_health && entity.state.damage >= 0.99:
		one_shots += 1


func dmg_after_res(dmg, res):
	var modifier = 1 + abs(res)
	if res > 0:
		return dmg / modifier
	else:
		return dmg * modifier


func _on_animation_finished():
	animations_left -= 1
	if animations_left == 0:
		for vector in spawned_mines:
			var entity = game.get_entity_at_position(vector, 'enemy')
			if entity:
				yield(entity.on_new_position(), 'completed')
		emit_signal('animations_all_finished')
		queue_free()
