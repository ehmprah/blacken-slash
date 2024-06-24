extends Node

signal game_ready
signal gear_updated
signal achievement_unlocked
signal meta_bonus

var game = null
var profile = null
var save_normal = null
var save_ladder = null

var profile_template = {
	'version': '0.8',
	'materials': 0,
	'difficulty_record': 0,
	'score_record': -1,
	'vault': [],
	'achievements': {},
	'found': [],
	'uuid': '',
	'name': '',
	'ladder': null,
	'welcome': false,
	'statistics': {
		Config.GAME_NORMAL: {
			'games': 0,
			'level': 0,
			'score': 0,
			'kills': 0,
			'kernels': 0,
			'legendaries': 0,
			'epics': 0,
		},
		Config.GAME_LADDER: {
			'games': 0,
			'level': 0,
			'score': 0,
			'kills': 0,
			'kernels': 0,
			'legendaries': 0,
			'epics': 0,
		},
	},
	'decrypted': {},
	'story': {},
	'reviewed': false,
}

var game_template = {
	'version': '1.2',
	'type': Config.GAME_NORMAL,
	'materials': 0,
	'vaultable': 0,
	'phase': Config.PHASE_LEVEL_PLAY,
	'difficulty': {
		'current': 1,
		'beaten': 0,
		'record': 0,
		'upgrades': 0,
	},
	'score': 0,
	'score_modifier': 0.0,
	'rng': {
		'seed': null,
		'state': null,
	},
	'slots': Config.slots.duplicate(),
	'sets': {},
	'gear': [],
	'loot': [],
	'damage': 0,
	'regen_uses': 0,
	'attributes': {},
	'modifiers': {
		'player': {},
		'enemy': {},
	},
	'meta': {
		'type': null,
		'rewarded': 0,
	},
	'level': {
		'next': '',
		'plays': {},
	},
	'stats_level': {
		# Counted towards stats_run
		'damage_skills': 0,
		'hits_taken': 0,
		'moves': 0,
		# Temporary ones
		'turns_taken': 0,
		'stationary': 0,
		'momentum': 0,
		'meta': 0,
		'loot': 0,
	},
	'stats_run': {
		'damage_skills': 0,
		'hits_taken': 0,
		'moves': 0,
		# Counted towards profile.statistics
		'legendaries': 0,
		'epics': 0,
		'kills': 0,
		'kernels': 0,
	},
}

func continue_game(type):
	if type == Config.GAME_LADDER:
		game = save_ladder
	if type == Config.GAME_NORMAL:
		game = save_normal
	RNG.init(game.rng)
	emit_signal('game_ready')


func start_game(type, meta):
	game = game_template.duplicate(true)
	game.type = type
	game.meta.type = meta
	game.difficulty.record = profile.difficulty_record
	if type == Config.GAME_LADDER:
		game.season = Util.get_season().current
		game.rng.seed = String(game.season)
	else:
		game.rng.seed = String(randf())
		# Transfer current materials from the profile to the game
		game.materials = profile.materials
		profile.materials = 0
		save_profile()
		if profile.vault.size() > 0:
			game.phase = Config.PHASE_FROM_VAULT
		# Handle debug helpers
		if Config.debug.has('roll_items'):
			for params in Config.debug.roll_items:
				for item in Config.items:
					var selected = true
					for property in params.keys():
						if !item.has(property) || item[property] != params[property]:
							selected = false
					if selected:
						game.gear.append(RNG.furnish_item(item.duplicate(true)))
						game.slots[item.type] -= 1
		if Config.debug.has('create_item'):
			game.gear.append(RNG.furnish_item(Config.debug.create_item.duplicate(true)))
			game.slots[Config.debug.create_item.type] -= 1
		if Config.debug.has('add_materials'):
			game.materials += Config.debug.add_materials
		if Config.debug.has('set_difficulty'):
			game.difficulty.beaten = Config.debug.set_difficulty - 1
			game.difficulty.current = Config.debug.set_difficulty
		if Config.debug.has('set_record'):
			game.difficulty.record = Config.debug.set_record
	RNG.init(game.rng)
	if game.meta.type == -1 && profile.difficulty_record > 0:
		game.meta.type = RNG.array_random(Config.meta.values())
	RNG.roll_level()
	save_game()
	update_achievement('T_ROGUELIKER', 1)
	emit_signal('game_ready')


func get_phase():
	if game != null:
		return game.phase
	return -1


func add_materials(amount):
	game.materials += amount
	game.stats_run.kernels += amount
	update_achievement('T_SCROOGE', game.materials, true)


func meta_bonus():
	add_materials(Config.globals.meta_bonus_amount)
	game.meta.rewarded += 1
	emit_signal('meta_bonus')
	if game.meta.rewarded == Config.globals.meta_bonus_times:
		update_achievement(Config.meta_labels[game.meta.type].achievement, 1)
		var grandmaster = true
		for key in Config.meta_labels:
			if key > -1:
				var achievement = Config.meta_labels[key].achievement
				if !profile.achievements.has(achievement) || profile.achievements[achievement] < 1:
					grandmaster = false
					break
		if grandmaster:
			update_achievement('T_META_GRANDMASTER', 1)


func calculate_gear_effects():
	game.skills = [Config.skills.move]
	game.attributes = Config.attributes_base.duplicate()
	game.sets.clear()
	for item in game.gear:
		if item.has('skill'):
			game.skills.append(Config.skills[item.skill])
		if item.has('set'):
			if !game.sets.has(item.set):
				game.sets[item.set] = {}
			game.sets[item.set][item.name] = 0
		for attribute in item.attributes:
			# Handle flags
			if !attribute.has('key'):
				game.attributes[attribute.name] = 1
				continue
			game.attributes[attribute.key] += attribute.value
			# Respect attribute cap
			if attribute.has('cap') && game.attributes[attribute.key] > attribute.cap:
				game.attributes[attribute.key] = attribute.cap
	# Handle flags
	if game.attributes.flag_bitshift > 0:
		game.attributes.regeneration = 0
		game.attributes.shields *= 2
		if game.attributes.shields > 1:
			game.attributes.shields = 1
	# Add set bonuses 
	for set in game.sets.keys():
		var amount = game.sets[set].size()
		var thresholds = Config.sets[set].keys()
		if amount == thresholds.max():
			update_achievement('T_COLLECTOR', 1)
		for threshold in thresholds:
			if amount >= threshold:
				for key in Config.sets[set][threshold].keys():
					game.attributes[key] += Config.sets[set][threshold][key]
	# Add boss modifiers
	for key in game.modifiers.player:
		game.attributes[key] += game.modifiers.player[key]
	if game.gear.size() == 9:
		update_achievement('T_FIRST_STEPS', 1)
		var legendaries = 0
		for item in game.gear:
			if item.rarity > Config.RARITY_RARE:
				legendaries += 1
		if legendaries == 9:
			update_achievement('T_SHINY_HINEY', 1)
	emit_signal('gear_updated')


func update_achievement(name, value, reset = false):
	var achievement = Config.achievements[name]
	if !profile.achievements.has(name):
		profile.achievements[name] = float(value) / float(achievement.goal)
	elif profile.achievements[name] == 1:
		return
	elif reset:
		profile.achievements[name] = float(value) / float(achievement.goal)
	else:
		profile.achievements[name] += float(value) / float(achievement.goal)
	if profile.achievements[name] >= 1:
		profile.achievements[name] = 1
		emit_signal('achievement_unlocked', achievement)
		SteamAPI.unlock_achievement(name)
		update_achievement('T_COMPLETIONIST', 1)


func update_profile():
	for key in profile_template.keys():
		if !profile.has(key):
			if profile_template[key] is int || profile_template[key] is bool:
				profile[key] = profile_template[key]
			else:
				profile[key] = profile_template[key].duplicate(true)


func fill_unlocks():
	for key in ['type_0', 'type_1', 'rarity_0', 'rarity_1', 'rarity_2', 'rarity_3']:
		if !profile.decrypted.has(key):
			profile.decrypted[key] = false
	for key in Config.attributes:
		if !key.begins_with('flag'):
			if !profile.decrypted.has(key):
				profile.decrypted[key] = false
	for key in Config.skills:
		if Config.skills[key].has('_item_types'):
			if !profile.decrypted.has(key):
				profile.decrypted[key] = false


func update_steam_achievements():
	for name in profile.achievements:
		if profile.achievements[name] == 1:
			SteamAPI.unlock_achievement(name)


func save_profile():
	save_file("user://profile.bin", profile)


func load_profile():
	var data = load_file("user://profile.bin")
	if data && data.has('version') && data.version == profile_template.version:
		profile = data
		update_profile()
		fill_unlocks()
		update_steam_achievements()
		_fix_completionist()
	else:
		profile = profile_template.duplicate(true)
		profile.uuid = Util.uuidv4()
		fill_unlocks()


func save_game():
	game.rng.state = RNG.get_state()
	if game.type == Config.GAME_LADDER:
		save_file("user://ladder.bin", game)
	else:
		save_file("user://game.bin", game)


func load_game():
	var data = load_file("user://game.bin")
	if data && data.has('version') && data.version == game_template.version:
		save_normal = data
	data = load_file("user://ladder.bin")
	if data && data.has('version') && data.version == game_template.version:
		save_ladder = data
		# Expire past season ladder games
		if save_ladder.season != Util.get_season().current:
			save_ladder.phase = Config.PHASE_GAME_OVER


func delete_game(type):
	var dir = Directory.new()
	if type == Config.GAME_NORMAL:
		if dir.file_exists("user://game.bin"):
			dir.remove("user://game.bin")
			save_normal = null
	if type == Config.GAME_LADDER:
		if dir.file_exists("user://ladder.bin"):
			dir.remove("user://ladder.bin")
			save_ladder = null


func save_file(filename, data):
	var f = File.new()
	var err = f.open_encrypted_with_pass(filename, File.WRITE, 'blacken')
	if err == OK:
		f.store_string(var2str(data))
		f.close()
	else:
		print('error saving file')


func load_file(filename):
	var f = File.new()
	var err = f.open_encrypted_with_pass(filename, File.READ, 'blacken')
	return str2var(f.get_as_text()) if err == OK else false


func _fix_completionist():
	var total = 0
	for name in profile.achievements:
		if profile.achievements[name] == 1:
			total += 1
	if total == Config.achievements.T_COMPLETIONIST.goal:
		emit_signal('achievement_unlocked', Config.achievements.T_COMPLETIONIST)
		SteamAPI.unlock_achievement("T_COMPLETIONIST")
