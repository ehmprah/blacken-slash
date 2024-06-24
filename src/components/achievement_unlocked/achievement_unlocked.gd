extends PanelContainer

const Achievement = preload('res://components/achievement/achievement.tscn')

var achievement

onready var slot = $Container/Panel/Container/V/Slot
onready var animation = $AnimationPlayer

func _ready():
	var child = Achievement.instance()
	child.data = achievement
	slot.add_child(child)
	SFX.play(SFX.sounds.ITEM_DROP_UNIQUE)
	animation.play("Enter")
	yield(animation, "animation_finished")


func _input(event):
	accept_event()
	if (
		event.is_action_pressed("ui_cancel") ||
		event.is_action_pressed("ui_accept")
	):
		animation.play_backwards("Enter")
		yield(animation, "animation_finished")
		queue_free()
