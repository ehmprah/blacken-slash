extends Node

signal item_found
signal new_item_found

var rng = RandomNumberGenerator.new()

func init(params):
	rng.seed = hash(params.seed)
	if params.state != null:
		rng.state = params.state


func get_state():
	return rng.state


func array_random(array):
	return array[rng.randi() % array.size()]


func array_random_n(array, amount):
	var chosen = []
	var indices = range(0, array.size())
	for n in amount:
		var index = array_random(indices)
		chosen.append(array[index])
		indices.erase(index)
	return chosen


func array_random_index(array):
	return rng.randi() % array.size()


func roll_range(value_min, value_max):
	return rng.randf_range(value_min, value_max)


func roll_loot(drops):
	var loot = { 'items': [], 'materials': 0 }
	if State.game.phase == Config.PHASE_LEVEL_PLAY:
		# There are absolutely no drops in the first level
		if State.game.difficulty.current == 1:
			return loot
		# We guarantee one tool drops in levels 2, 3, 4
		if State.game.difficulty.current < 5 && State.game.loot.size() == 0:
			var item = roll_item(Config.ITEM_TOOL, roll_item_rarity())
			emit_signal("item_found", item)
			loot.items.append(item)
			State.game.loot.append_array(loot.items)
			return loot
	# From there on out we roll items normally
	var loot_modifier = 1 + State.game.attributes.loot_bonus
	# We double the loot drop rate until the first item drops
	if State.game.loot.size() == 0:
		loot_modifier += 1
	if rng.randf() <= drops.items.chance * loot_modifier:
		var amount = 1
		if drops.items.max > 1:
			amount = rng.randi_range(1, drops.items.max)
		while (amount):
			var rarity = roll_item_rarity()
			var type = roll_item_type()
			var item = roll_item(type, rarity)
			emit_signal("item_found", item)
			loot.items.append(item)
			amount -= 1
		State.game.loot.append_array(loot.items)
		return loot
	# Roll materials
	if rng.randf() <= drops.materials.chance:
		var materials = rng.randi_range(5, drops.materials.max)
		loot.materials += floor(materials * (1 + State.game.attributes.material_gain_bonus))
	return loot


func roll_gigagun():
	var item = furnish_item({
		'_roll_skill': 1,
		'_roll_attributes' : 1,
		'rarity': Config.RARITY_EPIC,
		'type': Config.ITEM_TOOL,
		'skill': null,
		'attributes': [],
		'name': 'T_GIGAGUN',
		'prefix': '',
		'suffix': '',
	})
	item.attributes[0].value = item.attributes[0].augment_max * 4
	item.attributes[0].augmented = true
	emit_signal("item_found", item)
	State.game.loot.append(item)


func roll_salvage_materials(item):
	var gain = 50 * (1 + item.rarity)
	gain += rng.randi_range(1, 20)
	gain *= 1 + State.game.attributes.material_gain_bonus
	return ceil(gain)


func roll_item(type, rarity):
	var item_candidates = []
	for item in Config.items:
		if item.type == type && item.rarity == rarity:
			item_candidates.append(item)
	var item = array_random(item_candidates).duplicate(true)
	if item.rarity > Config.RARITY_RARE:
		State.update_achievement('T_TREASURE_HUNTER', 1)
		var key = item.prefix + item.name + item.suffix
		if !State.profile.found.has(key):
			State.profile.found.append(key)
			emit_signal('new_item_found')
			# Progress for holy grail achievement
			var total = 0
			var found = 0
			for data in Config.items:
				if data.rarity > Config.RARITY_RARE:
					total += 1
					if State.profile.found.has(data.prefix + data.name + data.suffix):
						found += 1
			State.update_achievement('T_HOLY_GRAIL', float(found) / float(total), true)
	# Handle epic uproll
	if State.game.difficulty.current > 50:
		var epic_chance = 0.2 if State.game.attributes.flag_double_epic > 0 else 0.1
		if rng.randf() < epic_chance:
			if item.rarity == Config.RARITY_LEGENDARY:
				item.rarity = Config.RARITY_EPIC
			if item.rarity == Config.RARITY_SET:
				item.rarity = Config.RARITY_EPIC_SET
			if item.has('_roll_attributes'):
				item._roll_attributes += 1
			else:
				item._roll_attributes = 1
	# Save stats
	if item.rarity >= Config.RARITY_EPIC:
		State.game.stats_run.epics += 1
	elif item.rarity >= Config.RARITY_LEGENDARY:
		State.game.stats_run.legendaries += 1
	return furnish_item(item)


func furnish_item(item):
	if item.has('_roll_skill'):
		var skill_candidates = []
		for key in Config.skills:
			var skill = Config.skills[key]
			if (
				skill.has('_level_min') && 
				State.game.difficulty.record >= skill._level_min &&
				skill.has('_item_types') && 
				skill._item_types.has(item.type)
			):
				skill_candidates.append(key)
		item.skill = array_random(skill_candidates)

	if item.has('_add_attributes'):
		for key in item._add_attributes:
			var attribute = Config.attributes[key].duplicate(true)
			if attribute.has('_roll_value'):
				attribute.value = Util.round_to_digit(
					rng.randf_range(attribute._roll_value.min, attribute._roll_value.max
				), 2)
			item.attributes.append(Util.clean_(attribute))

	if item.has('_roll_attributes'):
		roll_attributes(item, item._roll_attributes)

	if item.name == '':
		item.name = array_random(Config.item_types[item.type].names)
		if roll_chance(0.5):
			item.prefix = array_random(Config.prefixes)
		else:
			item.suffix = array_random(Config.suffixes)

	return Util.clean_(item)


func roll_attributes(item, amount, replace_index = -1):
	var exceptions = []
	for attr in item.attributes:
		if attr.has('key'):
			exceptions.append(attr.key)
	var attribute_candidates = []
	for attr in Config.attributes.values():
		if (
			!exceptions.has(attr.key) && 
			attr.has('_level_min') && 
			State.game.difficulty.record >= attr._level_min &&
			attr.has('_item_types') && 
			attr._item_types.has(item.type)
		):
			attribute_candidates.append(attr)
	for n in amount:
		var attribute
		if attribute_candidates.size() == 0:
			continue
		elif attribute_candidates.size() == 1:
			attribute = attribute_candidates[0].duplicate(true)
			attribute_candidates.remove(0)
		else:
			var index = array_random_index(attribute_candidates)
			attribute = attribute_candidates[index].duplicate(true)
			attribute_candidates.remove(index)
		if attribute.has('_roll_value'):
			attribute.value = Util.round_to_digit(
				rng.randf_range(attribute._roll_value.min, attribute._roll_value.max
			), 2)
		if replace_index >= 0:
			item.attributes[replace_index] = Util.clean_(attribute);
		else:
			item.attributes.append(Util.clean_(attribute))


func roll_item_type():
	if State.game.difficulty.record < 3:
		return Config.ITEM_TOOL
	return array_random(Config.item_types.keys())


func roll_item_rarity():
	var roll = rng.randf()
	if (
		State.game.difficulty.record >= 5 && 
		roll <= Config.rarities[Config.RARITY_LEGENDARY]
	):
		return array_random([Config.RARITY_SET, Config.RARITY_LEGENDARY])
	elif (
		State.game.difficulty.record >= 3 &&
		roll <= Config.rarities[Config.RARITY_RARE]
	):
		return Config.RARITY_RARE
	else:
		return Config.RARITY_COMMON


func roll_level():
	var difficulty = State.game.difficulty.current
	var boss_level = difficulty % Config.sector_size == 0
	var candidates = []
	var lowest_plays = 999
	for key in Levels.data:
		var lvl = Levels.data[key]
		# Respect difficulty limits
		if (
			lvl.difficulty_min <= difficulty && 
			difficulty <= lvl.difficulty_max &&
			(
				(boss_level && lvl.type == Config.level_types.GATE) ||
				(!boss_level && lvl.type != Config.level_types.GATE)
			)
		):
			candidates.append(key)
			if !State.game.level.plays.has(key):
				lowest_plays = 0
			elif lowest_plays > State.game.level.plays[key]:
				lowest_plays = State.game.level.plays[key]
	if candidates.size() > 0:
		var index = candidates.size() - 1
		while index > -1:
			if (
				State.game.level.plays.has(candidates[index]) && 
				State.game.level.plays[candidates[index]] > lowest_plays
			):
				candidates.remove(index)
			index -= 1
		var chosen = array_random(candidates)
		State.game.level.next = chosen
		if !State.game.level.plays.has(chosen):
			State.game.level.plays[chosen] = 0
		State.game.level.plays[chosen] += 1


func roll_damage(damage, attributes):
	var roll = rng.randf_range(damage.min, damage.max)
	var crit = rng.randf() < attributes.critical_chance
	if crit:
		roll *= 1 + attributes.critical_bonus
	return { 'damage': roll, 'crit': crit }


func roll_chance(chance):
	return rng.randf() <= chance
