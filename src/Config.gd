extends Node

const backend = 'https://us-central1-blacken-slash.cloudfunctions.net'

const version = '1.7'
const build = '25'

var debug = {
	'roll_items': [
		# { 'name': 'T_DYE_HARD'},
		# { 'set': 'T_PIXEL_PUSHER', 'name': 'T_EMITTER'},
		# { 'set': 'T_PIXEL_PUSHER', 'name': 'T_GUN'},
		# { 'set': 'T_PIXEL_PUSHER', 'name': 'T_BLASTER'},
		# { 'set': 'T_PIXEL_PUSHER', 'name': 'T_HARDWARE'},
	],
	# 'set_difficulty': 51,
	# 'set_record': 85,
	# 'add_materials': 150000,
	# 'roll_level': 'A_DEBUG.tscn',
	# 'create_item': {
	# 	# '_add_attributes': ['flag_drive_by'],
	# 	'_roll_attributes': 3,
	# 	'rarity': RARITY_LEGENDARY,
	# 	'type': ITEM_TOOL,
	# 	'attributes': [],
	# 	'name': 'DEBUG',
	# 	'skill': 'minelayer',
	# 	'prefix': '',
	# 	'suffix': '',
	# 	'augments': 0,
	# 	'rerolls': 0,
	# },
}

const grid_size = Vector2(64, 32)
const sector_size = 5

const direction = {
	'bottom_right': Vector2(64, 32),
	'bottom_left': Vector2(-64, 32),
	'top_left': Vector2(-64, -32),
	'top_right': Vector2(64, -32),
	'top': Vector2(0, -64),
	'right': Vector2(128, 0),
	'left': Vector2(-128, 0),
	'bottom': Vector2(0, 64),
}

const cardinal = [
	'bottom_right',
	'bottom_left',
	'top_left',
	'top_right',
]

const globals = {
	'augment_price': 20,
	'augment_modifier': 1.105,
	'reroll_price': 20,
	'reroll_modifier': 1.105,
	'gamble_price': 1500,
	'regenerate_price': 1000,
	'vault_slot_price': 3000,
	'meta_bonus_amount': 32,
	'meta_bonus_times': 320,
}

# TODO: group these enums!
enum {
	GAME_NORMAL,
	GAME_LADDER,
}

enum {
	MELEE,
	RANGED,
}

enum {
	PROJECTILE_AOE_ONLY,
	PROJECTILE_BEAM,
	PROJECTILE_BALLISTIC,
	PROJECTILE_PUSH,
	PROJECTILE_LIGHTNING,
	SKILL_SELF,
	SKILL_TELEPORT,
	SKILL_DASH,
	SKILL_DROP_MINE,
}

const locales = [
	{ 'key': 'en', 'name': 'English', 'prefix': true },
	{ 'key': 'de', 'name': 'Deutsch', 'prefix': true },
	{ 'key': 'es', 'name': 'Español', 'prefix': false },
	{ 'key': 'fr', 'name': 'Français', 'prefix': false },
	{ 'key': 'zh', 'name': '简体中文', 'prefix': true },
]

const colors = {
	'magenta': Color(1, 0.086275, 0.564706), #ff1690
	'yellow': Color(0.952941, 0.752941, 0.368627), #f3c05e
	'blue': Color(0.47451, 0.596078, 0.933333), #7998ee
	'teal': Color(0.211765, 0.803922, 0.768627), #36cdc4
	'purple': Color(0.509804, 0.211765, 0.803922), #8236cd
	'greyblue': Color(0.266667, 0.337255, 0.52549), #445686
	'grey': Color(0.8, 0.8, 0.8),
	'green': Color(0.658824, 0.803922, 0.211765),#a8cd36
	'orange': Color(0.92549, 0.478431, 0), #ec7a00
}

const sectors = [
	{ 'name': 'T_SECTOR_BLACK', 'color': Color(0, 0, 0) }, #000000
	{ 'name': 'T_SECTOR_GREEN', 'color': Color(0.117647, 0.698039, 0.25098) }, #1eb240
	{ 'name': 'T_SECTOR_TEAL', 'color': Color(0.086275, 0.85098, 1) }, #16adff
	{ 'name': 'T_SECTOR_BLUE', 'color': Color(0.235294, 0.262745, 1) }, #3c43ff
	{ 'name': 'T_SECTOR_PURPLE', 'color': Color(0.756863, 0.086275, 1) }, #c116ff
	{ 'name': 'T_SECTOR_PINK', 'color': Color(1, 0.086274, 0.564706) }, #ff1690
	{ 'name': 'T_SECTOR_RED', 'color': Color(1, 0.105882, 0.105882) }, #ff1b1b
	{ 'name': 'T_SECTOR_ORANGE', 'color': Color(0.92549, 0.478431, 0) }, #ec7a00
	{ 'name': 'T_SECTOR_YELLOW', 'color': Color(0.827451, 0.85098, 0.129412) }, #d3d921
	{ 'name': 'T_SECTOR_WHITE', 'color': Color(0.882353, 0.882353, 0.882353) }, #e1e1e1
]

enum {
	RARITY_COMMON,
	RARITY_RARE,
	RARITY_LEGENDARY,
	RARITY_SET,
	RARITY_EPIC,
	RARITY_EPIC_SET,
}

# TODO: combine those into one dict
const rarity_colors = {
	RARITY_COMMON: Color(0.65, 0.65, 0.65),
	RARITY_RARE: Color(0.188235, 0.345098, 0.827451), #3058d3
	RARITY_LEGENDARY: Color(0.737255, 0, 0.8), #Color(0.886275, 0.129412, 0.52549),
	RARITY_SET: Color(0.129412, 0.635294, 0.211765),
	RARITY_EPIC: Color(0.8, 0.546094, 0),
	RARITY_EPIC_SET: Color(0.152941, 0.721569, 0.470588),
}

const rarity_labels = {
	RARITY_COMMON: 'T_RARITY_COMMON',
	RARITY_RARE: 'T_RARITY_RARE',
	RARITY_LEGENDARY: 'T_RARITY_LEGENDARY',
	RARITY_SET: 'T_RARITY_SET',
	RARITY_EPIC: 'T_RARITY_EPIC',
	RARITY_EPIC_SET: 'T_RARITY_EPIC_SET',
}

const rarities = {
	RARITY_COMMON: 1,
	RARITY_RARE: 0.6,
	RARITY_LEGENDARY: 0.25,
}

const progress_colors = {
	'from': colors.blue,
	'to': colors.magenta,
}

const enemy_colors = {
	'red': Color(1, 0.352941, 0),
	'green': Color(0.109804, 0.838971, 0.894118),
	'yellow': Color(0.443137, 0.737255, 0),
}

# This is mirrored in /components/level_base.gd
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

enum {
	PHASE_FROM_VAULT,
	PHASE_LEVEL_PLAY,
	PHASE_LEVEL_CLEAR,
	PHASE_BONUS,
	PHASE_DIFFICULTY,
	PHASE_LOOT,
	PHASE_GAME_OVER,
	PHASE_TO_VAULT,
}

enum {
	ITEM_TOOL,
	ITEM_MODULE,
}

# TODO: add that to the item types
var slots = {
	ITEM_TOOL: 3,
	ITEM_MODULE: 6,
}

enum {
	FORMAT_PLAIN,
	FORMAT_PERCENT,
	FORMAT_FLAG
}

enum meta {
	PUSH,
	EVADE,
	CRIT,
	COUNTER,
	HIT,
	MOVE,
	AP,
}

enum status {
	MINELAYER,
}

var meta_labels = {
	-1: {
		'name': 'T_META_RANDOM',
		'desc': '',
	},
	meta.PUSH: {
		'name': 'T_META_PUSH',
		'desc': 'T_META_PUSH_DESC',
		'achievement': 'T_META_MASTERY_PUSH',
	},
	meta.EVADE: {
		'name': 'T_META_EVADE',
		'desc': 'T_META_EVADE_DESC',
		'achievement': 'T_META_MASTERY_EVADE',
	},
	meta.CRIT: {
		'name': 'T_META_CRIT',
		'desc': 'T_META_CRIT_DESC',
		'achievement': 'T_META_MASTERY_CRIT',
	},
	meta.COUNTER: {
		'name': 'T_META_COUNTER',
		'desc': 'T_META_COUNTER_DESC',
		'achievement': 'T_META_MASTERY_COUNTER',
	},
	meta.HIT: {
		'name': 'T_META_HIT',
		'desc': 'T_META_HIT_DESC',
		'achievement': 'T_META_MASTERY_HIT',
	},
	meta.MOVE: {
		'name': 'T_META_MOVE',
		'desc': 'T_META_MOVE_DESC',
		'achievement': 'T_META_MASTERY_MOVE',
	},
	meta.AP: {
		'name': 'T_META_AP',
		'desc': 'T_META_AP_DESC',
		'achievement': 'T_META_MASTERY_AP',
	},
}

var item_types = {
	ITEM_TOOL: {
		'icon': preload('res://assets/icons/icon_tool.svg'),
		'names': [
			'T_TRANSMITTER',
			'T_BLASTER',
			'T_LASER',
			'T_EMITTER',
			'T_GUN',
			'T_CANNON',
			'T_ORDNANCE',
			'T_DEVICE',
		],
	},
	ITEM_MODULE: {
		'icon': preload('res://assets/icons/icon_module.svg'),
		'names': [
			'T_CIRCUIT',
			'T_CHIPSET',
			'T_MODULE',
			'T_HARDWARE',
			'T_PROCESSOR',
			'T_GADGET',
		],
	},
}

const prefixes = [
	'T_PRISMATIC',
	'T_VOID',
	'T_STYGIAN',
	'T_ENTROPIC',
	'T_DARK',
	'T_OBLITERATING',
	'T_QUANTUM',
	'T_SUPREME',
	'T_NULLIFYING',
	'T_CALAMITOUS',
	'T_COSMIC',
	'T_PITCH_BLACK',
]

const suffixes = [
	'T_OF_BALANCE',
	'T_OF_INFINITY',
	'T_OF_DARKNESS',
	'T_OF_THE_VOID',
	'T_OF_DEATH',
	'T_OF_DESTRUCTION',
	'T_OF_OBLITERATION',
	'T_OF_EMPTINESS',
	'T_OF_DOOM',
]

const beeper_thoughts = [
	"T_BEEPER_SHOP_1",
	"T_BEEPER_SHOP_2",
	"T_BEEPER_SHOP_3",
	"T_BEEPER_SHOP_4",
	"T_BEEPER_SHOP_5",
	"T_BEEPER_SHOP_6",
	"T_BEEPER_SHOP_7",
]

const gate_rewards = [
	[
		{ 'type': 'regen', 'amount': 0.25 },
		{ 'type': 'regen', 'amount': 0.5 },
		{ 'type': 'regen', 'amount': 0.75 },
		{ 'type': 'regen', 'amount': 1 },
	],
	[
		{ 'type': 'kernels', 'amount': 500 },
		{ 'type': 'kernels', 'amount': 1000 },
		{ 'type': 'kernels', 'amount': 1500 },
		{ 'type': 'kernels', 'amount': 2000 },
		{ 'type': 'kernels', 'amount': 2500 },
	],
	[
		{ 'type': 'key', 'amount': 1 },
		{ 'type': 'key', 'amount': 2 },
		{ 'type': 'key', 'amount': 2 },
		{ 'type': 'key', 'amount': 2 },
		{ 'type': 'key', 'amount': 3 },
	],
	[
		{ 'type': 'item', 'item': ITEM_TOOL, 'rarity': RARITY_LEGENDARY },
		{ 'type': 'item', 'item': ITEM_TOOL, 'rarity': RARITY_LEGENDARY },
		{ 'type': 'item', 'item': ITEM_MODULE, 'rarity': RARITY_LEGENDARY  },
		{ 'type': 'item', 'item': ITEM_MODULE, 'rarity': RARITY_LEGENDARY  },
		{ 'type': 'item', 'item': ITEM_TOOL, 'rarity': RARITY_SET },
		{ 'type': 'item', 'item': ITEM_TOOL, 'rarity': RARITY_SET },
		{ 'type': 'item', 'item': ITEM_MODULE, 'rarity': RARITY_SET },
		{ 'type': 'item', 'item': ITEM_MODULE, 'rarity': RARITY_SET },
		{ 'type': 'item', 'item': ITEM_TOOL, 'rarity': RARITY_RARE },
		{ 'type': 'item', 'item': ITEM_MODULE, 'rarity': RARITY_RARE },
	],
]

const gate_difficulty = [
	# Low
	{ 'enemy': true, 'score': 0.08, 'attribute': 'damage_bonus', 'value': 0.16 },
	{ 'enemy': true, 'score': 0.08, 'attribute': 'resistance', 'value': 0.16 },
	{ 'enemy': true, 'score': 0.08, 'attribute': 'evade', 'value': 0.02 },
	{ 'enemy': true, 'score': 0.08, 'attribute': 'shields', 'value': 0.04 },
	{ 'enemy': true, 'score': 0.08, 'attribute': 'critical_chance', 'value': 0.04 },
	{ 'enemy': true, 'score': 0.08, 'attribute': 'counter_chance', 'value': 0.04 },
	# Medium
	{ 'enemy': true, 'score': 0.16, 'attribute': 'damage_bonus', 'value': 0.24 },
	{ 'enemy': true, 'score': 0.16, 'attribute': 'resistance', 'value': 0.24 },
	{ 'enemy': true, 'score': 0.16, 'attribute': 'evade', 'value': 0.03 },
	{ 'enemy': true, 'score': 0.16, 'attribute': 'shields', 'value': 0.06 },
	{ 'enemy': true, 'score': 0.16, 'attribute': 'critical_chance', 'value': 0.06 },
	{ 'enemy': true, 'score': 0.16, 'attribute': 'counter_chance', 'value': 0.06 },
	# High
	{ 'enemy': true, 'score': 0.32, 'attribute': 'damage_bonus', 'value': 0.32 },
	{ 'enemy': true, 'score': 0.32, 'attribute': 'resistance', 'value': 0.32 },
	{ 'enemy': true, 'score': 0.32, 'attribute': 'evade', 'value': 0.04 },
	{ 'enemy': true, 'score': 0.32, 'attribute': 'shields', 'value': 0.08 },
	{ 'enemy': true, 'score': 0.32, 'attribute': 'critical_chance', 'value': 0.08 },
	{ 'enemy': true, 'score': 0.32, 'attribute': 'counter_chance', 'value': 0.08 },
	# Ultra
	{ 'enemy': true, 'score': 0.64, 'attribute': 'flag_secureboot', 'value': 1 },
	{ 'enemy': true, 'score': 0.64, 'attribute': 'flag_shieldburn', 'value': 1 },
	{ 'enemy': true, 'score': 1.28, 'attribute': 'action_points_max', 'value': 1 },
	{ 'enemy': false, 'score': 1.28, 'attribute': 'flag_friction', 'value': 1 },
	{ 'enemy': false, 'score': 0.64, 'attribute': 'flag_fog_of_war', 'value': 1 },
	{ 'enemy': false, 'score': 1.28, 'attribute': 'flag_double_difficulty', 'value': 1 },
]

const elite_bonuses = [
	{ 'attribute': 'shields', 'value': 0.64 },
	{ 'attribute': 'damage_bonus', 'value': 0.64 },
	{ 'attribute': 'resistance', 'value': 0.64 },
]

const story = {
	PHASE_LEVEL_PLAY: {
		1: 'res://story/1_LEVEL.tscn',
		2: 'res://story/2_LEVEL.tscn',
		3: 'res://story/3_LEVEL.tscn',
		5: 'res://story/10_LEVEL.tscn',
		6: 'res://story/11_LEVEL.tscn',
		10: 'res://story/20_LEVEL.tscn',
		15: 'res://story/30_LEVEL.tscn',
		20: 'res://story/40_LEVEL.tscn',
		21: 'res://story/41_LEVEL.tscn',
		23: 'res://story/45_LEVEL.tscn',
		25: 'res://story/50_LEVEL.tscn',
		26: 'res://story/51_LEVEL.tscn',
		30: 'res://story/60_LEVEL.tscn',
		31: 'res://story/61_LEVEL.tscn',
		35: 'res://story/70_LEVEL.tscn',
		36: 'res://story/71_LEVEL.tscn',
		40: 'res://story/80_LEVEL.tscn',
		45: 'res://story/90_LEVEL.tscn',
		50: 'res://story/100_LEVEL.tscn',
	},
	# During the following phases, the difficulty will be + 1
	PHASE_LOOT: {
		2: 'res://story/1_LOOT.tscn',
		3: 'res://story/2_LOOT.tscn',
		6: 'res://story/10_LOOT.tscn',
		11: 'res://story/20_LOOT.tscn',
		16: 'res://story/30_LOOT.tscn',
		21: 'res://story/40_LOOT.tscn',
		52: 'res://story/101_LOOT.tscn',
	},
	PHASE_BONUS: {
		6: 'res://story/10_LEVEL_GATE.tscn',
		26: 'res://story/50_LEVEL_GATE.tscn',
		31: 'res://story/60_LEVEL_GATE.tscn',
		51: 'res://story/100_LEVEL_GATE.tscn',
	},
	'level_types': {
		level_types.SURVIVAL: 'res://story/SURVIVAL.tscn',
		level_types.MEGASPRITE: 'res://story/MEGASPRITE.tscn',
		level_types.BLOCK_EXIT: 'res://story/BLOCK_EXIT.tscn',
		level_types.WEATHER: 'res://story/WEATHER.tscn',
		level_types.FRICTION: 'res://story/FRICTION.tscn',
		level_types.KEEP_MOVING: 'res://story/KEEP_MOVING.tscn',
	}
}

const attributes = {
	'action_points_max' : {
		'_level_min': 1,
		'_item_types': [ITEM_TOOL, ITEM_MODULE],
		'_roll_value': { 'min': 0.16, 'max': 0.32 },
		'augmented': false,
		'augment_step': 0.02,
		'augment_max': 0.64,
		'base': 3,
		'cap': 10,
		'key': 'action_points_max',
		'name': 'T_MAX_AP',
		'desc': 'T_MAX_AP_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PLAIN,
	},
	'critical_chance' : {
		'_level_min': 7,
		'_item_types': [ITEM_TOOL, ITEM_MODULE],
		'_roll_value': { 'min': 0.02, 'max': 0.04 },
		'augmented': false,
		'augment_step': 0.0025,
		'augment_max': 0.08,
		'base': 0.08,
		'key': 'critical_chance',
		'name': 'T_CRIT_CHANCE',
		'desc': 'T_CRIT_CHANCE_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'critical_bonus' : {
		'_level_min': 8,
		'_item_types': [ITEM_TOOL, ITEM_MODULE],
		'_roll_value': { 'min': 0.16, 'max': 0.32 },
		'augmented': false,
		'augment_step': 0.02,
		'augment_max': 0.64,
		'base': 0.64,
		'key': 'critical_bonus',
		'name': 'T_CRITICAL_BONUS',
		'desc': 'T_CRITICAL_BONUS_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'counter_chance': {
		'_level_min': 6,
		'_item_types': [ITEM_TOOL, ITEM_MODULE],
		'_roll_value': { 'min': 0.02, 'max': 0.04 },
		'augmented': false,
		'augment_step': 0.0025,
		'augment_max': 0.08,
		'base': 0.04,
		'key': 'counter_chance',
		'name': 'T_COUNTER_CHANCE',
		'desc': 'T_COUNTER_CHANCE_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'damage_bonus': {
		'_level_min': 0,
		'_item_types': [ITEM_TOOL, ITEM_MODULE],
		'_roll_value': { 'min': 0.08, 'max': 0.16 },
		'augmented': false,
		'augment_step': 0.01,
		'augment_max': 0.32,
		'base': 0,
		'key': 'damage_bonus',
		'name': 'T_DAMAGE_BONUS',
		'desc': 'T_DAMAGE_BONUS_DESCRIPTION',
		'rerollable': false,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'evade': {
		'_level_min': 5,
		'_item_types': [ITEM_TOOL, ITEM_MODULE],
		'_roll_value': { 'min': 0.02, 'max': 0.04 },
		'augmented': false,
		'augment_step': 0.0025,
		'augment_max': 0.08,
		'base': 0.08,
		'cap': 0.8,
		'key': 'evade',
		'name': 'T_EVADE',
		'desc': 'T_EVADE_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'material_gain_bonus' : {
		'_level_min': 10,
		'_item_types': [ITEM_MODULE],
		'_roll_value': { 'min': 0.08, 'max': 0.16 },
		'augmented': false,
		'augment_step': 0.01,
		'augment_max': 0.32,
		'base': 0,
		'key': 'material_gain_bonus',
		'name': 'T_MATERIAL_BONUS',
		'desc': 'T_MATERIAL_BONUS_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'loot_bonus' : {
		'_level_min': 35,
		'_item_types': [ITEM_MODULE],
		'_roll_value': { 'min': 0.08, 'max': 0.16 },
		'augmented': false,
		'augment_step': 0.01,
		'augment_max': 0.32,
		'base': 0,
		'key': 'loot_bonus',
		'name': 'T_LOOT_BONUS',
		'desc': 'T_LOOT_BONUS_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'regeneration': {
		'_level_min': 4,
		'_item_types': [ITEM_MODULE],
		'_roll_value': { 'min': 0.01, 'max': 0.02 },
		'augmented': false,
		'augment_step': 0.00125,
		'augment_max': 0.04,
		'base': 0.04,
		'key': 'regeneration',
		'name': 'T_REGENERATION',
		'desc': 'T_REGENERATION_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'reliability': {
		'_level_min': 30,
		'_item_types': [ITEM_TOOL],
		'_roll_value': { 'min': 0.04, 'max': 0.08 },
		'augmented': false,
		'augment_step': 0.005,
		'augment_max': 0.16,
		'base': 0,
		'key': 'reliability',
		'name': 'T_RELIABILITY',
		'desc': 'T_RELIABILITY_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'resistance' : {
		'_level_min': 3,
		'_item_types': [ITEM_MODULE],
		'_roll_value': { 'min': 0.08, 'max': 0.16 },
		'augmented': false,
		'augment_step': 0.01,
		'augment_max': 0.32,
		'base': 0,
		'key': 'resistance',
		'name': 'T_RESISTANCE',
		'desc': 'T_RESISTANCE_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'resistance_reduction' : {
		'_level_min': 60,
		'_item_types': [ITEM_TOOL],
		'_roll_value': { 'min': 0.08, 'max': 0.16 },
		'augmented': false,
		'augment_step': 0.01,
		'augment_max': 0.32,
		'base': 0,
		'key': 'resistance_reduction',
		'name': 'T_RESISTANCE_REDUCTION',
		'desc': 'T_RESISTANCE_REDUCTION_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'shields': {
		'_level_min': 2,
		'_item_types': [ITEM_MODULE],
		'_roll_value': { 'min': 0.02, 'max': 0.04 },
		'augmented': false,
		'augment_step': 0.0025,
		'augment_max': 0.08,
		'base': 0,
		'key': 'shields',
		'name': 'T_SHIELDS',
		'desc': 'T_SHIELDS_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'cap': 1,
		'format': FORMAT_PERCENT,
	},
	'melee_bonus': {
		'_level_min': 45,
		'_item_types': [ITEM_TOOL, ITEM_MODULE],
		'_roll_value': { 'min': 0.16, 'max': 0.32 },
		'augmented': false,
		'augment_step': 0.02,
		'augment_max': 0.64,
		'base': 0,
		'key': 'melee_bonus',
		'name': 'T_MELEE_BONUS',
		'desc': 'T_MELEE_BONUS_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'ranged_bonus': {
		'_level_min': 45,
		'_item_types': [ITEM_TOOL, ITEM_MODULE],
		'_roll_value': { 'min': 0.16, 'max': 0.32 },
		'augmented': false,
		'augment_step': 0.02,
		'augment_max': 0.64,
		'base': 0,
		'key': 'ranged_bonus',
		'name': 'T_RANGED_BONUS',
		'desc': 'T_RANGED_BONUS_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'momentum_bonus': {
		'_level_min': 20,
		'_item_types': [ITEM_TOOL, ITEM_MODULE],
		'_roll_value': { 'min': 0.01, 'max': 0.02 },
		'augmented': false,
		'augment_step': 0.00125,
		'augment_max': 0.04,
		'base': 0,
		'key': 'momentum_bonus',
		'name': 'T_MOMENTUM_BONUS',
		'desc': 'T_MOMENTUM_BONUS_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'stationary_bonus': {
		'_level_min': 20,
		'_item_types': [ITEM_TOOL, ITEM_MODULE],
		'_roll_value': { 'min': 0.01, 'max': 0.02 },
		'augmented': false,
		'augment_step': 0.00125,
		'augment_max': 0.04,
		'base': 0,
		'key': 'stationary_bonus',
		'name': 'T_STATIONARY_BONUS',
		'desc': 'T_STATIONARY_BONUS_DESCRIPTION',
		'rerollable': true,
		'value': null,
		'format': FORMAT_PERCENT,
	},
	'flag_immobile': {
		'key': 'flag_immobile',
		'name': 'T_FLAG_IMMOBILE',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_unpushable': {
		'key': 'flag_unpushable',
		'name': 'T_FLAG_UNPUSHABLE',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_drive_by': {
		'key': 'flag_drive_by',
		'name': 'T_FLAG_DRIVE_BY',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_drive_by_ranged': {
		'key': 'flag_drive_by_ranged',
		'name': 'T_FLAG_DRIVE_BY_RANGED',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_push_mine': {
		'key': 'flag_push_mine',
		'name': 'T_FLAG_PUSH_MINE',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_bitshift': {
		'key': 'flag_bitshift',
		'name': 'T_FLAG_BITSHIFT',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_secureboot': {
		'key': 'flag_secureboot',
		'name': 'T_FLAG_SECUREBOOT',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_fastboot': {
		'key': 'flag_fastboot',
		'name': 'T_FLAG_FASTBOOT',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_powerdodge': {
		'key': 'flag_powerdodge',
		'name': 'T_FLAG_POWERDODGE',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_double_epic': {
		'key': 'flag_double_epic',
		'name': 'T_FLAG_DOUBLE_EPIC',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_shieldburn': {
		'key': 'flag_shieldburn',
		'name': 'T_FLAG_SHIELDBURN',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_bullseye': {
		'key': 'flag_bullseye',
		'name': 'T_FLAG_BULLSEYE',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_friction': {
		'key': 'flag_friction',
		'name': 'T_FLAG_FRICTION',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_fog_of_war': {
		'key': 'flag_fog_of_war',
		'name': 'T_FLAG_FOG_OF_WAR',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_double_difficulty': {
		'key': 'flag_double_difficulty',
		'name': 'T_FLAG_DOUBLE_DIFFICULTY',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_life_link': {
		'key': 'flag_life_link',
		'name': 'T_FLAG_LIFE_LINK',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
	'flag_life_steal': {
		'key': 'flag_life_steal',
		'name': 'T_FLAG_LIFE_STEAL',
		'base': 0,
		'value': 1,
		'rerollable': false,
		'format': FORMAT_FLAG,
	},
}

var damage = {
	'enemy_default': {'type': 'damage', 'name': 'T_DAMAGE', 'min': 0.08, 'max': 0.12 },
	'enemy_high_lower': {'type': 'damage', 'name': 'T_DAMAGE', 'min': 0.025, 'max': 0.1 },
	'low_lower': {'type': 'damage', 'name': 'T_DAMAGE', 'min': 0.25, 'max': 1 },
	'low': {'type': 'damage', 'name': 'T_DAMAGE', 'min': 0.5, 'max': 1 },
	'default_lower': {'type': 'damage', 'name': 'T_DAMAGE', 'min': 0.4, 'max': 1.2 },
	'default': {'type': 'damage', 'name': 'T_DAMAGE', 'min': 0.8, 'max': 1.2 },
	'high_lower': {'type': 'damage', 'name': 'T_DAMAGE', 'min': 0.5, 'max': 2 },
	'high': {'type': 'damage', 'name': 'T_DAMAGE', 'min': 1, 'max': 2 },
	'ultra_lower': {'type': 'damage', 'name': 'T_DAMAGE', 'min': 1, 'max': 3 },
	'ultra': {'type': 'damage', 'name': 'T_DAMAGE', 'min': 2, 'max': 3 },
}

var skills = {
	# Enemy skills
	'enemy_move': {
		'type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 1,
		'cost': 1,
		'icon': preload('res://assets/skills/icon_move.svg'),
		'name': 'T_MOVE_ATTACK',
		'desc': 'T_MOVE_ATTACK_DESCRIPTION',
		'effects': [
			damage.enemy_default
		],
	},
	'enemy_attack_high_lower': {
		'type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 1,
		'cost': 1,
		'effects': [
			damage.enemy_high_lower
		],
	},
	'enemy_ranged_1': {
		'type': PROJECTILE_BALLISTIC,
		'aoe_type': PROJECTILE_BEAM,
		'family': RANGED,
		'range': 4,
		'range_min': 1,
		'cost': 1,
		'icon': preload('res://assets/skills/icon_ranged.svg'),
		'name': 'T_RANGED',
		'desc': 'T_RANGED_DESCRIPTION',
		'effects': [
			damage.enemy_default
		],
	},
	'enemy_dash_and_slash': {
		'type': SKILL_DASH,
		'family': MELEE,
		'range': 4,
		'range_min': 1,
		'blocking': true,
		'only_floor': true,
		'cost': 2,
		'icon': preload('res://assets/skills/icon_dash_and_slash.svg'),
		'name': 'T_DASH_AND_SLASH',
		'desc': 'T_DASH_AND_SLASH_DESCRIPTION',
		'effects': [
			{'type': 'dash', 'name': 'T_DASH' },
		],
		'followup': 'enemy_attack_high_lower'
	},
	# Fixed skills used via code, not items
	'move': {
		'type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 1,
		'cost': 1,
		'_item_types': [],
		'icon': preload('res://assets/skills/icon_move.svg'),
		'name': 'T_MOVE_ATTACK',
		'desc': 'T_MOVE_ATTACK_DESCRIPTION',
		'effects': [
			damage.default
		],
	},
	'attack_high': {
		'type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 1,
		'cost': 1,
		'effects': [
			damage.high
		],
	},
	'push': {
		'type': PROJECTILE_PUSH,
		'range': 1,
		'cost': 1,
		'effects': [
			{'type': 'push', 'name': 'T_PUSH', 'tiles': 1 }
		],
	},
	'masochism': {
		'type': SKILL_SELF,
		'range': 1,
		'cost': 2,
		'reset_to_move': true,
		'name': 'T_MASOCHISM',
		'desc': 'T_MASOCHISM_DESCRIPTION',
		'icon': preload('res://assets/skills/icon_masochism.svg'),
		'effects': [
			{'type': 'masochism', 'name': 'T_MASOCHISM', 'min': 0.2, 'max': 0.8 }
		],
	},
	# Rollable skills
	'minelayer': {
		'_level_min': 15,
		'_item_types': [ITEM_TOOL],
		'type': SKILL_SELF,
		'reset_to_move': true,
		'cost': 3,
		'uses': 1,
		'uses_per_combat': 1,
		'icon': preload('res://assets/skills/icon_mine_drop.svg'),
		'name': 'T_MINELAYER',
		'desc': 'T_MINELAYER_DESCRIPTION',
		'effects': [
			{'type': 'minelayer', 'name': 'T_MINELAYER' }
		],
	},
	'regenerate': {
		'_level_min': 2,
		'_item_types': [ITEM_TOOL],
		'type': SKILL_SELF,
		'reset_to_move': true,
		'cost': 2,
		'uses': 1,
		'uses_per_combat': 1,
		'icon': preload('res://assets/skills/icon_regenerate.svg'),
		'name': 'T_REGENERATE',
		'desc': 'T_REGENERATE_DESCRIPTION',
		'effects': [
			{'type': 'regenerate', 'name': 'T_REGENERATE', 'min': 0.4, 'max': 0.6 }
		],
	},
	'double_shields': {
		'_level_min': 40,
		'_item_types': [ITEM_TOOL],
		'type': SKILL_SELF,
		'reset_to_move': true,
		'cost': 1,
		'icon': preload('res://assets/skills/icon_double_shields.svg'),
		'name': 'T_DOUBLE_SHIELDS',
		'desc': 'T_DOUBLE_SHIELDS_DESCRIPTION',
		'effects': [
			{'type': 'double_shields', 'name': 'T_DOUBLE_SHIELDS' }
		],
	},
	'shields_half': {
		'_level_min': 10,
		'_item_types': [ITEM_TOOL],
		'type': SKILL_SELF,
		'reset_to_move': true,
		'cost': 2,
		'icon': preload('res://assets/skills/icon_shields_up.svg'),
		'name': 'T_SHIELDS_HALF',
		'desc': 'T_SHIELDS_HALF_DESCRIPTION',
		'effects': [
			{'type': 'shields_up', 'name': 'T_CHARGE_SHIELDS', 'value': 0.5 }
		],
	},
	'shields_full': {
		'_level_min': 30,
		'_item_types': [ITEM_TOOL],
		'type': SKILL_SELF,
		'reset_to_move': true,
		'cost': 3,
		'icon': preload('res://assets/skills/icon_shields_up.svg'),
		'name': 'T_SHIELDS_FULL',
		'desc': 'T_SHIELDS_FULL_DESCRIPTION',
		'effects': [
			{'type': 'shields_up', 'name': 'T_CHARGE_SHIELDS', 'value': 1 }
		],
	},
	'teleport': {
		'_level_min': 10,
		'_item_types': [ITEM_TOOL],
		'type': SKILL_TELEPORT,
		'reset_to_move': true,
		'cost': 2,
		'icon': preload('res://assets/skills/icon_teleport.svg'),
		'name': 'T_TELEPORT',
		'desc': 'T_TELEPORT_DESCRIPTION',
		'effects': [
			{'type': 'teleport', 'name': 'T_TELEPORT' }
		],
	},
	'telepush': {
		'_level_min': 15,
		'_item_types': [ITEM_TOOL],
		'type': SKILL_TELEPORT,
		'reset_to_move': true,
		'cost': 3,
		'icon': preload('res://assets/skills/icon_telepush.svg'),
		'name': 'T_TELEPUSH',
		'desc': 'T_TELEPUSH_DESCRIPTION',
		'effects': [
			{'type': 'teleport', 'name': 'T_TELEPORT' }
		],
		'followup': 'push_melee'
	},
	'telestomp': {
		'_level_min': 25,
		'_item_types': [ITEM_TOOL],
		'type': SKILL_TELEPORT,
		'family': MELEE,
		'reset_to_move': true,
		'cost': 4,
		'icon': preload('res://assets/skills/icon_telestomp.svg'),
		'name': 'T_TELESTOMP',
		'desc': 'T_TELESTOMP_DESCRIPTION',
		'effects': [
			{'type': 'teleport', 'name': 'T_TELEPORT' }
		],
		'followup': 'roundhouse_4'
	},
	'dash_and_slash': {
		'_level_min': 5,
		'_item_types': [ITEM_TOOL],
		'type': SKILL_DASH,
		'reset_to_move': true,
		'family': MELEE,
		'range': 4,
		'range_min': 1,
		'blocking': true,
		'only_floor': true,
		'cost': 2,
		'icon': preload('res://assets/skills/icon_dash_and_slash.svg'),
		'name': 'T_DASH_AND_SLASH',
		'desc': 'T_DASH_AND_SLASH_DESCRIPTION',
		'effects': [
			{'type': 'dash', 'name': 'T_DASH' },
		],
		'followup': 'attack_high'
	},
	'dash_and_push': {
		'_level_min': 10,
		'_item_types': [ITEM_TOOL],
		'type': SKILL_DASH,
		'reset_to_move': true,
		'range': 4,
		'range_min': 1,
		'blocking': true,
		'only_floor': true,
		'cost': 2,
		'icon': preload('res://assets/skills/icon_dash_and_push.svg'),
		'name': 'T_DASH_AND_PUSH',
		'desc': 'T_DASH_AND_PUSH_DESCRIPTION',
		'effects': [
			{'type': 'dash', 'name': 'T_DASH' },
		],
		'followup': 'push'
	},
	'push_melee': {
		'_level_min': 15,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_AOE_ONLY,
		'aoe_type': PROJECTILE_PUSH,
		'reset_to_move': true,
		'range': 0,
		'cost': 2,
		'icon': preload('res://assets/skills/icon_push.svg'),
		'name': 'T_MELEE_PUSH',
		'desc': 'T_MELEE_PUSH_DESCRIPTION',
		'effects': [
			{'type': 'push', 'name': 'T_PUSH', 'tiles': 1 }
		],
		'aoe': [
			direction.bottom_right, 
			direction.bottom_left,
			direction.top_left, 
			direction.top_right, 
		],
	},
	'push_ranged': {
		'_level_min': 5,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_BALLISTIC,
		'aoe_type': PROJECTILE_PUSH,
		'range': 3,
		'range_min': 1,
		'cost': 1,
		'icon': preload('res://assets/skills/icon_ranged_push.svg'),
		'name': 'T_RANGED_PUSH',
		'desc': 'T_RANGED_PUSH_DESCRIPTION',
		'effects': [
			{'type': 'push', 'name': 'T_PUSH', 'tiles': 1 }
		],
	},
	'roundhouse_1': {
		'_level_min': 5,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_AOE_ONLY,
		'aoe_type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 0,
		'cost': 1,
		'icon': preload('res://assets/skills/icon_roundhouse.svg'),
		'name': 'T_MELEE_ROUNDHOUSE',
		'desc': 'T_MELEE_ROUNDHOUSE_DESCRIPTION',
		'effects': [
			damage.low_lower
		],
		'aoe': [
			direction.bottom_right, 
			direction.bottom_left,
			direction.top_left, 
			direction.top_right, 
			direction.top, 
			direction.bottom, 
			direction.right, 
			direction.left,
		],
	},
	'roundhouse_2': {
		'_level_min': 25,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_AOE_ONLY,
		'aoe_type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 0,
		'cost': 2,
		'icon': preload('res://assets/skills/icon_roundhouse.svg'),
		'name': 'T_MELEE_ROUNDHOUSE',
		'desc': 'T_MELEE_ROUNDHOUSE_DESCRIPTION',
		'effects': [
			damage.high_lower
		],
		'aoe': [
			direction.bottom_right, 
			direction.bottom_left,
			direction.top_left, 
			direction.top_right, 
			direction.top, 
			direction.bottom, 
			direction.right, 
			direction.left,
		],
	},
	'roundhouse_4': {
		'_level_min': 45,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_AOE_ONLY,
		'aoe_type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 0,
		'cost': 4,
		'icon': preload('res://assets/skills/icon_roundhouse.svg'),
		'name': 'T_MELEE_ROUNDHOUSE',
		'desc': 'T_MELEE_ROUNDHOUSE_DESCRIPTION',
		'effects': [
			damage.ultra
		],
		'aoe': [
			direction.bottom_right, 
			direction.bottom_left,
			direction.top_left, 
			direction.top_right, 
			direction.top, 
			direction.bottom, 
			direction.right, 
			direction.left,
		],
	},
	'cross_1': {
		'_level_min': 0,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_AOE_ONLY,
		'aoe_type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 0,
		'cost': 1,
		'icon': preload('res://assets/skills/icon_cross.svg'),
		'name': 'T_MELEE_CROSS',
		'desc': 'T_MELEE_CROSS_DESCRIPTION',
		'effects': [
			damage.default
		],
		'aoe': [
			direction.bottom_right, 
			direction.bottom_left, 
			direction.top_left, 
			direction.top_right, 
		],
	},
	'cross_2': {
		'_level_min': 20,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_AOE_ONLY,
		'aoe_type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 0,
		'cost': 2,
		'icon': preload('res://assets/skills/icon_cross.svg'),
		'name': 'T_MELEE_CROSS',
		'desc': 'T_MELEE_CROSS_DESCRIPTION',
		'effects': [
			damage.ultra_lower
		],
		'aoe': [
			direction.bottom_right, 
			direction.bottom_left, 
			direction.top_left, 
			direction.top_right, 
		],
	},
	'melee_annihilation_3': {
		'_level_min': 30,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_AOE_ONLY,
		'aoe_type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 0,
		'cost': 3,
		'icon': preload('res://assets/skills/icon_melee_annihilation.svg'),
		'name': 'T_MELEE_ANNIHILATION',
		'desc': 'T_MELEE_ANNIHILATION_DESCRIPTION',
		'effects': [
			damage.high_lower
		],
		'aoe': [
			direction.bottom_right,
			direction.bottom_left,
			direction.top_left,
			direction.top_right,
			direction.bottom_right * 2,
			direction.bottom_left * 2,
			direction.top_left * 2,
			direction.top_right * 2,
			direction.top,
			direction.bottom,
			direction.right,
			direction.left,
		],
	},
	'melee_annihilation_5': {
		'_level_min': 60,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_AOE_ONLY,
		'aoe_type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 0,
		'cost': 5,
		'icon': preload('res://assets/skills/icon_melee_annihilation.svg'),
		'name': 'T_MELEE_ANNIHILATION',
		'desc': 'T_MELEE_ANNIHILATION_DESCRIPTION',
		'effects': [
			damage.ultra
		],
		'aoe': [
			direction.bottom_right,
			direction.bottom_left,
			direction.top_left,
			direction.top_right,
			direction.bottom_right * 2,
			direction.bottom_left * 2,
			direction.top_left * 2,
			direction.top_right * 2,
			direction.top,
			direction.bottom,
			direction.right,
			direction.left,
		],
	},
	'double_1': {
		'_level_min': 0,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_BEAM,
		'aoe_type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 2,
		'cost': 1,
		'icon': preload('res://assets/skills/icon_double.svg'),
		'name': 'T_MELEE_DOUBLE',
		'desc': 'T_MELEE_DOUBLE_DESCRIPTION',
		'effects': [
			damage.low
		],
	},
	'double_2': {
		'_level_min': 15,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_BEAM,
		'aoe_type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 2,
		'cost': 2,
		'icon': preload('res://assets/skills/icon_double.svg'),
		'name': 'T_MELEE_DOUBLE',
		'desc': 'T_MELEE_DOUBLE_DESCRIPTION',
		'effects': [
			damage.high
		],
	},
	'triple_1': {
		'_level_min': 5,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_BEAM,
		'aoe_type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 3,
		'cost': 1,
		'icon': preload('res://assets/skills/icon_triple.svg'),
		'name': 'T_MELEE_TRIPLE',
		'desc': 'T_MELEE_TRIPLE_DESCRIPTION',
		'effects': [
			damage.low_lower
		],
	},
	'triple_2': {
		'_level_min': 20,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_BEAM,
		'aoe_type': PROJECTILE_BEAM,
		'family': MELEE,
		'range': 3,
		'cost': 2,
		'icon': preload('res://assets/skills/icon_triple.svg'),
		'name': 'T_MELEE_TRIPLE',
		'desc': 'T_MELEE_TRIPLE_DESCRIPTION',
		'effects': [
			damage.high
		],
	},
	'ranged_1': {
		'_level_min': 0,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_BALLISTIC,
		'aoe_type': PROJECTILE_BEAM,
		'family': RANGED,
		'range': 4,
		'range_min': 1,
		'cost': 1,
		'icon': preload('res://assets/skills/icon_ranged.svg'),
		'name': 'T_RANGED',
		'desc': 'T_RANGED_DESCRIPTION',
		'effects': [
			damage.high
		],
	},
	'ranged_2': {
		'_level_min': 20,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_BALLISTIC,
		'aoe_type': PROJECTILE_BEAM,
		'family': RANGED,
		'range': 4,
		'range_min': 1,
		'cost': 2,
		'icon': preload('res://assets/skills/icon_ranged.svg'),
		'name': 'T_RANGED',
		'desc': 'T_RANGED_DESCRIPTION',
		'effects': [
			damage.ultra
		],
	},
	'ranged_cross_1': {
		'_level_min': 0,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_BALLISTIC,
		'aoe_type': PROJECTILE_BEAM,
		'family': RANGED,
		'range': 4,
		'range_min': 1,
		'cost': 1,
		'icon': preload('res://assets/skills/icon_ranged_cross.svg'),
		'name': 'T_RANGED_CROSS',
		'desc': 'T_RANGED_CROSS_DESCRIPTION',
		'effects': [
			damage.low
		],
		'aoe': [
			direction.bottom_right, 
			direction.bottom_left, 
			direction.top_left, 
			direction.top_right, 
		],
	},
	'ranged_cross_2': {
		'_level_min': 25,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_BALLISTIC,
		'aoe_type': PROJECTILE_BEAM,
		'family': RANGED,
		'range': 4,
		'range_min': 1,
		'cost': 2,
		'icon': preload('res://assets/skills/icon_ranged_cross.svg'),
		'name': 'T_RANGED_CROSS',
		'desc': 'T_RANGED_CROSS_DESCRIPTION',
		'effects': [
			damage.high
		],
		'aoe': [
			direction.bottom_right, 
			direction.bottom_left, 
			direction.top_left, 
			direction.top_right, 
		],
	},
	'ranged_lightning_1': {
		'_level_min': 5,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_LIGHTNING,
		'family': RANGED,
		'range': 2,
		'range_min': 1,
		'chain': 4,
		'cost': 1,
		'icon': preload('res://assets/skills/icon_ranged_lightning.svg'),
		'name': 'T_RANGED_LIGHTNING',
		'desc': 'T_RANGED_LIGHTNING_DESCRIPTION',
		'effects': [
			damage.low_lower
		],
	},
	'ranged_roundhouse_3': {
		'_level_min': 35,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_BALLISTIC,
		'aoe_type': PROJECTILE_BEAM,
		'family': RANGED,
		'range': 4,
		'range_min': 1,
		'cost': 3,
		'icon': preload('res://assets/skills/icon_ranged_roundhouse.svg'),
		'name': 'T_RANGED_ROUNDHOUSE',
		'desc': 'T_RANGED_ROUNDHOUSE_DESCRIPTION',
		'effects': [
			damage.high
		],
		'aoe': [
			direction.bottom_right, 
			direction.bottom_left, 
			direction.top_left, 
			direction.top_right, 
			direction.top, 
			direction.bottom, 
			direction.right, 
			direction.left,
		],
	},
	'ranged_annihilation_4': {
		'_level_min': 45,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_BALLISTIC,
		'aoe_type': PROJECTILE_BEAM,
		'family': RANGED,
		'range': 5,
		'range_min': 2,
		'cost': 4,
		'icon': preload('res://assets/skills/icon_ranged_annihilation.svg'),
		'name': 'T_RANGED_ANNIHILATION',
		'desc': 'T_RANGED_ANNIHILATION_DESCRIPTION',
		'effects': [
			damage.high
		],
		'aoe': [
			direction.bottom_right,
			direction.bottom_left,
			direction.top_left,
			direction.top_right,
			direction.bottom_right * 2,
			direction.bottom_left * 2,
			direction.top_left * 2,
			direction.top_right * 2,
			direction.top,
			direction.bottom,
			direction.right,
			direction.left,
		],
	},
	'ranged_annihilation_5': {
		'_level_min': 55,
		'_item_types': [ITEM_TOOL],
		'type': PROJECTILE_BALLISTIC,
		'aoe_type': PROJECTILE_BEAM,
		'family': RANGED,
		'range': 5,
		'range_min': 2,
		'cost': 5,
		'icon': preload('res://assets/skills/icon_ranged_annihilation.svg'),
		'name': 'T_RANGED_ANNIHILATION',
		'desc': 'T_RANGED_ANNIHILATION_DESCRIPTION',
		'effects': [
			damage.ultra_lower
		],
		'aoe': [
			direction.bottom_right,
			direction.bottom_left,
			direction.top_left,
			direction.top_right,
			direction.bottom_right * 2,
			direction.bottom_left * 2,
			direction.top_left * 2,
			direction.top_right * 2,
			direction.top,
			direction.bottom,
			direction.right,
			direction.left,
		],
	},
}

var sets = {
	'T_ENTANGLER': {
		2: {
			'flag_life_link': 1,
		},
		3: {
			'flag_life_steal': 1,
		},
	},
	'T_PIXEL_PUSHER': {
		2: {
			'action_points_max': 1,
		},
		3: {
			'action_points_max': 1,
		},
		4: {
			'flag_push_mine': 1,
		}
	},
	'T_CRITICAL_BIT': {
		2: {
			'critical_chance': 0.5,
		},
		3: {
			'critical_bonus': 2,
		},
	},
	'T_ARTFUL_DODGER': {
		2: {
			'evade': 0.1,
		},
		3: {
			'evade': 0.1,
		},
		4: {
			'flag_powerdodge': 1,
		},
	},
	'T_ACTION_JACKSON': {
		2: {
			'action_points_max': 1,
		},
		3: {
			'action_points_max': 2,
		}
	},
	'T_MOBILITY_SHOOTER': {
		2: {
			'momentum_bonus': 0.1,
		},
		3: {
			'action_points_max': 1,
		},
		4: {
			'flag_drive_by': 1,
		},
		5: {
			'flag_drive_by_ranged': 1,
		},
	},
	'T_TALION': {
		2: {
			'counter_chance': 0.25,
		},
		3: {
			'melee_bonus': 0.25,
		},
		4: {
			'resistance': 0.25,
		},
		5: {
			'stationary_bonus': 0.25,
		},
	}
}


# name: "all gas no breaks" (also is high risk high reward)
# IDEA: set, 2 tools, push & pull, +1 ap on each tool, high chance for ap on kill
# IDEA: set, 2 tools, one costs 1ap and gives 3xp, one's a mighty 5AP attack
# IDEA: a set or legendary that sets all color bonuses to your highest bonus
# blackfast club
# pretty in pink hull
# luke dyewalker
var items = [
	{
		'_roll_skill': 1,
		'_roll_attributes' : 1,
		'rarity': RARITY_COMMON,
		'type': ITEM_TOOL,
		'skill': null,
		'attributes': [],
		'name': '',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_roll_skill': 1,
		'_roll_attributes' : 2,
		'rarity': RARITY_RARE,
		'type': ITEM_TOOL,
		'skill': null,
		'attributes': [],
		'name': '',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_roll_attributes' : 1,
		'rarity': RARITY_COMMON,
		'type': ITEM_MODULE,
		'attributes': [],
		'name': '',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_roll_attributes' : 2,
		'rarity': RARITY_RARE,
		'type': ITEM_MODULE,
		'attributes': [],
		'name': '',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	# LEGENDARIES
	{
		'_add_attributes': ['damage_bonus'],
		'_roll_attributes' : 2,
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_TOOL,
		'skill': 'roundhouse_1',
		'attributes': [],
		'name': 'T_CHARGED_CREEPER',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'damage_bonus',
			'ranged_bonus',
		],
		'_roll_attributes' : 1,
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_TOOL,
		'skill': 'ranged_lightning_1',
		'attributes': [],
		'name': 'T_DARTH_SHADER',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	# TODO: rework this into a set of three tools?!
	{
		'_add_attributes': [
			'action_points_max', 
			'damage_bonus',
		],
		'_roll_attributes' : 1,
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_TOOL,
		'skill': 'triple_2',
		'attributes': [],
		'name': 'T_TRINITY_FORCE',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'action_points_max', 
			'damage_bonus',
			'ranged_bonus',
		],
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_TOOL,
		'skill': 'ranged_annihilation_5',
		'attributes': [],
		'name': 'T_BFG',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'regeneration',
			'resistance',
			'shields',
		],
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_TOOL,
		'skill': 'regenerate',
		'attributes': [],
		'name': 'T_PLUMBUS',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_roll_skill': 1,
		'_add_attributes': [
			'damage_bonus',
		],
		'_roll_attributes' : 2,
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_TOOL,
		'skill': null,
		'attributes': [],
		'name': 'T_MY_LITTLE_FRIEND',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'damage_bonus',
			'ranged_bonus',
		],
		'_roll_attributes' : 1,
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_TOOL,
		'skill': 'ranged_cross_2',
		'attributes': [],
		'name': 'T_HOLY_HAND_GRENADE',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'damage_bonus',
			'critical_chance', 
			'critical_bonus',
		],
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_TOOL,
		'skill': 'ranged_roundhouse_3',
		'attributes': [],
		'name': 'T_GLASS_CANNON',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'damage_bonus', 
			'critical_chance', 
			'critical_bonus'
		],
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_DYE_HARD',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'flag_bitshift',
			'shields'
		],
		'_roll_attributes' : 1,
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_BITSHIFT',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'flag_secureboot',
		],
		'_roll_attributes' : 2,
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_SECUREBOOT',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'flag_fastboot',
		],
		'_roll_attributes' : 2,
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_FASTBOOT',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'flag_shieldburn',
		],
		'_roll_attributes' : 2,
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_SHIELDBURN',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'flag_bullseye',
		],
		'_roll_attributes' : 2,
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_BULLSEYE',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	# { # THIS ONE'S JUST HERE FOR THE NAME
	# 	'_add_attributes': ['damage_bonus', 'regeneration', 'resistance'],
	# 	'_roll_attributes' : 1,
	# 	'rarity': RARITY_LEGENDARY,
	# 	'type': ITEM_PIGMENT,
	# 	'attributes': [],
	# 	'name': 'T_HUETURAMA',
	# 	'prefix': '',
	# 	'suffix': '',
	# 	'augments': 0,
	# 	'rerolls': 0,
	# },
	{
		'_add_attributes': [
			'regeneration', 
			'resistance',
			'shields',
		],
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_COMPANION_CUBE',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'action_points_max',
		],
		'_roll_attributes' : 2,
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_GO_GO_GADGET',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'flag_double_epic',
			'material_gain_bonus',
			'loot_bonus',
		],
		'rarity': RARITY_LEGENDARY,
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_MY_PRECIOUS',
		'prefix': '',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	# Sets
	# CRITICAL BIT
	{
		'_roll_attributes' : 1,
		'rarity': RARITY_SET,
		'set': 'T_CRITICAL_BIT',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_CHIPSET',
		'prefix': 'T_CRITICAL_BIT',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_roll_attributes' : 1,
		'rarity': RARITY_SET,
		'set': 'T_CRITICAL_BIT',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_PROCESSOR',
		'prefix': 'T_CRITICAL_BIT',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_roll_attributes' : 1,
		'rarity': RARITY_SET,
		'set': 'T_CRITICAL_BIT',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_HARDWARE',
		'prefix': 'T_CRITICAL_BIT',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	# ACTION JACKSON
	{
		'_roll_attributes' : 1,
		'rarity': RARITY_SET,
		'set': 'T_ACTION_JACKSON',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_CHIPSET',
		'prefix': 'T_ACTION_JACKSON',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_roll_attributes' : 1,
		'rarity': RARITY_SET,
		'set': 'T_ACTION_JACKSON',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_PROCESSOR',
		'prefix': 'T_ACTION_JACKSON',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_roll_attributes' : 1,
		'rarity': RARITY_SET,
		'set': 'T_ACTION_JACKSON',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_HARDWARE',
		'prefix': 'T_ACTION_JACKSON',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	# T_ENTANGLER
	{
		'_roll_attributes' : 2,
		'rarity': RARITY_SET,
		'set': 'T_ENTANGLER',
		'type': ITEM_TOOL,
		'skill': 'masochism',
		'attributes': [],
		'name': 'T_DEVICE',
		'prefix': 'T_ENTANGLER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_roll_skill': 1,
		'_roll_attributes' : 2,
		'rarity': RARITY_SET,
		'set': 'T_ENTANGLER',
		'type': ITEM_TOOL,
		'skill': null,
		'attributes': [],
		'name': 'T_EMITTER',
		'prefix': 'T_ENTANGLER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_roll_skill': 1,
		'_roll_attributes' : 2,
		'rarity': RARITY_SET,
		'set': 'T_ENTANGLER',
		'type': ITEM_TOOL,
		'skill': null,
		'attributes': [],
		'name': 'T_BLASTER',
		'prefix': 'T_ENTANGLER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},

	# PIXEL PUSHER
	{
		'_roll_attributes' : 3,
		'rarity': RARITY_SET,
		'set': 'T_PIXEL_PUSHER',
		'type': ITEM_TOOL,
		'skill': 'push_melee',
		'attributes': [],
		'name': 'T_EMITTER',
		'prefix': 'T_PIXEL_PUSHER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_roll_attributes' : 3,
		'rarity': RARITY_SET,
		'set': 'T_PIXEL_PUSHER',
		'type': ITEM_TOOL,
		'skill': 'push_ranged',
		'attributes': [],
		'name': 'T_GUN',
		'prefix': 'T_PIXEL_PUSHER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_roll_attributes' : 3,
		'rarity': RARITY_SET,
		'set': 'T_PIXEL_PUSHER',
		'type': ITEM_TOOL,
		'skill': 'telepush',
		'attributes': [],
		'name': 'T_BLASTER',
		'prefix': 'T_PIXEL_PUSHER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_roll_attributes' : 3,
		'rarity': RARITY_SET,
		'set': 'T_PIXEL_PUSHER',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_HARDWARE',
		'prefix': 'T_PIXEL_PUSHER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	# MOBILITY SHOOTER
	{
		'_add_attributes': [
			'damage_bonus',
			'action_points_max',
			'momentum_bonus'
		],
		'rarity': RARITY_SET,
		'set': 'T_MOBILITY_SHOOTER',
		'type': ITEM_TOOL,
		'skill': 'dash_and_slash',
		'attributes': [],
		'name': 'T_BLASTER',
		'prefix': 'T_MOBILITY_SHOOTER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'damage_bonus',
			'action_points_max',
			'momentum_bonus',
		],
		'rarity': RARITY_SET,
		'set': 'T_MOBILITY_SHOOTER',
		'type': ITEM_TOOL,
		'skill': 'teleport',
		'attributes': [],
		'name': 'T_TRANSMITTER',
		'prefix': 'T_MOBILITY_SHOOTER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'action_points_max',
			'momentum_bonus',
		],
		'_roll_attributes' : 1,
		'rarity': RARITY_SET,
		'set': 'T_MOBILITY_SHOOTER',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_GADGET',
		'prefix': 'T_MOBILITY_SHOOTER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'action_points_max',
			'momentum_bonus',
		],
		'_roll_attributes' : 1,
		'rarity': RARITY_SET,
		'set': 'T_MOBILITY_SHOOTER',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_CHIPSET',
		'prefix': 'T_MOBILITY_SHOOTER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': [
			'action_points_max',
			'momentum_bonus',
		],
		'_roll_attributes' : 1,
		'rarity': RARITY_SET,
		'set': 'T_MOBILITY_SHOOTER',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_HARDWARE',
		'prefix': 'T_MOBILITY_SHOOTER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	# ARTFUL DODGER
	{
		'_add_attributes': ['evade'],
		'_roll_attributes' : 2,
		'rarity': RARITY_SET,
		'set': 'T_ARTFUL_DODGER',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_HARDWARE',
		'prefix': 'T_ARTFUL_DODGER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': ['evade'],
		'_roll_attributes' : 2,
		'rarity': RARITY_SET,
		'set': 'T_ARTFUL_DODGER',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_CHIPSET',
		'prefix': 'T_ARTFUL_DODGER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': ['evade'],
		'_roll_attributes' : 2,
		'rarity': RARITY_SET,
		'set': 'T_ARTFUL_DODGER',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_GADGET',
		'prefix': 'T_ARTFUL_DODGER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': ['evade'],
		'_roll_attributes' : 2,
		'rarity': RARITY_SET,
		'set': 'T_ARTFUL_DODGER',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_CIRCUIT',
		'prefix': 'T_ARTFUL_DODGER',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	# TALION
	{
		'_add_attributes': ['counter_chance', 'resistance'],
		'_roll_attributes' : 1,
		'rarity': RARITY_SET,
		'set': 'T_TALION',
		'type': ITEM_TOOL,
		'skill': 'regenerate',
		'attributes': [],
		'name': 'T_EMITTER',
		'prefix': 'T_TALION',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': ['counter_chance', 'resistance'],
		'_roll_attributes' : 1,
		'rarity': RARITY_SET,
		'set': 'T_TALION',
		'type': ITEM_TOOL,
		'skill': 'dash_and_slash',
		'attributes': [],
		'name': 'T_ORDNANCE',
		'prefix': 'T_TALION',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': ['counter_chance', 'resistance'],
		'_roll_attributes' : 1,
		'rarity': RARITY_SET,
		'set': 'T_TALION',
		'type': ITEM_TOOL,
		'skill': 'shields_full',
		'attributes': [],
		'name': 'T_TRANSMITTER',
		'prefix': 'T_TALION',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': ['counter_chance', 'resistance'],
		'_roll_attributes' : 1,
		'rarity': RARITY_SET,
		'set': 'T_TALION',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_GADGET',
		'prefix': 'T_TALION',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
	{
		'_add_attributes': ['counter_chance', 'resistance'],
		'_roll_attributes' : 1,
		'rarity': RARITY_SET,
		'set': 'T_TALION',
		'type': ITEM_MODULE,
		'attributes': [],
		'name': 'T_MODULE',
		'prefix': 'T_TALION',
		'suffix': '',
		'augments': 0,
		'rerolls': 0,
	},
]

var enemies = {
	'byte': {
		'color': enemy_colors.red,
		'type': 'byte',
		'name': 'T_BYTE',
		'desc': 'T_BYTE_DESCRIPTION',
		'drops': { 'items': { 'chance': 0.03, 'max': 1 }, 'materials': { 'chance': 0.5, 'max': 25 }},
		'sprite': {
			'texture': preload('res://assets/sprites/byte.svg'),
			'y_offset': 44,
			'height': 70,
		},
		'skills': [skills.enemy_move],
		'attributes': {
			'action_points_max': 1,
			'damage_bonus': 0.5,
		},
	},
	'kilobyte': {
		'color': enemy_colors.red,
		'type': 'kilobyte',
		'name': 'T_KILOBYTE',
		'desc': 'T_KILOBYTE_DESCRIPTION',
		'drops': { 'items': { 'chance': 0.03, 'max': 1 }, 'materials': { 'chance': 0.5, 'max': 25 }},
		'sprite': {
			'texture': preload('res://assets/sprites/kilobyte.svg'),
			'y_offset': 36,
			'height': 80,
		},
		'skills': [skills.enemy_move],
		'attributes': {
			'action_points_max': 1,
			'damage_bonus': 0.5,
			'shields': 0.64
		},
	},
	'buffer': {
		'color': enemy_colors.red,
		'type': 'buffer',
		'name': 'T_BUFFER',
		'desc': 'T_BUFFER_DESCRIPTION',
		'drops': { 'items': { 'chance': 0.03, 'max': 1 }, 'materials': { 'chance': 0.5, 'max': 25 }},
		'sprite': {
			'texture': preload('res://assets/sprites/buffer.svg'),
			'y_offset': 9,
			'height': 110,
		},
		'skills': [skills.enemy_move],
		'attributes': {
			'action_points_max': 1,
			'damage_bonus': 0.5,
			'flag_immobile': 1
		},
	},
	'glitch': {
		'color': enemy_colors.green,
		'type': 'glitch',
		'name': 'T_GLITCH',
		'desc': 'T_GLITCH_DESCRIPTION',
		'drops': { 'items': { 'chance': 0.03, 'max': 1 }, 'materials': { 'chance': 0.5, 'max': 25 }},
		'sprite': {
			'texture': preload('res://assets/sprites/glitch.svg'),
			'y_offset': 40,
			'height': 70,
		},
		'skills': [skills.enemy_move, skills.enemy_ranged_1],
		'attributes': {
			'action_points_max': 1,
		},
	},
	# TODO: make it actually run away and a bit squishier!
	# TODO: add STUNGUNNER (elite)
	'macro': {
		'color': enemy_colors.green,
		'type': 'macro',
		'name': 'T_MACRO',
		'desc': 'T_MACRO_DESCRIPTION',
		'drops': { 'items': { 'chance': 0.03, 'max': 1 }, 'materials': { 'chance': 0.5, 'max': 25 }},
		'sprite': {
			'texture': preload('res://assets/sprites/macro.svg'),
			'y_offset': 39,
			'height': 70,
		},
		'skills': [skills.enemy_move],
		'attributes': {
			'action_points_max': 1,
			'counter_chance': 0.75
		},
	},
	'micro': {
		'color': enemy_colors.green,
		'type': 'micro',
		'name': 'T_MICRO',
		'desc': 'T_MICRO_DESCRIPTION',
		'drops': { 'items': { 'chance': 0.03, 'max': 1 }, 'materials': { 'chance': 0.5, 'max': 25 }},
		'sprite': {
			'texture': preload('res://assets/sprites/micro.svg'),
			'y_offset': 68,
			'height': 35,
		},
		'skills': [skills.enemy_move],
		'attributes': {
			'action_points_max': 1,
			'counter_chance': 0.75,
			'evade': 0.25,
		},
	},
	'diode': {
		'color': enemy_colors.yellow,
		'type': 'diode',
		'name': 'T_DIODE',
		'desc': 'T_DIODE_DESCRIPTION',
		'drops': { 'items': { 'chance': 0.03, 'max': 1 }, 'materials': { 'chance': 0.5, 'max': 25 }},
		'sprite': {
			'texture': preload('res://assets/sprites/diode.svg'),
			'y_offset': 52,
			'height': 55,
		},
		'skills': [skills.enemy_move],
		'attributes': {
			'action_points_max': 2,
		},
	},
	'triode': {
		'color': enemy_colors.yellow,
		'type': 'triode',
		'name': 'T_TRIODE',
		'desc': 'T_TRIODE_DESCRIPTION',
		'drops': { 'items': { 'chance': 0.03, 'max': 1 }, 'materials': { 'chance': 0.5, 'max': 25 }},
		'sprite': {
			'texture': preload('res://assets/sprites/triode.svg'),
			'y_offset': 39,
			'height': 68,
		},
		'skills': [skills.enemy_move],
		'attributes': {
			'action_points_max': 3,
		},
	},
	'charger': {
		'color': enemy_colors.yellow,
		'type': 'charger',
		'name': 'T_CHARGER',
		'desc': 'T_CHARGER_DESCRIPTION',
		'drops': { 'items': { 'chance': 0.03, 'max': 1 }, 'materials': { 'chance': 0.5, 'max': 25 }},
		'sprite': {
			'texture': preload('res://assets/sprites/charger.svg'),
			'y_offset': 56,
			'height': 58,
		},
		'skills': [skills.enemy_move, skills.enemy_dash_and_slash],
		'attributes': {
			'action_points_max': 2,
		},
	},
	'baud': {
		'color': enemy_colors.yellow,
		'type': 'baud',
		'name': 'T_BAUD',
		'desc': 'T_BAUD_DESCRIPTION',
		'drops': { 'items': { 'chance': 0.03, 'max': 1 }, 'materials': { 'chance': 0.5, 'max': 25 }},
		'sprite': {
			'texture': preload('res://assets/sprites/baud.svg'),
			'y_offset': 44,
			'height': 66,
		},
		'skills': [skills.enemy_move, skills.teleport],
		'attributes': {
			'action_points_max': 2,
		},
	},
	'elite': {
		'color': Color(0.8, 0.8, 0.8),
		'type': 'elite',
		'name': 'T_MEGASPRITE',
		'desc': 'T_MEGASPRITE_DESCRIPTION',
		'drops': { 'items': { 'chance': 0.5, 'max': 2 }, 'materials': { 'chance': 1, 'max': 100 }},
		'sprite': {
			'texture': preload('res://assets/sprites/elite.svg'),
			'y_offset': 1,
			'height': 117,
		},
		'skills': [skills.enemy_move],
		'attributes': {
			'action_points_max': 3,
			'resistance': 1,
			'damage_bonus': 1,
			'flag_unpushable': 1,
		},
	},
}

var attributes_base = {}
var attributes_enemy = []

var achievements = {
	'T_FIRST_STEPS': {
		'name': 'T_FIRST_STEPS',
		'desc': 'T_FIRST_STEPS_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/first_steps.png'),
			false: preload('res://assets/achievements/png/first_steps_off.png'),
		},
	},
	'T_MILESTONE': {
		'name': 'T_MILESTONE',
		'desc': 'T_MILESTONE_DESCRIPTION',
		'goal': 25,
		'icon': {
			true: preload('res://assets/achievements/png/milestone.png'),
			false: preload('res://assets/achievements/png/milestone_off.png'),
		},
	},
	'T_LEGACY': {
		'name': 'T_LEGACY',
		'desc': 'T_LEGACY_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/legacy.png'),
			false: preload('res://assets/achievements/png/legacy_off.png'),
		},
	},
	'T_DEATH': {
		'name': 'T_DEATH',
		'desc': 'T_DEATH_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/death.png'),
			false: preload('res://assets/achievements/png/death_off.png'),
		},
	},
	'T_END_OF_THE_BEGINNING': {
		'name': 'T_END_OF_THE_BEGINNING',
		'desc': 'T_END_OF_THE_BEGINNING_DESCRIPTION',
		'goal': 50,
		'icon': {
			true: preload('res://assets/achievements/png/end_of_the_beginning.png'),
			false: preload('res://assets/achievements/png/end_of_the_beginning_off.png'),
		},
	},
	'T_BEGINNING_OF_THE_END': {
		'name': 'T_BEGINNING_OF_THE_END',
		'desc': 'T_BEGINNING_OF_THE_END_DESCRIPTION',
		'goal': 100,
		'icon': {
			true: preload('res://assets/achievements/png/beginning_of_the_end.png'),
			false: preload('res://assets/achievements/png/beginning_of_the_end_off.png'),
		},
	},
	'T_CHALLENGER': {
		'name': 'T_CHALLENGER',
		'desc': 'T_CHALLENGER_DESCRIPTION',
		'goal': 50,
		'icon': {
			true: preload('res://assets/achievements/png/challenger.png'),
			false: preload('res://assets/achievements/png/challenger_off.png'),
		},
	},
	'T_BRAGGING_RIGHTS': {
		'name': 'T_BRAGGING_RIGHTS',
		'desc': 'T_BRAGGING_RIGHTS_DESCRIPTION',
		'goal': 100,
		'icon': {
			true: preload('res://assets/achievements/png/bragging_rights.png'),
			false: preload('res://assets/achievements/png/bragging_rights_off.png'),
		},
	},
	'T_ROGUELIKER': {
		'name': 'T_ROGUELIKER',
		'desc': 'T_ROGUELIKER_DESCRIPTION',
		'goal': 100,
		'icon': {
			true: preload('res://assets/achievements/png/rogueliker.png'),
			false: preload('res://assets/achievements/png/rogueliker_off.png'),
		},
	},
	'T_MAXED': {
		'name': 'T_MAXED',
		'desc': 'T_MAXED_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/maxed.png'),
			false: preload('res://assets/achievements/png/maxed_off.png'),
		},
	},
	'T_SWITCHEROO': {
		'name': 'T_SWITCHEROO',
		'desc': 'T_SWITCHEROO_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/switcheroo.png'),
			false: preload('res://assets/achievements/png/switcheroo_off.png'),
		},
	},
	'T_ARTISAN': {
		'name': 'T_ARTISAN',
		'desc': 'T_ARTISAN_DESCRIPTION',
		'goal': 100,
		'icon': {
			true: preload('res://assets/achievements/png/artisan.png'),
			false: preload('res://assets/achievements/png/artisan_off.png'),
		},
	},
	'T_FIRST_STRIKE': {
		'name': 'T_FIRST_STRIKE',
		'desc': 'T_FIRST_STRIKE_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/first_strike.png'),
			false: preload('res://assets/achievements/png/first_strike_off.png'),
		},
	},
	'T_SEVEN_AT_ONE_BLOW': {
		'name': 'T_SEVEN_AT_ONE_BLOW',
		'desc': 'T_SEVEN_AT_ONE_BLOW_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/seven_at_one_blow.png'),
			false: preload('res://assets/achievements/png/seven_at_one_blow_off.png'),
		},
	},
	'T_ONE_HIT_WONDER': {
		'name': 'T_ONE_HIT_WONDER',
		'desc': 'T_ONE_HIT_WONDER_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/one_hit_wonder.png'),
			false: preload('res://assets/achievements/png/one_hit_wonder_off.png'),
		},
	},
	'T_HAT_TRICK': {
		'name': 'T_HAT_TRICK',
		'desc': 'T_HAT_TRICK_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/hat_trick.png'),
			false: preload('res://assets/achievements/png/hat_trick_off.png'),
		},
	},
	'T_TANKY': {
		'name': 'T_TANKY',
		'desc': 'T_TANKY_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/tanky.png'),
			false: preload('res://assets/achievements/png/tanky_off.png'),
		},
	},
	'T_STATIONARY': {
		'name': 'T_STATIONARY',
		'desc': 'T_STATIONARY_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/stationary.png'),
			false: preload('res://assets/achievements/png/stationary_off.png'),
		},
	},
	'T_CLOSE_CALL': {
		'name': 'T_CLOSE_CALL',
		'desc': 'T_CLOSE_CALL_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/close_call.png'),
			false: preload('res://assets/achievements/png/close_call_off.png'),
		},
	},
	'T_SHINY_HINEY': {
		'name': 'T_SHINY_HINEY',
		'desc': 'T_SHINY_HINEY_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/shiny_hiney.png'),
			false: preload('res://assets/achievements/png/shiny_hiney_off.png'),
		},
	},
	'T_RICH_BITCH': {
		'name': 'T_RICH_BITCH',
		'desc': 'T_RICH_BITCH_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/rich_bitch.png'),
			false: preload('res://assets/achievements/png/rich_bitch_off.png'),
		},
	},
	'T_PERFECTIONIST': {
		'name': 'T_PERFECTIONIST',
		'desc': 'T_PERFECTIONIST_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/perfectionist.png'),
			false: preload('res://assets/achievements/png/perfectionist_off.png'),
		},
	},
	'T_SCROOGE': {
		'name': 'T_SCROOGE',
		'desc': 'T_SCROOGE_DESCRIPTION',
		'goal': 25000,
		'icon': {
			true: preload('res://assets/achievements/png/scrooge.png'),
			false: preload('res://assets/achievements/png/scrooge_off.png'),
		},
	},
	'T_PILE_OF_CRAP': {
		'name': 'T_PILE_OF_CRAP',
		'desc': 'T_PILE_OF_CRAP_DESCRIPTION',
		'goal': 1000,
		'icon': {
			true: preload('res://assets/achievements/png/pile_of_crap.png'),
			false: preload('res://assets/achievements/png/pile_of_crap_off.png'),
		},
	},
	'T_COMMON_SENSE': {
		'name': 'T_COMMON_SENSE',
		'desc': 'T_COMMON_SENSE_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/common_sense.png'),
			false: preload('res://assets/achievements/png/common_sense_off.png'),
		},
	},
	'T_COLLECTOR': {
		'name': 'T_COLLECTOR',
		'desc': 'T_COLLECTOR_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/collector.png'),
			false: preload('res://assets/achievements/png/collector_off.png'),
		},
	},
	'T_TREASURE_HUNTER': {
		'name': 'T_TREASURE_HUNTER',
		'desc': 'T_TREASURE_HUNTER_DESCRIPTION',
		'goal': 100,
		'icon': {
			true: preload('res://assets/achievements/png/treasure_hunter.png'),
			false: preload('res://assets/achievements/png/treasure_hunter_off.png'),
		},
	},
	'T_ELUSIVE': {
		'name': 'T_ELUSIVE',
		'desc': 'T_ELUSIVE_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/elusive.png'),
			false: preload('res://assets/achievements/png/elusive_off.png'),
		},
	},
	'T_PACIFIST': {
		'name': 'T_PACIFIST',
		'desc': 'T_PACIFIST_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/pacifist.png'),
			false: preload('res://assets/achievements/png/pacifist_off.png'),
		},
	},
	'T_META_MASTERY_PUSH': {
		'name': 'T_META_MASTERY_PUSH',
		'desc': 'T_META_MASTERY_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/meta_mastery.png'),
			false: preload('res://assets/achievements/png/meta_mastery_off.png'),
		},
	},
	'T_META_MASTERY_EVADE': {
		'name': 'T_META_MASTERY_EVADE',
		'desc': 'T_META_MASTERY_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/meta_mastery.png'),
			false: preload('res://assets/achievements/png/meta_mastery_off.png'),
		},
	},
	'T_META_MASTERY_CRIT': {
		'name': 'T_META_MASTERY_CRIT',
		'desc': 'T_META_MASTERY_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/meta_mastery.png'),
			false: preload('res://assets/achievements/png/meta_mastery_off.png'),
		},
	},
	'T_META_MASTERY_COUNTER': {
		'name': 'T_META_MASTERY_COUNTER',
		'desc': 'T_META_MASTERY_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/meta_mastery.png'),
			false: preload('res://assets/achievements/png/meta_mastery_off.png'),
		},
	},
	'T_META_MASTERY_HIT': {
		'name': 'T_META_MASTERY_HIT',
		'desc': 'T_META_MASTERY_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/meta_mastery.png'),
			false: preload('res://assets/achievements/png/meta_mastery_off.png'),
		},
	},
	'T_META_MASTERY_MOVE': {
		'name': 'T_META_MASTERY_MOVE',
		'desc': 'T_META_MASTERY_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/meta_mastery.png'),
			false: preload('res://assets/achievements/png/meta_mastery_off.png'),
		},
	},
	'T_META_MASTERY_AP': {
		'name': 'T_META_MASTERY_AP',
		'desc': 'T_META_MASTERY_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/meta_mastery.png'),
			false: preload('res://assets/achievements/png/meta_mastery_off.png'),
		},
	},
	'T_META_GRANDMASTER': {
		'name': 'T_META_GRANDMASTER',
		'desc': 'T_META_GRANDMASTER_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/meta_grandmaster.png'),
			false: preload('res://assets/achievements/png/meta_grandmaster_off.png'),
		},
	},
	'T_HOLY_GRAIL': {
		'name': 'T_HOLY_GRAIL',
		'desc': 'T_HOLY_GRAIL_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/holy_grail.png'),
			false: preload('res://assets/achievements/png/holy_grail_off.png'),
		},
	},
	'T_COMPLETIONIST': {
		'name': 'T_COMPLETIONIST',
		'desc': 'T_COMPLETIONIST_DESCRIPTION',
		'goal': 1,
		'icon': {
			true: preload('res://assets/achievements/png/completionist.png'),
			false: preload('res://assets/achievements/png/completionist_off.png'),
		},
	}
}


func _ready():
	# Set the goal for the completionist achievement
	achievements['T_COMPLETIONIST'].goal = achievements.size() - 1
	# Build base attributes
	for key in attributes:
		attributes_base[key] = attributes[key].base
	# Build enemy display attributes
	for key in attributes:
		if !key.begins_with('flag') && key != 'regeneration':
			attributes_enemy.append(key)
