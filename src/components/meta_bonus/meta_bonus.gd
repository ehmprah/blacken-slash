extends Node2D

onready var tween = $Tween
onready var progress = $V/ProgressBar

func _ready():
	progress.max_value = Config.globals.meta_bonus_times
	progress.value = State.game.meta.rewarded
	
	tween.interpolate_property(self, "scale", scale, Vector2(1.25, 1.25),
			0.5, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	
	tween.interpolate_property(self, "position", position, 
		position + Vector2(0, -50), 1, Tween.TRANS_BACK, Tween.EASE_IN)
	var transparent = modulate
	transparent.a = 0.0
	tween.interpolate_property(self, "modulate", modulate, transparent,
			2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")
	queue_free()
