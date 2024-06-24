extends KinematicBody2D

const Projectile = preload("res://components/projectile/projectile.tscn")
const PopLabel = preload("res://components/pop_label/pop_label.tscn")

# TODO: rewrite all the yields to "completed"!
signal animation_finished
signal action_points_changed
signal damage_taken
signal death
signal health_changed

onready var game = get_parent().get_parent()
onready var tween = $Tween
onready var animation = $AnimationPlayer
onready var sprite = $Sprite
onready var damage = $Sprite/Damage
onready var shields = $Sprite/Shields

var alive = true
var type = 'player'
var color = Color(1, 1, 1)
var sprite_height = 98
var sprite_y_offset = 23
var state = {
	'damage': 0,
	'shields': 0,
	'skills': [],
	'status': {},
	'attributes': Config.attributes_base.duplicate(),
}

# TODO: refactor here, remove code duplication!

func hydrate(data):
	type = data.type
	state.skills = data.skills.duplicate(true)
	for attribute in data.attributes.keys():
		state.attributes[attribute] = data.attributes[attribute]


func reset_action_points():
	state.attributes.action_points = floor(state.attributes.action_points_max)


func move(vector):
	on_leaving_position()
	state.attributes.action_points -= 1
	emit_signal("action_points_changed", state)
	tween.interpolate_property(self, "position", position, position + vector, 0.15, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	yield(on_new_position(), 'completed')	


func teleport(vector):
	on_leaving_position()
	SFX.play(SFX.sounds.DASH)
	animation.stop(true)
	animation.play("Teleport")
	yield(animation, "animation_finished")
	tween.interpolate_property(self, "position", position, position + vector, 0.1, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	SFX.play(SFX.sounds.DASH_REVERSE)
	animation.play_backwards("Teleport")
	yield(animation, "animation_finished")
	yield(on_new_position(), 'completed')


func dash(vector):
	on_leaving_position()
	# Substract the direction vector, we land one tile before the one clicked
	var normalized = Util.get_direction_vector(vector)
	var move_vector = vector - normalized
	SFX.play(SFX.sounds.DASH)
	$Trail.emitting = true
	tween.interpolate_property(self, "position", position, position + move_vector, 0.2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	$Trail.emitting = false
	yield(on_new_position(), 'completed')


func push(vector):
	var target = 	position + vector
	Pathfinding.disable_tile(position, false)
	tween.interpolate_property(self, "position", position, target, 0.3, Tween.TRANS_QUAD, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_all_completed")
	if game.grid.has(target):
		if game.get_entity_at_position(target, 'exit'):
			SFX.play(SFX.sounds.DASH)
			tween.interpolate_property(self, "position", target, target - Vector2(0, 50), 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.interpolate_property(self, "modulate", Color.white, Color(1, 1, 1, 0), 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.start()
			yield(tween, "tween_all_completed")
			if (self.is_in_group('enemy')):
				alive = false
				emit_signal("death")
		else:
			yield(on_new_position(), 'completed')
	else:
		SFX.play(SFX.sounds.PUSH_FALL)
		tween.interpolate_property(self, "position", target, target + Vector2(0, 50), 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween.interpolate_property(self, "modulate", Color.white, Color(1, 1, 1, 0), 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween.start()
		yield(tween, "tween_all_completed")
		if (self.is_in_group('enemy')):
			game.roll_loot(position, state.drops)
			alive = false
		emit_signal("death")
	emit_signal("animation_finished")


func push_blocked():
	show_pop_label('T_BLOCKED')
	emit_signal("animation_finished")


func action(vector, skill):
	state.attributes.action_points -= skill.cost
	if skill.has('uses'):
		skill.uses -= 1
	emit_signal("action_points_changed", state)
	if skill.type == Config.SKILL_SELF:
		for effect in skill.effects:
			match effect.type:
				'masochism':
					var amount = RNG.roll_range(effect.min, effect.max)
					show_pop_label(String(floor(100 * amount)))
					lose_health(amount)
					yield(get_tree(), "idle_frame")
				'regenerate':
					# TODO: rework this to 'compltede'
					regenerate(RNG.roll_range(effect.min, effect.max))
					yield(self, 'animation_finished')
				'double_shields':
					state.shields *= 2
					yield(regenerate_shields(true), 'completed')
				'shields_up':
					state.shields = effect.value
					yield(regenerate_shields(true), 'completed')
				'minelayer':
					state.status[Config.status.MINELAYER] = 9999
					SFX.play(SFX.sounds.BUFF)
					yield(get_tree(), "idle_frame")

	elif skill.type == Config.SKILL_TELEPORT:
		yield(teleport(vector), 'completed')
		if skill.has('followup'):
			var followup = Config.skills[skill.followup]
			state.attributes.action_points += followup.cost
			# We make sure to use a standardized vector here
			yield(action(Config.direction.top_right, followup), 'completed')


	elif skill.type == Config.SKILL_DASH:
		yield(dash(vector), 'completed')
		var followup = Config.skills[skill.followup]
		state.attributes.action_points += followup.cost
		yield(action(Util.get_direction_vector(vector), followup), 'completed')

	else:
		var projectile = Projectile.instance()
		projectile.params = {
			'position': position, 
			'vector': vector, 
			'skill': skill,
			'source': self,
		}
		game.add_child(projectile)
		yield(projectile, "animations_all_finished")


func on_leaving_position():
	yield(get_tree(), "idle_frame")


func on_new_position():
	yield(get_tree(), "idle_frame")


func on_turn_end():
	# Recharge single use skills
	for skill in state.skills:
		if skill.has('uses_per_turn'):
			skill.uses = skill.uses_per_turn
	# Reset statuses
	for status in state.status:
		state.status[status] -= 1
		if state.status[status] == 0:
			state.status.erase(status)


func regenerate(amount):
	if (state.damage > 0):
		var regen = 0
		if amount > state.damage:
			regen = state.damage
			state.damage = 0
		else:
			regen = amount
			state.damage -= amount
		emit_signal('health_changed')
		show_pop_label(String(floor(100 * regen)) + '%', Color(0.211765, 0.803922, 0.768627))
		SFX.play(SFX.sounds.BUFF)
		var new_height = state.damage * sprite_height
		var new_offset = Vector2(-64, -64 + sprite_y_offset + sprite_height - new_height)
		var new_rect = Rect2(0, sprite_y_offset + sprite_height - new_height, 128, new_height)
		tween.interpolate_property(damage, "offset", damage.offset, new_offset, 0.2)
		tween.interpolate_property(damage, "region_rect", damage.region_rect, new_rect, 0.2)
		tween.start()
		yield(tween, "tween_all_completed")
		emit_signal("animation_finished")
	else:
		# To yield the execution of this function reliably we have to yield in it every time!
		yield(get_tree(), "idle_frame")
		emit_signal("animation_finished")


func regenerate_shields(overcharge = false):
	if overcharge || state.shields != state.attributes.shields:
		if !overcharge:
			state.shields = state.attributes.shields
		var rect = Rect2(0, 0, 128, state.shields * sprite_height + sprite_y_offset)
		tween.interpolate_property(shields, "region_rect", shields.region_rect, rect, 0.2)
		tween.start()
		SFX.play(SFX.sounds.BUFF)
		yield(tween, "tween_all_completed")
		emit_signal("animation_finished")
	else:
		# To yield the execution of this function reliably we have to yield in it every time!
		yield(get_tree(), "idle_frame")


func lose_health(amount):
	var before = state.damage
	state.damage += amount
	# Losing health works asynchronously and can't kill
	if (state.damage >= 0.99):
		state.damage = 0.98
	emit_signal('damage_taken', state.damage - before)
	emit_signal('health_changed')
	var new_height = state.damage * sprite_height
	var new_offset = Vector2(-64, -64 + sprite_y_offset + sprite_height - new_height)
	var new_rect = Rect2(0, sprite_y_offset + sprite_height - new_height, 128, new_height)
	tween.interpolate_property(damage, "offset", damage.offset, new_offset, 0.2)
	tween.interpolate_property(damage, "region_rect", damage.region_rect, new_rect, 0.2)
	tween.start()


func deal_damage(vector, hit, source = null, is_counter = false):
	if roll_evasion(source):
		yield(evade(vector), 'completed')
		if is_counter == false:
			yield(handle_counter(source), 'completed')
		return emit_signal("animation_finished")

	# Show damage numbers
	show_pop_label(
		String(floor(100 * hit.damage)), 
		Color(0.905882, 0, 0) if hit.crit else Color.white
	)

	# Handle shields change
	if state.shields > 0:
		if source != null && is_instance_valid(source) && source.alive && source.state.attributes.flag_shieldburn > 0:
			state.shields = 0
		elif state.shields > hit.damage:
			state.shields -= hit.damage
			hit.damage = 0
		else:
			hit.damage -= state.shields
			state.shields = 0
		var rect = Rect2(0, 0, 128, state.shields * sprite_height + sprite_y_offset)
		tween.interpolate_property(shields, "region_rect", shields.region_rect, rect, 0.2)

	# Handle health change
	var before = state.damage
	state.damage += hit.damage
	if (state.damage >= 0.99):
		alive = false
	var new_height = state.damage * sprite_height
	var new_offset = Vector2(-64, -64 + sprite_y_offset + sprite_height - new_height)
	var new_rect = Rect2(0, sprite_y_offset + sprite_height - new_height, 128, new_height)
	tween.interpolate_property(damage, "offset", damage.offset, new_offset, 0.2)
	tween.interpolate_property(damage, "region_rect", damage.region_rect, new_rect, 0.2)

	emit_signal('damage_taken', state.damage - before)
	emit_signal('health_changed')

	# On hit animation
	var angle = 0.1 if vector.x > 0 else -0.1
	tween.interpolate_property(sprite, "position", Vector2.ZERO, vector * 0.1, 0.2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	tween.interpolate_property(sprite, "rotation", rotation, rotation + angle, 0.2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	if (state.damage < 0.99):
		tween.interpolate_property(sprite, "position", vector * 0.1, Vector2.ZERO, 0.1, Tween.TRANS_QUAD, Tween.EASE_IN_OUT, 0.2)
		tween.interpolate_property(sprite, "rotation", rotation + angle, rotation, 0.1, Tween.TRANS_QUAD, Tween.EASE_IN_OUT, 0.2)

	tween.start()
	yield(tween, "tween_all_completed")

	# Handle death
	if !alive:
		return handle_death()

	# If we survived this far, handle counters
	if is_counter == false:
		yield(handle_counter(source), 'completed')

	return emit_signal("animation_finished")


func handle_death():
	emit_signal("death")
	emit_signal("animation_finished")


func show_pop_label(text, modulate = Color.white, duration = 0.25):
	var label = PopLabel.instance()
	label.position = position - Vector2(0, 50)
	label.text = text
	label.duration = duration
	label.modulate = modulate
	get_node("/root/Main").add_child(label)


func handle_counter(source):
	if state.attributes.counter_chance > 0 && source != null && is_instance_valid(source) && source.alive:
		for direction in Config.cardinal:
			var vec = Config.direction[direction]
			if position + vec == source.position:
				if RNG.roll_chance(state.attributes.counter_chance):
					yield(counter(vec), 'completed')
	yield(get_tree(), "idle_frame")


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
			'effects': [Config.damage.default],
		},
		'source': self,
		'is_counter': true,
	}
	game.add_child(projectile)
	yield(projectile, 'animations_all_finished')


func roll_evasion(source = null):
	if state.attributes.flag_bullseye > 0:
		return false
	var evade_chance = state.attributes.evade
	if source != null && is_instance_valid(source) && source.alive:
		if source.state.attributes.flag_bullseye > 0:
			return false
		evade_chance -= source.state.attributes.reliability
	evade_chance = clamp(evade_chance, 0, 1)
	return evade_chance > 0 && RNG.roll_chance(evade_chance)


func evade(vector):
	show_pop_label('T_EVADE')
	SFX.play(SFX.sounds.DASH)
	tween.interpolate_property(sprite, "position", Vector2.ZERO, vector * 0.1, 0.2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	tween.interpolate_property(sprite, "position", vector * 0.1, Vector2.ZERO, 0.1, Tween.TRANS_QUAD, Tween.EASE_IN_OUT, 0.2)
	tween.start()
	yield(tween, "tween_all_completed")
