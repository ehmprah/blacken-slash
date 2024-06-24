extends Node2D

signal animation_finished

var target

func animate():
	$Particles.emitting = true
	$Particles.rotation = atan2(target.y, target.x)
	yield(get_tree().create_timer(0.5), "timeout")
	emit_signal("animation_finished")
	queue_free()
