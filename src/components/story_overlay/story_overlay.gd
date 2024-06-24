extends PanelContainer

var data
var closable = false

onready var tween = $Tween
onready var bits = $Scroll/V/Bits
onready var icon = $Scroll/V/ActionIcon

func _ready():
	modulate = Color(0, 0, 0, 0)
	icon.visible = false
	tween.interpolate_property(self, 'modulate', modulate, Color.white, 0.2)
	tween.start()
	yield(tween, 'tween_all_completed')
	for child in bits.get_children():
		yield(child.show(), 'completed')
	closable = true
	icon.visible = true


func _input(event):
	accept_event()
	if (
		closable &&
		(
			event.is_action_pressed("ui_cancel") ||
			event.is_action_pressed("ui_accept")
		)
	):
		tween.stop_all()
		tween.interpolate_property(self, "modulate", modulate, Color(0, 0, 0, 0), 0.2)
		tween.start()
		yield(tween, "tween_all_completed")
		Controls.change_focus()
		queue_free()
