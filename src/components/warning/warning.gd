extends Control

onready var container = $Container
onready var icon_left = $Container/Left/Icon
onready var icon_right = $Container/Right/Icon
onready var label_top = $Container/Labels/Top
onready var label_left = $Container/Labels/Main/Left
onready var label_right = $Container/Labels/Main/Right
onready var animation = $AnimationPlayer

func hide():
	animation.play("Hide")

func show_limit(turns):
	visible = true
	container.rect_position = Vector2.ZERO
	container.modulate = Config.colors.magenta
	label_top.text = 'T_REACH_GATE_IN'
	label_left.text = String(turns)
	label_right.text = 'T_TURNS'


func show_survive(turns):
	visible = true
	container.rect_position = Vector2.ZERO
	container.modulate = Config.colors.magenta
	label_top.text = 'T_SURVIVE_FOR'
	label_left.text = String(turns)
	label_right.text = 'T_TURNS'


func show_weather():
	visible = true
	container.rect_position = Vector2.ZERO
	container.modulate = Config.colors.yellow
	label_top.text = 'T_WARNING'
	label_left.text = 'T_WEATHER_WARNING'
	label_right.text = ''


func show_elite(attribute, value):
	visible = true
	container.rect_position = Vector2.ZERO
	container.modulate = Config.colors.grey
	label_top.text = 'T_MEGASPRITE_BONUS'
	if State.game.difficulty.current == 50:
		label_top.text = 'T_GIGASPRITE_BONUS'
	label_left.text = attribute
	label_right.text = value


func show_exit():
	visible = true
	container.rect_position = Vector2.ZERO
	container.modulate = Config.colors.yellow
	label_top.text = 'T_WARNING'
	label_left.text = 'T_BLOCK_EXIT'
	label_right.text = ''


func show_friction():
	visible = true
	container.rect_position = Vector2.ZERO
	container.modulate = Config.colors.yellow
	label_top.text = 'T_WARNING'
	label_left.text = 'T_TYPE_FRICTION'
	label_right.text = ''


func show_keep_moving():
	visible = true
	container.rect_position = Vector2.ZERO
	container.modulate = Config.colors.yellow
	label_top.text = 'T_WARNING'
	label_left.text = 'T_TYPE_KEEP_MOVING'
	label_right.text = ''
