extends Node2D

export (Vector2) var final_scale = Vector2(1.5, 1.5)
export (float) var float_distance = 50.0
export (float) var duration = 0.2
export (String) var text = ''
export (Resource) var icon = null

onready var tween = $Tween

func _ready():
	$Container/Icon.visible = icon != null
	if icon:
		$Container/Icon.texture = icon
	$Container/Label.text = text

	tween.interpolate_property(self, "scale", scale, final_scale,
			duration, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
			
	tween.start()
	yield(tween, "tween_completed")
	
	tween.interpolate_property(self, "position", position, 
			position + Vector2(0, -float_distance), duration, Tween.TRANS_BACK,
			Tween.EASE_IN)
	var transparent = modulate
	transparent.a = 0.0
	tween.interpolate_property(self, "modulate", modulate, transparent,
			duration, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")
	queue_free()
