extends Node

const POOL_SIZE = 8
var pool = []
var next_player = 0
var timestamps = {}

enum sounds {
	BALLISTIC_FIRE,
	BALLISTIC_HIT,
	BEAM,
	BUFF,
	BUZZ,
	CLICK,
	DASH_REVERSE,
	DASH,
	DEBUFF,
	ITEM_AUGMENT,
	ITEM_DROP_UNIQUE,
	ITEM_DROP,
	LAY_TRAP,
	LEVEL_CLEAR,
	LIGHTNING_1,
	LIGHTNING_2,
	LIGHTNING_3,
	LIGHTNING_4,
	LIGHTNING_5,
	LIGHTNING_6,
	LIGHTNING_7,
	LIGHTNING_SHOT,
	MOVE_ENEMY,
	MOVE_PLAYER,
	OPEN_TREASURE,
	PLAYER_DAMAGE,
	PUSH_COLLIDE_1,
	PUSH_COLLIDE_2,
	PUSH_COLLIDE_3,
	PUSH_COLLIDE_4,
	PUSH_COLLIDE,
	PUSH_FALL,
	PUSH_FIRE,
	SALVAGE,
	SHATTER,
	SWOOSH_1,
	SWOOSH_2,
	SWOOSH_3,
	SWOOSH_4,
	SWOOSH_5,
	SWOOSH_6,
	TREASURE_DISAPPEAR,
	TREASURE_DROP,
	TURN_NOTIFICATION,
}

const streams = {
	sounds.BALLISTIC_FIRE: preload("res://assets/sfx/ballistic_projectile_fire.wav"),
	sounds.BALLISTIC_HIT: preload("res://assets/sfx/ballistic_projectile_hit.wav"),
	sounds.BEAM: preload("res://assets/sfx/beam_projectile.wav"),
	sounds.BUFF: preload("res://assets/sfx/buff.wav"),
	sounds.CLICK: preload("res://assets/sfx/click.wav"),
	sounds.DASH: preload("res://assets/sfx/dash_forward.wav"),
	sounds.DEBUFF: preload("res://assets/sfx/debuff.wav"),
	sounds.SHATTER: preload("res://assets/sfx/entity_death.wav"),
	sounds.MOVE_ENEMY: preload("res://assets/sfx/entity_moves_enemy.wav"),
	sounds.MOVE_PLAYER: preload("res://assets/sfx/entity_moves_player.wav"),
	sounds.ITEM_DROP_UNIQUE: preload("res://assets/sfx/item_drop_unique.wav"),
	sounds.ITEM_DROP: preload("res://assets/sfx/item_drop.wav"),
	sounds.LAY_TRAP: preload("res://assets/sfx/lay_trap.wav"),
	sounds.OPEN_TREASURE: preload("res://assets/sfx/open_treasure.wav"),
	sounds.SALVAGE: preload("res://assets/sfx/salvage_item.wav"),
	sounds.LEVEL_CLEAR: preload("res://assets/sfx/stage_clear.wav"),
	sounds.TURN_NOTIFICATION: preload("res://assets/sfx/turn_notification.wav"),
	sounds.ITEM_AUGMENT: preload("res://assets/sfx/upgrade_item.wav"),
	sounds.PLAYER_DAMAGE: preload("res://assets/sfx/x_entity_damage_player.wav"),
	sounds.BUZZ: preload("res://assets/sfx/glitch_flicker_buzz_2.wav"),
	sounds.PUSH_FIRE: preload("res://assets/sfx/push_fire.wav"),
	sounds.PUSH_COLLIDE: preload("res://assets/sfx/push_enemy_collide.wav"),
	sounds.PUSH_FALL: preload("res://assets/sfx/push_enemy_fall.wav"),
	sounds.TREASURE_DROP: preload("res://assets/sfx/open_treasure2.wav"),
	sounds.TREASURE_DISAPPEAR: preload("res://assets/sfx/treasure_dismiss.wav"),
	sounds.DASH_REVERSE: preload("res://assets/sfx/dash_reverse.wav"),
	sounds.SWOOSH_1: preload("res://assets/sfx/quick_swoosh_for_overlays.wav"),
	sounds.SWOOSH_2: preload("res://assets/sfx/quick_swoosh_for_overlays2.wav"),
	sounds.SWOOSH_3: preload("res://assets/sfx/quick_swoosh_for_overlays3.wav"),
	sounds.SWOOSH_4: preload("res://assets/sfx/quick_swoosh_for_overlays4.wav"),
	sounds.SWOOSH_5: preload("res://assets/sfx/quick_swoosh_for_overlays5.wav"),
	sounds.SWOOSH_6: preload("res://assets/sfx/quick_swoosh_for_overlays6.wav"),
	sounds.PUSH_COLLIDE_1: preload("res://assets/sfx/push_enemy_collide1.wav"),
	sounds.PUSH_COLLIDE_2: preload("res://assets/sfx/push_enemy_collide2.wav"),
	sounds.PUSH_COLLIDE_3: preload("res://assets/sfx/push_enemy_collide3.wav"),
	sounds.PUSH_COLLIDE_4: preload("res://assets/sfx/push_enemy_collide4.wav"),
	sounds.LIGHTNING_SHOT: preload("res://assets/sfx/lightning_shot.wav"),
	sounds.LIGHTNING_1: preload("res://assets/sfx/lightning_arc1.wav"),
	sounds.LIGHTNING_2: preload("res://assets/sfx/lightning_arc2.wav"),
	sounds.LIGHTNING_3: preload("res://assets/sfx/lightning_arc3.wav"),
	sounds.LIGHTNING_4: preload("res://assets/sfx/lightning_arc4.wav"),
	sounds.LIGHTNING_5: preload("res://assets/sfx/lightning_arc5.wav"),
	sounds.LIGHTNING_6: preload("res://assets/sfx/lightning_arc6.wav"),
	sounds.LIGHTNING_7: preload("res://assets/sfx/lightning_arc7.wav"),
}

var variants = {
	'lightning': [
		sounds.LIGHTNING_1,
		sounds.LIGHTNING_2,
		sounds.LIGHTNING_3,
		sounds.LIGHTNING_4,
		sounds.LIGHTNING_5,
		sounds.LIGHTNING_6,
		sounds.LIGHTNING_7,
	],
	'collide': [
		sounds.PUSH_COLLIDE_1,
		sounds.PUSH_COLLIDE_2,
		sounds.PUSH_COLLIDE_3,
		sounds.PUSH_COLLIDE_4,
	],
	'swoosh': [
		sounds.SWOOSH_1,
		sounds.SWOOSH_2,
		sounds.SWOOSH_3,
		sounds.SWOOSH_4,
		sounds.SWOOSH_5,
		sounds.SWOOSH_6,
	],
}

func _ready():
	for _i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = 'SFX'
		add_child(player)
		pool.append(player)
	for sound in sounds:
		timestamps[sounds[sound]] = 0


func _get_next_player_id():
	var next = next_player
	next_player = (next_player + 1) % POOL_SIZE
	return next


func play(sound, delay = 0.0):
	if OS.get_ticks_msec() - timestamps[sound] > 100:
		if (delay > 0):
			yield(get_tree().create_timer(delay), "timeout")
		var player = pool[_get_next_player_id()]
		player.stream = streams[sound]
		player.play()
		timestamps[sound] = OS.get_ticks_msec()


func play_variant(variant, delay = 0.0):
	play(variants[variant][randi() % variants[variant].size()], delay)
