extends Node2D

const AchievementUnlocked = preload('res://components/achievement_unlocked/achievement_unlocked.tscn')
const DemoOver = preload('res://components/demo_over/demo_over.tscn')

var is_playing = false

onready var game = $Game
onready var sector = $Background/Sector
onready var grid = $Background/Sector/Grid
onready var tween = $Background/Sector/Tween
onready var grayscale = $FilterGrayscale
onready var ui = $UI

func _ready():
	randomize()
	State.connect('achievement_unlocked', self, '_on_achievement_unlocked')
	State.connect('game_ready', self, 'start_game')
	ui.level_clear.connect('clear_continue', self, 'level_clear_continue')
	# Try and load the saved state
	State.load_profile()
	State.load_game()
	ui.title.show()


func _notification(what: int):
	match what:
		MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
			# Handle Android back button
			if ui.title.visible == true:
				get_tree().quit()
			elif ui.menu.visible == true:
				ui.menu.hide()
			else:
				ui.menu.show()


func show_screen():
	match State.game.phase:
		Config.PHASE_FROM_VAULT:
			yield(ui.inventory.show(), 'completed')
			ui.popup('meta')
		Config.PHASE_LOOT, Config.PHASE_TO_VAULT:
			yield(ui.inventory.show(), 'completed')
		Config.PHASE_LEVEL_PLAY:
			yield(game.show(), 'completed')
		Config.PHASE_BONUS:
			yield(ui.boss_reward.show(), 'completed')
		Config.PHASE_DIFFICULTY:
			yield(ui.difficulty.show(), 'completed')
		Config.PHASE_GAME_OVER:
			yield(ui.game_over.show(), 'completed')
	show_story()


func show_story(level_type = null):
	if level_type != null:
		if Config.story.level_types.has(level_type):
			if (
				!State.profile.story.has('level_types') || 
				!State.profile.story.level_types.has(level_type)
			):
				var path = Config.story.level_types[level_type]
				ui.overlays.add_child(load(path).instance())
				if !State.profile.story.has('level_types'):
					State.profile.story.level_types = {}
				State.profile.story.level_types[level_type] = 1
	else:
		var phase = State.game.phase
		var difficulty = State.game.difficulty.current
		if (
			Config.story.has(phase) &&
			Config.story[phase].has(difficulty) &&
			(!State.profile.story.has(phase) || !State.profile.story[phase].has(difficulty))
		):
			var path = Config.story[phase][difficulty]
			ui.overlays.add_child(load(path).instance())
			if !State.profile.story.has(phase):
				State.profile.story[phase] = {}
			State.profile.story[phase][difficulty] = 1
		if (
			OS.has_feature('mobile') && 
			State.profile.reviewed == false &&
			phase == Config.PHASE_LOOT && 
			difficulty == 38
		):
			var prompt = load('res://components/review_prompt/review_prompt.tscn')
			ui.overlays.add_child(prompt.instance())


func inventory_next():
	match State.game.phase:
		Config.PHASE_FROM_VAULT:
			if State.game.slots.values().max() == 0:
				State.update_achievement('T_RICH_BITCH', 1)
			if State.game.difficulty.upgrades > 0:
				State.game.phase = Config.PHASE_DIFFICULTY
				State.save_game()
				return show_screen()
			next_level()
		Config.PHASE_LOOT:
			State.save_game()
			next_level()


func next_level():
	Music.xfade(Music.MAIN)
	State.game.phase = Config.PHASE_LEVEL_PLAY
	show_screen()


func level_clear():
	if State.game.phase == Config.PHASE_GAME_OVER:
		return
	if State.game.damage > 0.95:
		State.update_achievement('T_CLOSE_CALL', 1)
	if State.game.stats_level.moves == 0:
		State.update_achievement('T_STATIONARY', 1)
	var flags = {
		'unlocked': false,
		'beaten': false,
		'pacifist': State.game.stats_level.damage_skills == 0,
		'first_strike': State.game.stats_level.turns_taken == 0,
		'elusive': State.game.stats_level.turns_taken > 0 && State.game.stats_level.hits_taken == 0,
	}
	if flags.pacifist:
		State.add_materials(25)
	if flags.elusive:
		State.add_materials(25)
	if flags.first_strike:
		State.add_materials(50)
		if State.game.difficulty.current >= 25:
			State.update_achievement('T_FIRST_STRIKE', 1)
	if State.game.difficulty.current > State.game.difficulty.beaten:
		State.game.difficulty.beaten = State.game.difficulty.current
		flags.beaten = true
		if State.game.difficulty.beaten == 25:
			# Check common sense achievement
			var only_commons = true
			for item in State.game.gear:
				if item.rarity > Config.RARITY_COMMON:
					only_commons = false
			if only_commons:
				State.update_achievement('T_COMMON_SENSE', 1)
			if State.game.stats_run.damage_skills == 0:
				State.update_achievement('T_PACIFIST', 1)
			if State.game.stats_run.hits_taken == 0:
				State.update_achievement('T_ELUSIVE', 1)
		if State.game.type == Config.GAME_LADDER:
			submit_ladder_progress()
			State.update_achievement('T_CHALLENGER', State.game.difficulty.beaten, true)
			State.update_achievement('T_BRAGGING_RIGHTS', State.game.difficulty.beaten, true)
		State.update_achievement('T_MILESTONE', State.game.difficulty.beaten, true)
		State.update_achievement('T_END_OF_THE_BEGINNING', State.game.difficulty.beaten, true)
		State.update_achievement('T_BEGINNING_OF_THE_END', State.game.difficulty.beaten, true)
		if State.game.difficulty.beaten == 50:
			RNG.roll_gigagun()
	if State.game.difficulty.current > State.game.difficulty.record:
		State.game.difficulty.record += 1
		flags.unlocked = true
	State.game.difficulty.current += 1
	update_sector_color()
	RNG.roll_level()
	SFX.play(SFX.sounds.LEVEL_CLEAR)
	if Settings.user.gameplay.skip_level_clear == false:
		ui.level_clear.show_notifications(flags)
	else:
		level_clear_continue()


func level_clear_continue():
	if State.game.difficulty.beaten % Config.sector_size == 0:
		State.game.phase = Config.PHASE_BONUS
		Music.fade(Music.BOSS)
	else:
		State.game.phase = Config.PHASE_LOOT
		Music.xfade(Music.OFF)
	if State.game.difficulty.beaten == 13 && OS.has_feature('demo'):
		State.game.phase = Config.PHASE_GAME_OVER
		ui.overlays.add_child(DemoOver.instance())
	if State.game.difficulty.beaten == 100:
		State.game.phase = Config.PHASE_GAME_OVER
	ui.inventory.update()
	State.save_game()
	# Since we now do this sparingly, at least do it once after the level
	State.save_profile()
	show_screen()


func submit_ladder_progress():
	var data = {
		'version': Config.version,
		'hash': '',
		'uuid': State.profile.uuid,
		'name': State.profile.name.http_escape(),
		'season': State.game.season,
		'difficulty': State.game.difficulty.beaten,
		'modifier': State.game.score_modifier,
		'gear': Util.simplify_gear(),
		'dead': State.game.phase == Config.PHASE_GAME_OVER
	}
	data.hash = String(data.difficulty * 10 + data.season).sha256_text()
	State.profile.ladder = data
	ui.ladder.purge_cache()
	var url = Config.backend + '/updateLadder'
	var body = to_json(data)
	$HTTP.request(url, ["Content-Type: text/plain"], true, HTTPClient.METHOD_POST, body)


func game_over():
	grayscale.reset_grayscale()
	update_sector_color(true)
	Music.xfade(Music.OFF)
	State.game.phase = Config.PHASE_GAME_OVER
	State.game.damage = 0
	State.game.score = floor(State.game.difficulty.beaten * (State.game.score_modifier + 1))
	if State.game.type == Config.GAME_LADDER:
		submit_ladder_progress()
	State.save_game()
	show_screen()


func save_and_quit():
	# Because of the autosave, we only have to save in the inventory and beyond
	if State.game.phase >= Config.PHASE_LOOT:
		State.save_game()
	Music.stop()
	get_tree().reload_current_scene()
	grayscale.reset_grayscale()
	update_sector_color(true)


func end_run():
	$Game.hide()
	ui.inventory.hide()
	game_over()


func vault_items():
	if State.game.vaultable > 0:
		State.game.phase = Config.PHASE_TO_VAULT
		ui.inventory.update()
		show_screen()
	else:
		end_game()


func end_game():
	State.profile.materials += State.game.materials
	if State.game.difficulty.record > State.profile.difficulty_record:
		State.profile.difficulty_record = State.game.difficulty.record
	if State.game.score > State.profile.score_record:
		State.profile.score_record = State.game.score
	# Save stats
	var stats = State.profile.statistics[State.game.type]
	stats.games += 1
	if State.game.difficulty.beaten > stats.level:
		stats.level = State.game.difficulty.beaten
	if State.game.score > stats.score:
		stats.score = State.game.score
	stats.kills += State.game.stats_run.kills
	stats.kernels += State.game.stats_run.kernels
	stats.legendaries += State.game.stats_run.legendaries
	stats.epics += State.game.stats_run.epics
	State.save_profile()
	State.delete_game(State.game.type)
	State.game = null
	is_playing = false
	ui.title.show()


func update_sector_color(reset = false):
	if reset:
		grid.visible = true
		tween.interpolate_property(sector, "modulate", sector.modulate, Color.black, 0.2)
		tween.start()
	else:
		var difficulty = State.game.difficulty.current
		grid.visible = difficulty <= 50
		var color = Color.black
		if difficulty <= 50:
			color = Config.sectors[floor((difficulty - 1) / Config.sector_size)].color
		tween.interpolate_property(sector, "modulate", sector.modulate, color, 0.2)
		tween.start()


func prepare_game():
	# FIXME: All this could be moved to a signal, "game_enter"
	game.player.reset()
	ui.inventory.reset()
	ui.inventory.hydrate()
	State.calculate_gear_effects()
	is_playing = true


func start_game():
	prepare_game()
	update_sector_color()
	show_screen()


func _on_achievement_unlocked(achievement):
	var unlock = AchievementUnlocked.instance()
	unlock.achievement = achievement
	ui.overlays.add_child(unlock)
