extends CanvasLayer


onready var grayscale = $Greyscale
onready var tween = $Greyscale/Tween

func _ready():
	# warning-ignore:return_value_discarded
	var player = get_node("/root/Main/Game/Entities/Player")
	player.connect('health_changed', self, '_on_health_change')
	# warning-ignore:return_value_discarded
	var inventory = get_node("/root/Main/UI").inventory
	inventory.connect('health_changed', self, '_on_health_change')


func reset_grayscale():
	if grayscale:
		grayscale.material.set_shader_param('intensity', 0)


func _on_health_change():
	if Settings.user.gameplay.disable_grayscale == false:
		set_grayscale(State.game.damage)


func set_grayscale(target):
	tween.interpolate_property(
		grayscale.material,
		"shader_param/intensity",
		grayscale.material.get_shader_param('intensity'),
		clamp(float(target), 0, 1),
		0.2
	)
	tween.start()
