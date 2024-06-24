extends Control

onready var ui = get_node('/root/Main/UI')

func show(upper = '', lower = ''):
	ui.overlays.add_child(self)
	visible = true
	$Upper.text = upper
	$Lower.text = lower
	$AnimationPlayer.play("Show")
	yield($AnimationPlayer, "animation_finished")
	ui.overlays.remove_child(self)
