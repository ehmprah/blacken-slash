extends PanelContainer

enum characters { CHIP, PATCH, BEEPER, GIGASPRITE }
export (characters) var character = 0

onready var tween = $Tween
onready var wave = $Waveform
onready var player = $Voice
onready var theming = [
	{
		'visual': $Chip, 
		'color': Config.colors.teal, 
		'tracks': [
			preload("res://assets/voice/Chip01.mp3"),
			preload("res://assets/voice/Chip02.mp3"),
			preload("res://assets/voice/Chip03.mp3"),
			preload("res://assets/voice/Chip04.mp3"),
			preload("res://assets/voice/Chip05.mp3"),
			preload("res://assets/voice/Chip06.mp3"),
		]
	},
	{
		'visual': $Patch, 
		'color': Config.colors.orange, 
		'tracks': [
			preload("res://assets/voice/Patch01.mp3"),
			preload("res://assets/voice/Patch02.mp3"),
			preload("res://assets/voice/Patch03.mp3"),
			preload("res://assets/voice/Patch04.mp3"),
			preload("res://assets/voice/Patch05.mp3"),
		]
	},
	{
		'visual': $Beeper, 
		'color': Config.colors.green, 
		'tracks': [
			preload("res://assets/voice/Beeper01.mp3"),
			preload("res://assets/voice/Beeper02.mp3"),
			preload("res://assets/voice/Beeper03.mp3"),
			preload("res://assets/voice/Beeper04.mp3"),
			preload("res://assets/voice/Beeper05.mp3"),
			preload("res://assets/voice/Beeper06.mp3"),
			preload("res://assets/voice/Beeper07.mp3"),
			preload("res://assets/voice/Beeper08.mp3"),
		]
	},
	{
		'visual': $Gigasprite, 
		'color': Config.colors.grey, 
		'tracks': [
			preload("res://assets/voice/Giga01.mp3"),
			preload("res://assets/voice/Giga02.mp3"),
			preload("res://assets/voice/Giga03.mp3"),
		]
	},
]

func _ready():
	update()
	modulate = Color(1, 1, 1, 0)


func update():
	theming[character].visual.visible = true
	theming[character].visual.modulate = theming[character].color
	self_modulate = theming[character].color
	wave.modulate = theming[character].color
	for child in get_children():
		if child is Label:
			child.modulate = theming[character].color


func show():
	rect_pivot_offset = rect_size / 2
	rect_scale = Vector2(0, 0)
	tween.interpolate_property(self, "modulate", modulate, Color.white,
			0.1, Tween.TRANS_CUBIC, Tween.EASE_IN)
	tween.interpolate_property(self, "rect_scale", Vector2(0, 0), Vector2(1, 1),
			0.3, Tween.TRANS_CUBIC, Tween.EASE_IN)
	tween.start()
	yield(tween, 'tween_all_completed')
	play_voice()


func _on_StoryFrame_gui_input(event):
	if (
		event is InputEventMouseButton && 
		event.button_index == BUTTON_LEFT && 
		!event.is_pressed()
	):
		play_voice()


func play_voice():
	var tracks = theming[character].tracks
	player.stream = tracks[randi() % tracks.size()]
	player.play()
