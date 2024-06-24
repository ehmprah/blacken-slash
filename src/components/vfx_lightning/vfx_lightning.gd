extends Node2D

signal animation_finished

var entity
var colors = []
var target

onready var tween = $Tween
onready var particles_casting = $Particles/CastingParticles
onready var particles_hit = $Particles/HitParticles
onready var lines = [$Line, $Line2, $Line3]

func _ready():
	visible = false


func update():
	particles_casting.rotation = atan2(target.y, target.x)
	particles_hit.position = target
	# Update the lightning bolts
	for line in lines:
		line.clear_points()
		line.add_point(Vector2.ZERO)
		for n in 2:
			var point = randf() * target
			point += Vector2((randi() % 40) - 20, (randi() % 40) - 20)
			line.add_point(point)
		line.add_point(target)


func animate():
	update()
	visible = true
	SFX.play_variant('lightning')
	particles_casting.emitting = true
	particles_hit.emitting = true
	tween.interpolate_callback(self, 0.05, 'update')
	tween.interpolate_callback(self, 0.15, 'update')
	tween.interpolate_property(self, "modulate", colors[0], colors[1], 0.2)
	tween.start()
	yield(tween, "tween_all_completed")
	emit_signal("animation_finished")
	# Before we delete this, we fade it slowly
	tween.interpolate_callback(self, 0.1, 'update')
	tween.interpolate_callback(self, 0.2, 'update')
	tween.interpolate_property(self, "modulate", modulate, Color(0, 0, 0, 0), 0.2)
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()
