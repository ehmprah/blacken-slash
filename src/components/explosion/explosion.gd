extends Particles2D

func _ready():
	emitting = true
	SFX.play(SFX.sounds.SHATTER)
	yield(get_tree().create_timer(1.0), "timeout")
	queue_free()