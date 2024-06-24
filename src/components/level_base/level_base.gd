extends Node2D
tool

# This is mirrored in /config.gd
enum level_types { 
	NORMAL,
	SURVIVAL,
	MEGASPRITE,
	BLOCK_EXIT,
	GATE,
	WEATHER,
	FRICTION,
	KEEP_MOVING,
	NORMAL_FLAVORLESS,
}

const tile = {
	'player': 0,
	'exit': 1,
	'spawner': 15,
	'treasure': 2,
	'enemy_random': 3,
	'byte': 4,
	'charger': 5,
	'diode': 6,
	'glitch': 7,
	'kilobyte': 8,
	'baud': 9,
	'macro': 10,
	'micro': 14,
	'triode': 11,
	'buffer': 12,
	'elite': 13,
}

export(level_types) var level_type = 0
export var difficulty_min = 0
export var difficulty_max = 0
export var turn_limit = -1
export var survive_turns = -1
export var random_byte = false
export var random_macro = false
export var random_glitch = false
export var random_diode = false
export var random_charger = false
export var random_baud = false
export var random_triode = false
export var random_buffer = false
export var random_kilobyte = false
export var random_micro = false
export var random_elite = false

var types = []

func _ready():
	if !Engine.editor_hint:
		$Entities.visible = false
		for type in Config.enemies.keys():
			if self['random_' + type]:
				types.append(type)


func get_entities_by_id(id):
	var entities = []
	for cell in $Entities.get_used_cells_by_id(id):
		entities.append($Entities.map_to_world(cell))
	return entities


func get_floor_cells():
	var cells = []
	for cell in $Floor.get_used_cells():
		cells.append($Floor.map_to_world(cell))
	return cells


func update_boss_damage(percentage):
	var damage = $Boss/Damage
	var tween = $Boss/Tween
	var new_height = percentage * 512
	var new_offset = Vector2(-256, -256 + 512 - new_height)
	var new_rect = Rect2(0, 512 - new_height, 512, new_height)
	tween.interpolate_property(damage, "offset", damage.offset, new_offset, 0.2)
	tween.interpolate_property(damage, "region_rect", damage.region_rect, new_rect, 0.2)
	tween.start()
