extends Control

onready var animation = $AnimationPlayer

func show():
	visible = true
	animation.play("FadeIn")
	SFX.play_variant('swoosh', 0.3)
	yield(animation, "animation_finished")


func hide():
	animation.stop(true)
	animation.play_backwards("FadeIn")
	yield(animation, "animation_finished")
	visible = false
